defmodule ConsentWeb.ConsentController do
  use ConsentWeb, :controller

  require Logger

  alias Consent.Accounts.ConsentSettings
  alias ConsentWeb.{ConsentHelpers, UserAuth}

  def edit_summary(conn, _params) do
    render(conn, "edit_summary.html",
      form_action: Routes.consent_path(conn, :update_summary),
      learn_more_href: Routes.consent_path(conn, :edit_details),
      return_to: "/",
      show_event: "consent-modal-show"
    )
  end

  def update_summary(conn, params) do
    user = conn.assigns.current_user
    consent = get_session(conn, :cookie_consent)

    allowed_cookies = get_in(params, ["consent_params", "allowed_cookies"]) || "all"
    Logger.info("update_summary #{inspect(params)} -> #{allowed_cookies}")

    case ConsentHelpers.handle_summary_form_data(consent, user, allowed_cookies) do
      {:ok, consent} ->
        Logger.info("updated terms: #{inspect(consent.terms)} groups: #{inspect(consent.groups)}")

        conn
        |> UserAuth.write_consent_cookie(consent)
        |> put_flash(:info, "Cookie preferences were updated successfully.")
        |> redirect(to: Routes.consent_path(conn, :drop_cookies))
        |> halt()

      {:error, _reason_or_changeset} ->
        conn
        |> put_flash(:error, "Houston, we had a problem.")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def edit_details(conn, _params) do
    cookie_consent = get_session(conn, :cookie_consent)

    # cookie_consent.terms may be nil
    render(conn, "edit_details.html",
      form_action: Routes.consent_path(conn, :update_details),
      terms_agreement: %{
        version: cookie_consent.terms,
        current_version: ConsentSettings.current_version()
      },
      groups: cookie_consent.groups,
      return_to: "/",
      show_event: "consent-modal-show"
    )
  end

  def update_details(conn, %{"consent_params" => consent_params}) do
    user = conn.assigns.current_user
    consent = get_session(conn, :cookie_consent)

    case ConsentHelpers.handle_details_form_data(consent, user, consent_params) do
      {:ok, consent} ->
        conn
        |> UserAuth.write_consent_cookie(consent)
        |> put_flash(:info, "Cookie preferences were updated successfully.")
        |> redirect(to: Routes.consent_path(conn, :drop_cookies))
        |> halt()

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Houston, we had a problem.")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def drop_cookies(conn, _params) do
    consent = get_session(conn, :cookie_consent)
    {conn, count} = UserAuth.drop_cookies(conn, consent)

    msg =
      case count do
        0 -> ""
        1 -> " and 1 cookie was removed"
        _ -> " and #{count} cookies were removed"
      end

    conn
    |> put_flash(:info, "Cookie preferences were updated successfully#{msg}.")
    |> redirect(to: "/")
    |> halt()
  end
end
