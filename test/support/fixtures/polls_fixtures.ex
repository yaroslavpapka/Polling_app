defmodule PollingApp.PollsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PollingApp.Polls` context.
  """

  @doc """
  Generate a poll.
  """
  def poll_fixture(attrs \\ %{}) do
    {:ok, poll} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> PollingApp.Polls.create_poll()

    poll
  end

  @doc """
  Generate a vote.
  """
  def vote_fixture(attrs \\ %{}) do
    {:ok, vote} =
      attrs
      |> Enum.into(%{
        choice: "some choice"
      })
      |> PollingApp.Polls.create_vote()

    vote
  end
end
