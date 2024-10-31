defmodule PollingApp.Repo.Migrations.AddChoicesToPolls do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :choices, {:array, :string}, default: []
    end
  end
end
