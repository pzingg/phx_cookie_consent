import Config

# or :gigalixir
platform = :fly

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  case platform do
    :fly ->
      config :consent, Consent.Repo,
        # ssl: true,
        # IMPORTANT: Or it won't find the DB server
        socket_options: [:inet6],
        url: database_url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

    :gigalixir ->
      config :consent, Consent.Repo,
        adapter: Ecto.Adapters.Postgres,
        url: System.get_env("DATABASE_URL"),
        ssl: true,
        pool_size: 2
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint by setting `server: true`.
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  case platform do
    :fly ->
      app_name =
        System.get_env("FLY_APP_NAME") ||
          raise "environment variable FLY_APP_NAME is missing."

      config :consent, ConsentWeb.Endpoint,
        url: [host: "#{app_name}.fly.dev", port: 80],
        http: [
          # Enable IPv6 and bind on all interfaces.
          # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
          # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
          # for details about using IPv6 vs IPv4 and loopback vs public addresses.
          ip: {0, 0, 0, 0, 0, 0, 0, 0},
          port: String.to_integer(System.get_env("PORT") || "4000")
        ],
        secret_key_base: secret_key_base,
        server: true

    :gigalixir ->
      app_name =
        System.get_env("APP_NAME") ||
          raise "environment variable APP_NAME is missing."

      # Gigalixir Free Tier configuration
      # See https://gigalixir.readthedocs.io/en/latest/modify-app/index.html
      # Free tier db only allows 4 connections. Rolling deploys need pool_size*(n+1) connections where n is the number of app replicas.
      config :consent, ConsentWeb.Endpoint,
        url: [host: "#{app_name}.gigalixirapp.com", port: 443],
        # Possibly not needed, but doesn't hurt
        http: [port: {:system, "PORT"}],
        secret_key_base: secret_key_base,
        server: true
  end

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :consent, Consent.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

if config_env() == :dev do
  database_url = System.get_env("DATABASE_URL")

  if database_url != nil do
    config :consent, Consent.Repo,
      url: database_url,
      socket_options: [:inet6]
  end
end
