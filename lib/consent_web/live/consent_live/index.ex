defmodule ConsentWeb.ConsentLive.Index do
  use ConsentWeb, :live_view

  require Logger

  alias Consent.Accounts.{ConsentForm, ConsentGroup}
  alias ConsentWeb.LayoutComponent
  alias ConsentWeb.ConsentLive.FormComponent

  @current_terms_version "1.1.0"

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
    cookie_consent = socket.assigns.cookie_consent
    consented_groups = cookie_consent.groups

    groups =
      ConsentGroup.builtin_groups()
      |> Enum.map(fn {_slug, group} ->
        ConsentGroup.set_consent(group, consented_groups)
        |> Map.from_struct()
      end)

    attrs =
      case cookie_consent.terms do
        version when is_binary(version) ->
          %{terms_version: version, terms_agreed: true, groups: groups}

        nil ->
          %{terms_version: @current_terms_version, terms_agreed: false, groups: groups}
      end

    changeset = ConsentForm.changeset(%ConsentForm{}, attrs)

    LayoutComponent.hide_modal()

    socket =
      socket
      |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show", params, socket) do
    submit_form = Map.get(params, "submit_form", false)
    submit_form = submit_form && submit_form != "false"

    socket =
      socket
      |> show_consent_modal(submit_form)

    {:noreply, socket}
  end

  defp show_consent_modal(socket, submit_form) do
    LayoutComponent.show_modal(FormComponent, %{
      id: "consent-modal",
      confirm: {"Save", type: "submit", form: "consent-form"},
      on_confirm: hide_modal("consent-modal"),
      patch: "/",
      changeset: socket.assigns.changeset,
      cookie_consent: socket.assigns.cookie_consent,
      submit_form: submit_form,
      trigger_submit: false,
      title: "Manage Cookies",
      current_user: socket.assigns.current_user
    })

    socket
  end
end
