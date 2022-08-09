defmodule ConsentWeb.ConsentController do
  use ConsentWeb, :controller

  alias ConsentWeb.{ConsentHelpers, UserAuth}

  # We come here to update the cookie_consent cookie
  def update(conn, %{"consent_params" => consent_params}) do
    user = conn.assigns.current_user
    consent = get_session(conn, :cookie_consent)

    case ConsentHelpers.handle_consent_form_data(consent, user, consent_params) do
      {:ok, consent} ->
        conn
        |> UserAuth.write_consent_cookie(consent)
        |> put_flash(:info, "Cookie preferences were saved in a cookie successfully.")
        |> redirect(to: "/")
        |> halt()

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Houston, we had a problem.")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def alpine_modal(conn, _params) do
    render(conn, "alpine_modal.html")
  end
end
