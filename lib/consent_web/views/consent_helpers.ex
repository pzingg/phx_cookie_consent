defmodule ConsentWeb.ConsentHelpers do
  @moduledoc """
  Conveniences for processing consent form.
  """

  alias Consent.Accounts

  def handle_consent_form_data(consent, user, %{"groups" => groups, "terms" => terms}) do
    groups =
      groups
      |> Enum.into([])
      |> Enum.map(fn
        {_, %{"consent_given" => "true", "slug" => slug}} -> slug
        _ -> nil
      end)
      |> Enum.filter(fn slug -> !is_nil(slug) end)

    terms =
      case terms do
        %{"consent_given" => "true", "version" => version} -> version
        _ -> nil
      end

    update_consent(consent, user, %{terms: terms, groups: groups})
  end

  defp update_consent(consent, nil, consent_params) do
    Accounts.update_anonymous_consent(consent, consent_params)
  end

  defp update_consent(_consent, user, consent_params) do
    Accounts.update_consent(user, consent_params)
  end
end
