defmodule Consent.Repo.Migrations.CreateConsentSettings do
  use Ecto.Migration

  def change do
    create table(:consents, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :terms, :string
      add :groups, {:array, :string}
      add :consented_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
