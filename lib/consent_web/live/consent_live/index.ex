defmodule ConsentWeb.ConsentLive.Index do
  use ConsentWeb, :live_view

  require Logger

  alias Consent.Accounts
  alias Consent.Accounts.{ConsentForm, ConsentGroup}
  alias ConsentWeb.LayoutComponent
  alias ConsentWeb.ConsentLive.FormComponent

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
    user = socket.assigns.current_user

    consented_groups =
      case Accounts.get_consent(user) do
        nil -> nil
        consent -> consent.groups
      end

    groups =
      ConsentGroup.builtin_groups()
      |> Enum.map(fn {_slug, group} ->
        ConsentGroup.set_consent(group, consented_groups)
        |> Map.from_struct()
      end)

    changeset =
      ConsentForm.changeset(
        %ConsentForm{},
        %{terms_version: "1.0.0", terms_agreed: true, groups: groups}
      )

    LayoutComponent.hide_modal()

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show", _params, socket) do
    socket =
      socket
      |> show_consent_modal()

    {:noreply, socket}
  end

  def handle_event("toggle_group", %{"slug" => slug}, socket) do
    changeset = socket.assigns.changeset

    group_changesets =
      Enum.map(changeset.changes.groups, fn group_changeset ->
        %Ecto.Changeset{changes: group} = group_changeset

        show =
          if group.slug == slug do
            !group.show
          else
            false
          end

        %Ecto.Changeset{group_changeset | changes: Map.put(group, :show, show)}
      end)

    changes = Map.put(changeset.changes, :groups, group_changesets)
    changeset = %Ecto.Changeset{changeset | changes: changes}

    send_update(FormComponent, id: "consent-modal", changeset: changeset)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"consent_params" => consent_params}, socket) do
    user = socket.assigns.current_user
    update_consent(user, consent_params)

    socket =
      socket
      |> put_flash(:info, "Cookie preferences were updated successfully.")
      |> redirect(to: "/")

    {:noreply, socket}
  end

  def update_consent(user, consent_params) do
    Logger.info("update #{inspect(consent_params)}")

    groups =
      Map.get(consent_params, "groups", %{})
      |> Enum.into([])
      |> Enum.map(fn
        {_, %{"consent_given" => "true", "slug" => slug}} -> slug
        _ -> nil
      end)
      |> Enum.filter(fn slug -> !is_nil(slug) end)

    consent =
      Accounts.update_consent(user, %{
        terms: Map.get(consent_params, "terms_version"),
        groups: groups
      })

    Logger.info("consent now #{inspect(consent)}")
  end

  defp show_consent_modal(socket) do
    LayoutComponent.show_modal(FormComponent, %{
      id: "consent-modal",
      confirm: {"Save", type: "submit", form: "consent-form"},
      on_confirm: hide_modal("consent-modal"),
      patch: "/",
      changeset: socket.assigns.changeset,
      title: "Manage Cookies",
      current_user: socket.assigns.current_user
    })

    socket
  end
end
