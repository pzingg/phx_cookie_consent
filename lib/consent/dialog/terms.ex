defmodule Consent.Dialog.Terms do
  use Ecto.Schema

  # TODO: application.get_env()
  @current_terms_version "1.1.0"

  embedded_schema do
    field :title, :string, virtual: true
    field :description, :string, virtual: true
    field :show, :boolean, virtual: true
    field :version, :boolean
    field :consent_given, :boolean
  end

  def changeset(terms, attrs) do
    terms
    |> Ecto.Changeset.cast(attrs, [:version, :consent_given])
    |> Ecto.Changeset.validate_required([:version, :consent_given])
  end

  def current_version() do
    @current_terms_version
  end

  def set_consent(terms, nil) do
    %__MODULE__{terms | show: false, version: current_version(), consent_given: true}
  end

  def set_consent(terms, version) when is_binary(version) do
    version_to_set = current_version()

    %__MODULE__{
      terms
      | show: false,
        version: version_to_set,
        consent_given: Version.compare(version, version_to_set) != :lt
    }
  end

  def builtin() do
    %__MODULE__{
      title: "Terms and Conditions",
      description: """
      Please read the site's Terms and Conditions, version #{current_version()}.
      By continuing to use this website, you consent to those terms.
      """
    }
  end
end
