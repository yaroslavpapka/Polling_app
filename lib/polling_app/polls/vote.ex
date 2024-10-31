defmodule PollingApp.Polls.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :choice, :string

    belongs_to :poll, PollingApp.Polls.Poll
    belongs_to :user, PollingApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:choice, :poll_id, :user_id])
    |> validate_required([:choice, :poll_id, :user_id])
    |> foreign_key_constraint(:poll_id)
    |> foreign_key_constraint(:user_id)
  end
end
