defmodule Mmorpg.GameSupervisor do
  use DynamicSupervisor

  alias Mmorpg.GameServer

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_game(name) do
    spec = {GameServer, name}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_game(name) do
    Supervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end

  def current_games() do
    games = Supervisor.which_children(__MODULE__)
    |> Enum.map(fn child ->
      {_id, pid, _type, _modules } = child
      pid
    end)
    |> Enum.filter(fn pid ->
      {:ok, status} = GameServer.open?(pid)
      status
    end)
    |> Enum.map(fn pid ->
      {:ok, game_id} = GameServer.game_id(pid)
      game_id
    end)
    IO.inspect(games)
    {:ok, games}
  end

  defp pid_from_name(name) do
    name
    |> GameServer.via_tuple()
    |> GenServer.whereis()
  end

end
