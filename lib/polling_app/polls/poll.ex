defmodule PollingApp.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polls" do
    field :title, :string
    field :description, :string
    belongs_to :user, PollingApp.Accounts.User
    field :choices, {:array, :string}, default: []
    has_many :votes, PollingApp.Polls.Vote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :description, :user_id, :choices])
    |> validate_required([:title, :description])
  end
end
