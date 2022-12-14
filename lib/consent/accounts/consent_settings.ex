defmodule Consent.Accounts.ConsentSettings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  # TODO: fetch these from application.get_env()
  @current_terms_version "1.1.0"
  @all_cookie_groups ["mandatory", "functional", "measurement", "marketing"]

  schema "consents" do
    # We may have nil here
    # belongs_to :user, User, type: Ecto.UUID
    field :terms, :string
    field :groups, {:array, :string}, default: []
    field :consented_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :user_id, Ecto.UUID

    timestamps()
  end

  def expires_from_now(%__MODULE__{} = consent) do
    DateTime.diff(consent.expires_at, DateTime.utc_now(), :second)
  end

  def current_version(), do: @current_terms_version

  def all_groups(), do: @all_cookie_groups

  @doc """
  The `:user_id` in `%ConsentSettings{}` struct is always set by `:cast_assoc`,
  so we don't include it in `cast`, or require it.
  """
  def changeset(%__MODULE__{} = consent, attrs) do
    attrs = set_consent(attrs)

    consent
    |> cast(attrs, [:terms, :groups, :consented_at, :expires_at])
    |> validate_required([:consented_at, :expires_at])
    |> validate_version(:terms)
  end

  defp set_consent(attrs) do
    {consented, attrs} = Map.pop(attrs, :consented)

    case consented do
      :all ->
        attrs
        |> consent_current_terms()
        |> consent_all_groups()

      :terms ->
        consent_current_terms(attrs)

      :groups ->
        consent_all_groups(attrs)

      _ ->
        attrs
    end
  end

  defp consent_current_terms(attrs) do
    Map.put(attrs, :terms, current_version())
  end

  defp consent_all_groups(attrs) do
    Map.put(attrs, :groups, all_groups())
  end

  def validate_version(changeset, field) do
    validate_change(changeset, field, fn key, value ->
      case Version.parse(value) do
        {:ok, _} -> []
        :error -> [key, "must be a semantic version (major.minor.patch)"]
      end
    end)
  end
end
