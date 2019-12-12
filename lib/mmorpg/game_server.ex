defmodule Mmorpg.GameServer do

  use GenServer

  alias Mmorpg.Player

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def init(game_id) do
    {:ok, %{game_id: game_id, status: :open, players: %{}}}
  end

  def current_players(server), do: GenServer.call(server, :current_players)
  def add_player(server, player_info), do: GenServer.call(server, {:add_player, player_info})
  def remove_player(server, player_name), do: GenServer.call(server, {:remove_player, player_name})
  def move_player(server, player_name, %{} = player_info), do: GenServer.call(server, {:move_player, player_name, player_info})
  def sync_player(server, player_name, %{} = player_info), do: GenServer.call(server, {:sync_player, player_name, player_info})
  def open?(server), do: GenServer.call(server, :open)
  def game_id(server), do: GenServer.call(server, :game_id)
  def game_data(server), do: GenServer.call(server, :game_data)

  def handle_call(:current_players, _from, state) do
    players = state.players
    |> Enum.map(fn {player_id, player} ->
      {player_id, Player.to_map(player)} end)
    |> Map.new()
    {:reply, {:ok, players}, state}
  end

  def handle_call({:add_player, player_info}, _from, state) do
    player = Player.new(player_info)
    state = %{state | players: Map.put(state.players, player.id, player)}
    {:reply, {:ok, player}, state}
  end

  def handle_call({:remove_player, player_name}, _from, state) do
    new_state = %{state | players: Map.delete(state.players, player_name)}
    case new_state.players do
      %{} -> {:reply, {:ok, :empty}, new_state}
      _   -> {:reply, :ok, new_state}
    end
  end

  def handle_call({:move_player, player_name, %{} = player_info}, _from, state) do
      player = Map.get(state.players, player_name)
      player = player
      |> Map.put(:move_left, Map.get(player_info, "moveLeft", player.move_left))
      |> Map.put(:move_right, Map.get(player_info, "moveRight", player.move_right))
      |> Map.put(:move_up, Map.get(player_info, "moveUp", player.move_up))
      |> Map.put(:move_down, Map.get(player_info, "moveDown", player.move_down))

      state = %{state | players: Map.put(state.players, player_name, player)}

      {:reply, {:ok, Player.to_map(player)}, state}
  end

  def handle_call({:sync_player, player_name, %{} = player_info}, _from, state) do
    player = Map.get(state.players, player_name)
    player = player
    |> Map.put(:move_left, Map.get(player_info, "moveLeft", player.move_left))
    |> Map.put(:move_right, Map.get(player_info, "moveRight", player.move_right))
    |> Map.put(:move_up, Map.get(player_info, "moveUp", player.move_up))
    |> Map.put(:move_down, Map.get(player_info, "moveDown", player.move_down))
    |> Map.put(:x, Map.get(player_info, "x", player.x))
    |> Map.put(:y, Map.get(player_info, "y", player.y))

    state = %{state | players: Map.put(state.players, player_name, player)}

    {:reply, {:ok, Player.to_map(player)}, state}
  end

  def handle_call(:open, _from, state) do
    {:reply, {:ok, state.status == :open}, state}
  end

  def handle_call(:game_id, _from, state) do
    {:reply, {:ok, state.game_id}, state}
  end

  def handle_call(:game_data, _from, state) do
    {:reply, {:ok, %{"gameId" => state.game_id, "status" => state.status}}, state}
  end

  def via_tuple(game_id) do
    {:via, Registry, {Registry.Game, game_id}}
  end
end
