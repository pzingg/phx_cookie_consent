defmodule ConsentWeb.ConsentLive.Index do
  use ConsentWeb, :live_view

  require Logger

  alias Consent.Accounts
  alias Consent.Accounts.{ConsentForm, ConsentGroup}

  @impl true
  def mount(
        _params,
        _session,
        socket
      ) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    groups =
      ConsentGroup.builtin_groups()
      |> Enum.map(fn {_, group} -> ConsentGroup.set_consent(group) |> Map.from_struct() end)

    changeset =
      ConsentForm.changeset(
        %ConsentForm{},
        %{terms_version: "1.0.0", terms_agreed: true, groups: groups}
      )

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide", params, socket) do
    Logger.info("hide #{inspect(params)}")
    {:noreply, socket}
  end

  def handle_event("change", %{"consent_params" => _consent_params}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"consent_params" => consent_params}, socket) do
    update_consent(consent_params)

    socket =
      socket
      |> put_flash(:info, "Cookie preferences were updated successfully.")
      |> redirect(to: "/")

    {:noreply, socket}
  end

  def update_consent(consent_params) do
    Logger.info("update #{inspect(consent_params)}")

    terms_version = Map.get(consent_params, "terms_version")
    terms_agreed = Map.get(consent_params, "terms_agreed")

    groups =
      Map.get(consent_params, "groups", %{})
      |> Enum.into([])
      |> Enum.map(fn
        {_, %{"consent_given" => "true", "slug" => slug}} -> slug
        _ -> nil
      end)
      |> Enum.filter(fn slug -> !is_nil(slug) end)

    user = Accounts.current_user!()

    consent =
      Accounts.update_consent(user, %{
        terms: terms_version,
        groups: groups
      })

    Logger.info("consent now #{inspect(consent)}")
  end
end
