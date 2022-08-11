defmodule Consent.Accounts.Consent do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

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

  def expires_from_now(%Consent{} = consent) do
    DateTime.diff(consent.expires_at, DateTime.utc_now(), :second)
  end

  def anonymous_changeset(%Consent{} = consent, attrs) do
    consent
    |> cast(attrs, [:user_id, :terms, :groups, :consented_at, :expires_at])
    |> validate_required([:consented_at, :expires_at])
    |> validate_version(:terms)
  end

  def user_changeset(%Consent{} = consent, attrs) do
    consent
    |> cast(attrs, [:user_id, :terms, :groups, :consented_at, :expires_at])
    |> validate_required([:user_id, :consented_at, :expires_at])
    |> validate_version(:terms)
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
