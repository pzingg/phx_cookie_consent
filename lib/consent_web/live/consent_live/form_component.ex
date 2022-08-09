defmodule ConsentWeb.ConsentLive.FormComponent do
  use ConsentWeb, :live_component

  alias ConsentWeb.ConsentHelpers

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :action, :new)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  @impl true
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

    socket =
      socket
      |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"consent_params" => consent_params}, socket) do
    socket =
      if socket.assigns.submit_form do
        assign(socket, :trigger_submit, true)
      else
        user = socket.assigns.current_user
        consent = socket.assigns.cookie_consent

        case ConsentHelpers.handle_consent_form_data(consent, user, consent_params) do
          {:ok, _consent} ->
            socket
            |> put_flash(
              :info,
              "Cookie preferences were updated successfully (but not written to the cookie)."
            )
            |> redirect(to: "/")

          {:error, _changeset} ->
            socket
            |> put_flash(:error, "Houston, we had a problem.")
            |> redirect(to: "/")
        end
      end

    {:noreply, socket}
  end
end
