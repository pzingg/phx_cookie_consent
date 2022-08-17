defmodule ConsentWeb.Router do
  use ConsentWeb, :router

  import ConsentWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ConsentWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_cookie_consent
  end

  pipeline :static do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ConsentWeb.LayoutView, :root}
    plug :no_cookie_modal
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ConsentWeb do
    pipe_through :static

    get "/terms", PageController, :terms
    get "/privacy", PageController, :privacy
    get "/cookies", PageController, :cookies
  end

  scope "/", ConsentWeb do
    pipe_through :browser

    live_session :current_user, on_mount: {ConsentWeb.UserAuth, :current_user} do
      live "/test_page", PageLive.Index, :index
    end

    get "/", PageController, :index

    get "/consent", ConsentController, :edit_summary
    post "/consent", ConsentController, :update_summary
    get "/consent/more", ConsentController, :edit_details
    post "/consent/more", ConsentController, :update_details
  end

  # Other scopes may use custom stacks.
  # scope "/api", ConsentWeb do
  #   pipe_through :api
  # end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ConsentWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", ConsentWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", ConsentWeb do
    pipe_through :browser

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
