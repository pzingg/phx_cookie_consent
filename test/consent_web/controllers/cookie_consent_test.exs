defmodule ConsentWeb.CookieConsentTest do
  use ConsentWeb.ConnCase, async: true

  import Consent.AccountsFixtures

  @consent_cookie "_consent_web_cookie_consent"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, ConsentWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{conn: conn}
  end

  test "writes an anonymous consent cookie if user is not logged in", %{conn: conn} do
    conn = get(conn, "/")
    refute get_session(conn, :user_token)
    consent = get_session(conn, :cookie_consent)
    assert consent
    assert consent == conn.cookies[@consent_cookie]
    assert consent.user_id == nil

    assert %{value: signed_consent, max_age: max_age} = conn.resp_cookies[@consent_cookie]
    assert signed_consent != consent
    assert_in_delta max_age, 31_536_000, 100
  end

  test "writes a user consent cookie after user logs in", %{conn: conn} do
    email = unique_user_email()

    conn =
      post(conn, Routes.user_registration_path(conn, :create), %{
        "user" => valid_user_attributes(email: email)
      })

    assert get_session(conn, :user_token)

    # Now do a logged in request and assert on the menu
    conn = get(conn, "/")
    current_user = conn.assigns[:current_user]
    assert current_user

    consent = get_session(conn, :cookie_consent)
    assert consent
    assert consent == conn.cookies[@consent_cookie]
    assert consent.user_id == current_user.id

    assert %{value: signed_consent, max_age: max_age} = conn.resp_cookies[@consent_cookie]
    assert signed_consent != consent
    assert_in_delta max_age, 31_536_000, 100
  end
end
