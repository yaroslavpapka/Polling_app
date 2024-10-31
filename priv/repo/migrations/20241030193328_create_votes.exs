defmodule PollingApp.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :choice, :string
      add :poll_id, references(:polls, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:votes, [:poll_id])
    create index(:votes, [:user_id])
    create unique_index(:votes, [:poll_id, :user_id])
  end
end
