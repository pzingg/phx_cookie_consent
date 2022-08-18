defmodule ConsentWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  require Logger

  alias Phoenix.LiveView
  alias Consent.Accounts
  alias Consent.Accounts.{ConsentSettings, User}
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

  def assign_and_write_consent_cookie(conn, %ConsentSettings{} = consent, user_id) do
    Logger.debug("assign user to consent in cookie")
    write_consent_cookie(conn, %ConsentSettings{consent | user_id: user_id})
  end

  def write_consent_cookie(conn, %ConsentSettings{} = consent) do
    Logger.debug("write consent to cookie")
    max_age = ConsentSettings.expires_from_now(consent)

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

  def no_cookie_modal(conn, _opts) do
    conn
    |> put_session(:show_cookie_modal, false)
    |> assign(:show_cookie_modal, false)
  end

  defp get_consent_status(nil, _now), do: :not_found

  defp get_consent_status(%ConsentSettings{expires_at: expires_at}, now) do
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
        Logger.debug("no cookie, creating anonymous cookie")
        {:create_anonymous_consent, nil}
      else
        if is_nil(cookie_consent.user_id) do
          Logger.debug("using anonymous cookie #{cookie_consent.id}")
          {:use_cookie_consent, cookie_consent}
        else
          Logger.debug("using cookie #{cookie_consent.id} from user #{cookie_consent.user_id}")
          {:use_cookie_consent, cookie_consent}
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
          Logger.debug("no consent in cookie, will use user's saved consent")
          {:assign_from_user_to_cookie, user, consent, false}

        {:expired, nil} ->
          Logger.debug("assigning cookie from expired consent")
          {:assign_from_user_to_cookie, user, consent, true}

        {:not_found, nil} ->
          Logger.debug("no consent, no cookie: creating user consent")
          {:create_user_consent, user}

        {:ok, %ConsentSettings{user_id: nil} = _anonymous_user} ->
          case DateTime.compare(consent.consented_at, cookie_consent.consented_at) do
            :gt ->
              Logger.debug("assigning to anonymous cookie from newer consent #{consent.id}")
              {:assign_from_user_to_cookie, user, consent, false}

            _ ->
              Logger.debug("assigning from anonymous cookie to older consent #{consent.id}")
              {:assign_from_newer_cookie, user, cookie_consent}
          end

        # :expired or :not_found
        {tag, %ConsentSettings{user_id: nil} = _anonymous_user} ->
          Logger.debug("user consent #{tag}: assigning from anonymous cookie")
          {:assign_from_anonymous_cookie, user, cookie_consent}

        {:not_found, %ConsentSettings{user_id: ^user_id} = _same_user} ->
          Logger.debug("using cookie #{cookie_consent.id} from same user")
          {:use_cookie_consent, cookie_consent}

        {tag, %ConsentSettings{user_id: ^user_id} = _same_user} ->
          case DateTime.compare(consent.consented_at, cookie_consent.consented_at) do
            :gt ->
              case tag do
                :ok ->
                  Logger.debug("assigning to same user cookie from newer consent #{consent.id}")
                  {:assign_from_user_to_cookie, user, consent, false}

                :expired ->
                  Logger.debug("consent expired for #{user.id} (same user)")
                  {:no_op, consent, true}
              end

            _ ->
              Logger.debug("assigning from same user cookie to older consent #{consent.id}")
              {:assign_from_newer_cookie, user, cookie_consent}
          end

        {:not_found, %ConsentSettings{user_id: other_user_id} = _other_user} ->
          Logger.debug("no consent for #{user.id}, cookie was from #{other_user_id}")
          {:cookie_other_user, user}

        {:ok, %ConsentSettings{user_id: _other_user_id} = _other_user} ->
          Logger.debug("no op for #{user.id} (other user)")
          {:no_op, consent, false}

        {:expired, %ConsentSettings{user_id: _other_user_id} = _other_user} ->
          Logger.debug("consent expired for #{user.id} (other user)")
          {:no_op, consent, true}
      end

    {conn, disposition}
  end

  defp process_cookie_logic({conn, disposition}) do
    tag = elem(disposition, 0)
    Logger.debug("cookie logic #{tag}")

    {conn, consent, show_cookie_modal} =
      case disposition do
        {:no_op, consent, show_cookie_modal} ->
          {conn, consent, show_cookie_modal}

        {:use_cookie_consent, cookie_consent} ->
          {conn, cookie_consent, false}

        {:cookie_other_user, user} ->
          {conn, Accounts.create_user_consent!(user, %{consented: :all}), true}

        {:assign_from_newer_cookie, user, cookie_consent} ->
          {conn, Accounts.assign_user_consent!(user, cookie_consent), false}

        {:assign_from_user_to_cookie, user, consent, show_cookie_modal} ->
          {assign_and_write_consent_cookie(conn, consent, user.id), consent, show_cookie_modal}

        {:assign_from_anonymous_cookie, user, cookie_consent} ->
          consent = Accounts.assign_user_consent!(user, cookie_consent)
          {write_consent_cookie(conn, consent), consent, false}

        {:create_anonymous_consent, _nil} ->
          consent = Accounts.create_anonymous_consent!(%{consented: :all})
          {write_consent_cookie(conn, consent), consent, true}

        {:create_user_consent, user} ->
          consent = Accounts.create_user_consent!(user, %{consented: :all})
          {write_consent_cookie(conn, consent), consent, true}
      end

    conn
    |> put_session(:cookie_consent, consent)
    |> put_session(:show_cookie_modal, show_cookie_modal)
    |> assign(:show_cookie_modal, show_cookie_modal)
  end

  defp assign_cookie_consent(socket, session) do
    consent = session["cookie_consent"] || Accounts.create_anonymous_consent!(%{consented: :all})
    show_cookie_modal = session["show_cookie_modal"]

    Logger.debug("assign_cookie_consent: #{consent.id}")
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
