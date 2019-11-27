defmodule MmorpgWeb.GameChannel do
  use MmorpgWeb, :channel

  alias Mmorpg.{GameServer, GameSupervisor}

  def join("game:lobby", _payload, socket) do
    GameSupervisor.start_game("lobby")
    {:ok, socket}
  end

  def handle_in("addPlayer", %{"playerId" => player_id}, socket) do
    {:ok, current_players} = GameServer.current_players(via(socket.topic))
    case GameServer.add_player(via(socket.topic), player_id) do
      {:ok, player} ->
        broadcast_from(socket, "newPlayer", player)
        push(socket, "currentPlayers", current_players)
        {:reply, {:ok, player}, assign(socket, :player_id, player_id)}
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

  def handle_in("syncPlayer", %{} = player_info, socket) do
    player_id = socket.assigns.player_id
    case GameServer.sync_player(via(socket.topic), player_id, player_info) do
    {:ok, player} ->
      broadcast_from(socket, "syncPlayer", player)
      {:noreply, socket}
    {:error, reason} ->
      {:reply, {:error, %{"error" => reason}}, socket}
    :error ->
      {:reply, :error, socket}
    end
  end

  def terminate({:shutdown, :left}, socket) do
    remove_player(socket)
  end

  def terminate({:shutdown, :closed}, socket) do
    case player_id = Map.get(socket.assigns, :player_id) do
      nil -> IO.inspect("Shutting down with empty player")
      _ ->
        GameServer.remove_player(via(socket.topic), player_id)
        broadcast_from(socket, "playerLeft", %{"playerId" => player_id})
      end
    socket
  end

  def terminate(_, socket) do
    socket
  end

  defp remove_player(socket) do
    player_id = socket.assigns.player_id
    case GameServer.remove_player(via(socket.topic), player_id) do
      :ok ->
        IO.inspect("Removed player")
        broadcast_from(socket, "playerLeft", %{"playerId" => player_id})
        socket
      {:ok, :empty} ->
        IO.inspect("Empty, closing game")
        "game:" <> game_id = socket.topic
        GameSupervisor.stop_game(game_id)
        socket
      _ ->
        IO.inspect("Error")
        socket
    end
  end

  defp via("game:" <> game_id), do: GameServer.via_tuple(game_id)

end
