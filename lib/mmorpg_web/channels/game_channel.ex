defmodule MmorpgWeb.GameChannel do
  use MmorpgWeb, :channel

  alias Mmorpg.{GameServer, GameSupervisor, Player}

  def join("games:lobby", _payload, socket) do
    with {:ok, games} <- GameSupervisor.current_games() do
      {:ok, %{"games" => games}, socket}
    else
      {:error, %{} = reason} ->
        {:error, reason}
      _ ->
        {:error, %{"reason" => "Unspecified error"}}
    end
  end

  def join("games:"<> _game_id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("currentGames", _payload, socket) do
    with {:ok, games} <- GameSupervisor.current_games() do
      {:reply, {:ok, %{"games" => games}}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  def handle_in("startGame", _payload, socket) do
    game_id = System.unique_integer([:positive])
    |> Integer.to_string()

    with {:ok, game_pid} <- GameSupervisor.start_game(game_id),
         {:ok, game_data} <- GameServer.game_data(game_pid)
    do
      broadcast_from(socket, "gameAdded", game_data)
      {:reply, {:ok, %{"gameId" => game_id}}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, socket}
      :error ->
        {:reply, :error, socket}
    end
  end

  def handle_in("addPlayer", %{}=player_info, socket) do
    {:ok, current_players} = GameServer.current_players(via(socket.topic))
    # TODO refactor params to PlayerInfo map
    case GameServer.add_player(via(socket.topic), player_info) do
      {:ok, player} ->
        player_map = Player.to_map(player)
        broadcast_from(socket, "newPlayer", player_map)
        push(socket, "currentPlayers", current_players)
        IO.inspect(player)
        {:reply, {:ok, player_map}, assign(socket, :player_id, player.id)}
      :error ->
        {:reply, :error, socket}
    end
  end

  def handle_in("movePlayer", player_info, socket) do
    player_id = socket.assigns.player_id
    case GameServer.move_player(via(socket.topic), player_id, player_info) do
    {:ok, player} ->
      broadcast(socket, "playerMoved", player)
      {:noreply, socket}
    {:error, reason} ->
      {:reply, {:error, %{"error" => reason}}, socket}
    :error ->
      {:reply, :error, socket}
    end
  end

  def handle_in("syncUp", %{} = player_info, socket) do
    player_id = socket.assigns.player_id
    case GameServer.sync_player(via(socket.topic), player_id, player_info) do
    {:ok, player} ->
      broadcast_from(socket, "syncDown", player)
      {:noreply, socket}
    {:error, reason} ->
      {:reply, {:error, %{"error" => reason}}, socket}
    :error ->
      {:reply, :error, socket}
    end
  end

  defp via("games:" <> game_id) do
    game_id
    |> IO.inspect()
    |> GameServer.via_tuple()
  end
end
