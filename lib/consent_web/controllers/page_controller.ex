defmodule ConsentWeb.PageController do
  use ConsentWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Welcome!")
  end

  def terms(conn, _params) do
    render(conn, "terms.html", page_title: "Terms and Conditions")
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html", page_title: "Privacy Policy")
  end

  def cookies(conn, _params) do
    render(conn, "cookies.html", page_title: "Cookie List")
  end
end
