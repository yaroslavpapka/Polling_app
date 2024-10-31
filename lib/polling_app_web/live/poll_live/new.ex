defmodule PollingAppWeb.PollLive.New do
  use PollingAppWeb, :live_view

  alias PollingApp.Polls
  alias PollingApp.Polls.Poll

  @impl true
  def mount(_params, %{"user_id" => user_id} = session, socket) do
    changeset = Polls.change_poll(%Poll{user_id: user_id})
    {:ok, assign(socket, changeset: changeset, user_id: user_id)}
  end

  @impl true
  def handle_event("save", %{"poll" => poll_params}, socket) do
    case Polls.create_poll(poll_params) do
      {:ok, _poll} ->
        {:noreply, socket |> put_flash(:info, "Poll created successfully!") |> push_redirect(to: "/polls")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
