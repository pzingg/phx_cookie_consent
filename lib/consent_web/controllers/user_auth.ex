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

  def assign_and_write_consent_cookie(conn, %Consent{} = consent, user_id) do
    Logger.info("assign user to consent in cookie")
    write_consent_cookie(conn, %Consent{consent | user_id: user_id})
  end

  def write_consent_cookie(conn, %Consent{} = consent) do
    Logger.info("write consent to cookie")
    max_age = Consent.expires_from_now(consent)

    conn
    |> put_resp_cookie(
      @consent_cookie,
      consent,
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
    conn
    |> consent_cookie_logic(conn.assigns[:current_user])
    |> process_cookie_logic()
  end

  defp get_consent_status(nil, _now), do: :not_found

  defp get_consent_status(%Consent{expires_at: expires_at}, now) do
    if DateTime.compare(expires_at, now) != :gt do
      :expired
    else
      :ok
    end
  end

  # Not logged in case
  defp consent_cookie_logic(conn, nil) do
    conn = fetch_cookies(conn, signed: [@consent_cookie])
    cookie_consent = conn.cookies[@consent_cookie]

    disposition =
      if is_nil(cookie_consent) do
        {:cookie_not_found, nil, nil}
      else
        if is_nil(cookie_consent.user_id) do
          {:cookie_anonymous, cookie_consent, nil}
        else
          {:cookie_from_user, cookie_consent}
        end
      end

    {conn, disposition}
  end

  # Logged in case
  defp consent_cookie_logic(conn, %User{id: user_id} = user) do
    now = DateTime.utc_now()
    consent = Accounts.get_user_consent(user)
    status = get_consent_status(consent, now)

    if status == :expired do
      Logger.error("EXPIRED consent at #{now} expiration #{consent.expires_at} #{consent.id}")
    end

    conn = fetch_cookies(conn, signed: [@consent_cookie])
    cookie_consent = conn.cookies[@consent_cookie]

    cookie_consent =
      case get_consent_status(cookie_consent, now) do
        :expired ->
          Logger.error(
            "EXPIRED cookie at #{now} expiration #{cookie_consent.expires_at} #{cookie_consent.id}"
          )

          nil

        _ ->
          cookie_consent
      end

    disposition =
      case {status, cookie_consent} do
        {:ok, nil} ->
          {:cookie_not_found, consent, user}

        {:expired, nil} ->
          {:expired_available, consent, user}

        {:not_found, nil} ->
          {:nothing_available, user}

        {:ok, %Consent{user_id: nil} = _anonymous_user} ->
          case DateTime.compare(consent.consented_at, cookie_consent.consented_at) do
            :gt -> {:cookie_older_anonymous_user, consent, cookie_consent, user}
            _ -> {:cookie_newer_anonymous_user, consent, cookie_consent, user}
          end

        {_expired_or_not_found, %Consent{user_id: nil} = _anonymous_user} ->
          {:cookie_anonymous, cookie_consent, user}

        {:not_found, %Consent{user_id: ^user_id} = _same_user} ->
          {:cookie_same_user, cookie_consent}

        {_ok_or_expired, %Consent{user_id: ^user_id} = _same_user} ->
          case DateTime.compare(consent.consented_at, cookie_consent.consented_at) do
            :gt -> {:cookie_older_same_user, consent, cookie_consent, user}
            _ -> {:cookie_newer_same_user, consent, cookie_consent, user}
          end

        {:ok, %Consent{user_id: other_user_id} = _other_user} ->
          {:no_op_other_user, consent, user, other_user_id}

        {:expired, %Consent{user_id: other_user_id} = _other_user} ->
          {:expired_other_user, consent, user, other_user_id}

        {:not_found, %Consent{user_id: other_user_id} = _other_user} ->
          {:cookie_other_user, user, other_user_id}
      end

    {conn, disposition}
  end

  defp process_cookie_logic({conn, disposition}) do
    tag = elem(disposition, 0)
    Logger.info("cookie logic #{tag}")

    {conn, consent, show_cookie_modal} =
      case disposition do
        {:no_op_other_user, consent, user, other_user_id} ->
          Logger.info("no op for #{user.id}, other user in cookie #{other_user_id}")
          {conn, consent, false}

        {:nothing_available, user} ->
          consent = Accounts.create_user_consent!(user, %{consented: :all})
          Logger.info("creating new consent #{consent.id}")

          {write_consent_cookie(conn, consent), consent, true}

        {:expired_available, consent, user} ->
          Logger.info("assigning cookie from expired consent")

          {assign_and_write_consent_cookie(conn, consent, user.id), consent, true}

        {:expired_other_user, consent, user, other_user_id} ->
          Logger.info("consent expired for #{user.id}, other user in cookie #{other_user_id}")

          {conn, consent, true}

        {:cookie_not_found, nil, _} ->
          consent = Accounts.create_anonymous_consent!(%{consented: :all})
          Logger.info("no cookie, creating anonymous #{consent.id}")
          {write_consent_cookie(conn, consent), consent, true}

        {:cookie_not_found, consent, user} ->
          Logger.info("no consent in cookie, will use user's saved consent")
          {assign_and_write_consent_cookie(conn, consent, user.id), consent, false}

        {:cookie_anonymous, cookie_consent, nil} ->
          Logger.info("using anonymous cookie #{cookie_consent.id}")
          {conn, cookie_consent, false}

        {:cookie_anonymous, cookie_consent, user} ->
          consent = Accounts.assign_user_consent!(user, cookie_consent)
          Logger.info("assigning from anonymous cookie #{consent.id}")
          {write_consent_cookie(conn, consent), consent, false}

        {:cookie_from_user, cookie_consent} ->
          Logger.info("using cookie #{cookie_consent.id} from user #{cookie_consent.user_id}")
          {conn, cookie_consent, false}

        {:cookie_same_user, cookie_consent} ->
          Logger.info("using same user cookie #{cookie_consent.id}")
          {conn, cookie_consent, false}

        {:cookie_older_anonymous_user, consent, _cookie_consent, user} ->
          Logger.info("assigning to anonymous user cookie from newer consent #{consent.id}")
          {assign_and_write_consent_cookie(conn, consent, user.id), consent, false}

        {:cookie_newer_anonymous_user, consent, cookie_consent, user} ->
          Logger.info("assigning from anonymous user cookie to older consent #{consent.id}")
          {conn, Accounts.assign_user_consent!(user, cookie_consent), false}

        {:cookie_older_same_user, consent, _cookie_consent, user} ->
          Logger.info("assigning to same user cookie from newer consent #{consent.id}")
          {assign_and_write_consent_cookie(conn, consent, user.id), consent, false}

        {:cookie_newer_same_user, consent, cookie_consent, user} ->
          Logger.info("assigning from same user cookie to older consent #{consent.id}")
          {conn, Accounts.assign_user_consent!(user, cookie_consent), false}

        {:cookie_other_user, user, other_user_id} ->
          consent = Accounts.create_user_consent!(user, %{consented: :all})

          Logger.info(
            "no consent for #{user.id}, created #{consent.id} cookie was from #{other_user_id}"
          )

          {conn, consent, true}
      end

    conn
    |> put_session(:cookie_consent, consent)
    |> put_session(:show_cookie_modal, show_cookie_modal)
    |> assign(:show_cookie_modal, show_cookie_modal)
  end

  defp assign_cookie_consent(socket, session) do
    consent = session["cookie_consent"] || Accounts.create_anonymous_consent!(%{consented: :all})
    show_cookie_modal = session["show_cookie_modal"]

    Logger.info("assign_cookie_consent: #{consent.id}")
    LiveView.assign(socket, cookie_consent: consent, show_cookie_modal: show_cookie_modal)
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
