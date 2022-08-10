defmodule ConsentWeb.ConsentController do
  use ConsentWeb, :controller

  alias Consent.Accounts.ConsentGroup
  alias ConsentWeb.{ConsentHelpers, UserAuth}

  @current_terms_version "1.1.0"

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
    cookie_consent = get_session(conn, :cookie_consent)
    consented_groups = cookie_consent.groups

    groups_with_index =
      ConsentGroup.builtin_groups()
      |> Enum.map(fn {_slug, group} ->
        ConsentGroup.set_consent(group, consented_groups)
        |> Map.from_struct()
      end)
      |> Enum.with_index()

    form_action = Routes.consent_update_path(conn, :update)
    csrf_token = Phoenix.HTML.Tag.csrf_token_value(form_action)

    render(conn, "alpine_modal.html",
      form_action: form_action,
      csrf_token: csrf_token,
      terms_version: @current_terms_version,
      groups_with_index: groups_with_index
    )
  end
end
