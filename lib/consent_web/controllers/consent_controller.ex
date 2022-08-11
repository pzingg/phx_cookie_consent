defmodule ConsentWeb.ConsentController do
  use ConsentWeb, :controller

  alias Consent.Dialog.{Header, Terms, Group}
  alias ConsentWeb.{ConsentHelpers, UserAuth}

  def edit(conn, _params) do
    cookie_consent = get_session(conn, :cookie_consent)
    consented_groups = cookie_consent.groups

    groups_with_index =
      Group.builtins()
      |> Enum.map(fn {_slug, group} ->
        Group.set_consent(group, consented_groups)
        |> Map.from_struct()
      end)
      |> Enum.with_index()

    # cookie_consent.terms may be nil
    version = cookie_consent.terms
    terms = Terms.builtin() |> Terms.set_consent(version) |> Map.from_struct()

    render(conn, "edit.html",
      form_action: Routes.consent_path(conn, :update),
      header: Header.builtin(),
      terms: terms,
      groups_with_index: groups_with_index,
      return_to: "/",
      show_event: "consent-modal-show"
    )
  end

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
end
