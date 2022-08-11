defmodule ConsentWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  require Logger

  alias Phoenix.LiveView
  alias Consent.Accounts
  alias Consent.Accounts.{Consent, User}
  alias ConsentWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @remember_me_max_age 3600 * 24 * 60
  @remember_me_cookie "_consent_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @remember_me_max_age, same_site: "Lax"]

  @consent_max_age 3600 * 24 * 60
  @consent_cookie "_consent_web_cookie_consent"
  @consent_options [sign: true, max_age: @consent_max_age, same_site: "Lax"]

  def on_mount(:current_user, _params, session, socket) do
    {:cont,
     socket
     |> assign_current_user(session)
     |> assign_cookie_consent(session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        new_socket =
          LiveView.assign_new(socket, :current_user, fn ->
            Accounts.get_user_by_session_token!(user_token)
          end)

        %Accounts.User{} = new_socket.assigns.current_user
        {:cont, assign_cookie_consent(new_socket, session)}

      %{} ->
        {:halt, redirect_require_login(socket)}
    end
  rescue
    Ecto.NoResultsError -> {:halt, redirect_require_login(socket)}
  end

  def write_consent_cookie(conn, %Consent{} = cookie_consent) do
    max_age = Consent.expires_from_now(cookie_consent)

    conn
    |> put_session(:cookie_consent, cookie_consent)
    |> put_resp_cookie(
      @consent_cookie,
      cookie_consent,
      Keyword.put(@consent_options, :max_age, max_age)
    )
  end

  @doc """
  Picks up the user's cookie consent, or loads one from
  session cookies. Can assign nil, meaning a cookie modal
  should be presented.

  This plug should be the LAST in the pipeline, definitely
  after :fetch_current_user.
  """
  def fetch_cookie_consent(conn, _opts) do
    consent_cookie_logic(conn, conn.assigns[:current_user])
  end

  # Not logged in case
  def consent_cookie_logic(conn, nil) do
    conn = fetch_cookies(conn, signed: [@consent_cookie])

    case conn.cookies[@consent_cookie] do
      nil ->
        case Accounts.create_anonymous_consent() do
          {:ok, consent} ->
            conn
            |> put_session(:cookie_consent, consent)
            |> put_session(:show_cookie_modal, true)

          _ ->
            raise "Internal error creating anonymous consent"
        end

      consent ->
        put_session(conn, :cookie_consent, consent)
    end
  end

  # Logged in case
  def consent_cookie_logic(conn, %User{id: user_id} = user) do
    conn = fetch_cookies(conn, signed: [@consent_cookie])
    cookie_consent = conn.cookies[@consent_cookie]
    {status, consent} = Accounts.get_user_consent(user)

    {db_action, cookie_action, show_modal} =
      case {status, consent, cookie_consent} do
        {_, nil, nil} ->
          {:new, :assign, true}

        {_, nil, %Consent{user_id: ^user_id}} ->
          {:assign, :ok, false}

        {_, nil, %Consent{user_id: nil}} ->
          {:assign, :assign, false}

        {_, %Consent{consented_at: db_time},
         %Consent{user_id: ^user_id, consented_at: cookie_time}} ->
          case DateTime.diff(cookie_time, db_time) do
            :gt -> {:assign, :ok, false}
            _ -> {:ok, :assign, false}
          end

        {:ok, _, nil} ->
          {:ok, :assign, false}

        {:expired, _, nil} ->
          {:ok, :assign, true}

        {:ok, _, _other_user} ->
          {:ok, :ok, false}

        {:expired, _, _other_user} ->
          {:ok, :ok, true}
      end

    db_results =
      case db_action do
        :ok ->
          {:ok, consent}

        :new ->
          Accounts.create_user_consent(user, %{})

        :assign ->
          Accounts.assign_user_consent(user, consent)
      end

    consent =
      case db_results do
        {:ok, consent} -> consent
        {:error, reason} -> raise "Whoa there db #{reason}"
      end

    conn =
      case cookie_action do
        :assign ->
          write_consent_cookie(conn, consent)

        :ok ->
          put_session(conn, :cookie_consent, consent)
      end

    if show_modal do
      put_session(conn, :show_cookie_modal, true)
    else
      conn
    end
  end

  defp assign_cookie_consent(socket, session) do
    cookie_consent =
      case session["cookie_consent"] do
        nil ->
          case Accounts.create_anonymous_consent() do
            {:ok, consent} -> consent
            _ -> nil
          end

        consent ->
          consent
      end

    Logger.info("assign_cookie_consent: #{cookie_consent.id}")
    LiveView.assign(socket, :cookie_consent, cookie_consent)
  end

  defp assign_current_user(socket, session) do
    case session do
      %{"user_token" => user_token} ->
        LiveView.assign_new(socket, :current_user, fn ->
          Accounts.get_user_by_session_token!(user_token)
        end)

      %{} ->
        LiveView.assign(socket, :current_user, nil)
    end
  end

  defp redirect_require_login(socket) do
    socket
    |> LiveView.put_flash(:error, "Please sign in")
    |> LiveView.redirect(to: Routes.user_session_path(socket, :new))
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || "/")
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    cookie_consent = get_session(conn, :cookie_consent)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:cookie_consent, cookie_consent)
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      ConsentWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
