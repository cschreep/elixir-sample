defmodule Mmorpg.GameServer do

  use GenServer

  alias Mmorpg.Player

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def init(_game_id) do
    {:ok, %{players: %{}}}
  end

  def current_players(server), do: GenServer.call(server, :current_players)
  def add_player(server, player_name, x, y), do: GenServer.call(server, {:add_player, player_name, x, y})
  def remove_player(server, player_name), do: GenServer.call(server, {:remove_player, player_name})
  def move_player(server, player_name, %{} = player_info), do: GenServer.call(server, {:move_player, player_name, player_info})
  def sync_player(server, player_name, %{} = player_info), do: GenServer.call(server, {:sync_player, player_name, player_info})

  def handle_call(:current_players, _from, state) do
    players = state.players
    |> Enum.map(fn {player_id, player} ->
      {player_id, Player.to_map(player)} end)
    |> Map.new()
    {:reply, {:ok, players}, state}
  end

  def handle_call({:add_player, player_name, x, y}, _from, state) do
    player = Player.new(player_name)
    |> Map.put(:x, x)
    |> Map.put(:y, y)
    state = %{state | players: Map.put(state.players, player_name, player)}
    {:reply, {:ok, Player.to_map(player)}, state}
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
      |> Map.put(:move_left, Map.get(player_info, "left", player.move_left))
      |> Map.put(:move_right, Map.get(player_info, "right", player.move_right))
      |> Map.put(:move_up, Map.get(player_info, "up", player.move_up))
      |> Map.put(:move_down, Map.get(player_info, "down", player.move_down))

      state = %{state | players: Map.put(state.players, player_name, player)}

      {:reply, {:ok, Player.to_map(player)}, state}
  end

  def handle_call({:sync_player, player_name, %{} = player_info}, _from, state) do
    player = Map.get(state.players, player_name)
    player = player
    |> Map.put(:move_left, Map.get(player_info, "left", player.move_left))
    |> Map.put(:move_right, Map.get(player_info, "right", player.move_right))
    |> Map.put(:move_up, Map.get(player_info, "up", player.move_up))
    |> Map.put(:move_down, Map.get(player_info, "down", player.move_down))
    |> Map.put(:x, Map.get(player_info, "x", player.x))
    |> Map.put(:y, Map.get(player_info, "y", player.y))
    |> Map.put(:flip_x, Map.get(player_info, "flip_x", player.flip_x))

    state = %{state | players: Map.put(state.players, player_name, player)}

    {:reply, {:ok, Player.to_map(player)}, state}
  end

  def via_tuple(game_id) do
    {:via, Registry, {Registry.Game, game_id}}
  end
end
