defmodule Consent.Accounts.Consent do
  use Ecto.Schema
  import Ecto.Changeset

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

  def anonymous_changeset(consent, attrs) do
    consent
    |> cast(attrs, [:user_id, :terms, :groups, :consented_at, :expires_at])
    |> validate_required([:consented_at, :expires_at])
  end

  def user_changeset(consent, attrs) do
    consent
    |> cast(attrs, [:user_id, :terms, :groups, :consented_at, :expires_at])
    |> validate_required([:user_id, :consented_at, :expires_at])
  end
end
