defmodule Consent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Consent.Repo,
      # Start the Telemetry supervisor
      ConsentWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Consent.PubSub},
      # Start the Endpoint (http/https)
      ConsentWeb.Endpoint
      # Start a worker by calling: Consent.Worker.start_link(arg)
      # {Consent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Consent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ConsentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
