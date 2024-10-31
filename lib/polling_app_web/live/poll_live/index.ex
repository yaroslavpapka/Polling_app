defmodule PollingAppWeb.PollLive.Index do
  use PollingAppWeb, :live_view

  alias PollingApp.Accounts
  alias PollingApp.Polls
  alias PollingApp.Polls.Poll

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: PollingAppWeb.Endpoint.subscribe("polls:updates")

    user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:polls, Polls.list_polls())
     |> assign(:new_poll, %Poll{})
     |> assign(:choices, [""])
     |> assign(:changeset, Polls.change_poll(%Poll{}))}
  end

  @impl true
  def handle_event("add_choice", _params, socket) do
    new_choices = socket.assigns.choices ++ [""]
    {:noreply, assign(socket, :choices, new_choices)}
  end

  @impl true
  def handle_event("update_choice", %{"index" => index, "value" => value}, socket) do
    choices = List.update_at(socket.assigns.choices, String.to_integer(index), fn _ -> value end)
    {:noreply, assign(socket, :choices, choices)}
  end

  @impl true
  def handle_event("save_poll", %{"poll" => poll_params}, socket) do
    choices = socket.assigns.choices |> Enum.filter(&(&1 != ""))

    poll_params =
      poll_params
      |> Map.put("choices", choices)
      |> Map.put("user_id", socket.assigns.user.id)

    case Polls.create_poll(poll_params) do
      {:ok, poll} ->
        PollingAppWeb.Endpoint.broadcast("polls:updates", "new_poll", %{poll: poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll created successfully")
         |> assign(:polls, Polls.list_polls())
         |> assign(:choices, [""])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("vote", %{"poll_id" => poll_id, "choice" => choice}, socket) do
    user_id = socket.assigns.user.id

    case Polls.vote(poll_id, user_id, choice) do
      {:ok, _vote} ->
        PollingAppWeb.Endpoint.broadcast("polls:updates", "vote", %{poll_id: poll_id})
        {:noreply, assign(socket, :polls, Polls.list_polls())}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "You have already voted in this poll")}
    end
  end

  @impl true
  def handle_info(%{event: "new_poll", payload: %{poll: _poll}}, socket) do
    {:noreply, assign(socket, :polls, Polls.list_polls())}
  end

  def handle_info(%{event: "vote", payload: %{poll_id: _poll_id}}, socket) do
    {:noreply, assign(socket, :polls, Polls.list_polls())}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Polling Application</h1>

      <%= if @user do %>
        <div class="mb-6">
          <h2 class="text-xl font-semibold">Create a New Poll</h2>

          <.form for={@changeset} phx-submit="save_poll">
            <label for="poll_title" class="block">Title</label>
            <input
              type="text"
              id="poll_title"
              name="poll[title]"
              class="border rounded w-full py-2 px-3"
            />
            <label for="poll_description" class="block mt-2">Description</label> <textarea
              id="poll_description"
              name="poll[description]"
              class="border rounded w-full py-2 px-3"
            ></textarea>
            <h3 class="text-lg font-semibold mt-4">Choices</h3>

            <%= for {choice, index} <- Enum.with_index(@choices) do %>
              <input
                type="text"
                name="poll[choices][]"
                value={choice}
                phx-keyup="update_choice"
                phx-value-index={index}
                class="border rounded w-full py-2 px-3 mb-2"
              />
            <% end %>

            <button
              type="button"
              phx-click="add_choice"
              class="mt-2 bg-green-500 text-white py-1 px-2 rounded"
            >
              + Add Choice
            </button>

            <button type="submit" class="mt-4 bg-blue-500 text-white py-2 px-4 rounded">
              Create Poll
            </button>
          </.form>
        </div>
      <% end %>

      <h2 class="text-xl font-semibold">Active Polls</h2>

      <div>
        <%= for poll <- @polls do %>
          <% user_vote = Enum.find(poll.votes, fn vote -> vote.user_id == @user.id end) %> <% choices =
            vote_statistics(poll) %>
          <div class="border p-4 mt-4 rounded">
            <h3 class="font-bold"><%= poll.title %></h3>

            <p><%= poll.description %></p>

            <div class="mt-2">
              <%= for choice <- choices do %>
                <button
                  phx-click="vote"
                  phx-value-poll_id={poll.id}
                  phx-value-choice={choice.choice}
                  class={
                    if user_vote && user_vote.choice == choice.choice,
                      do: "bg-green-500 text-white",
                      else:
                        if(user_vote,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-blue-500 text-white hover:bg-blue-600"
                        )
                  }
                  disabled={user_vote != nil}
                >
                  <%= choice.choice %>
                  <%= if user_vote do %>
                    - <%= choice.percentage %>% (<%= choice.votes %> votes)
                  <% end %>
                </button>
              <% end %>
            </div>

            <div class="mt-2">
              <p class="text-sm text-gray-600">Total Votes: <%= length(poll.votes) %></p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp vote_statistics(poll) do
    total_votes = length(poll.votes)

    Enum.map(poll.choices, fn choice ->
      choice_votes = Enum.count(poll.votes, fn vote -> vote.choice == choice end)
      percentage = if total_votes > 0, do: round(choice_votes * 100 / total_votes), else: 0

      %{
        choice: choice,
        votes: choice_votes,
        percentage: percentage
      }
    end)
  end
end
