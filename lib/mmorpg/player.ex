defmodule Mmorpg.Player do

  defstruct [
    :rotation,
    :x,
    :y,
    :id,
    :move_left,
    :move_right,
    :move_up,
    :move_down
  ]

  alias __MODULE__

  def new(player_info) do
    IO.inspect(player_info)
    %Player{
      rotation: 0,
      x: Map.get(player_info, "x", :math.floor(:rand.uniform() * 400) + 50),
      y: Map.get(player_info, "y", :math.floor(:rand.uniform() * 500) + 50),
      id: Map.get(player_info, "playerId"),
      move_left: false,
      move_right: false,
      move_up: false,
      move_down: false,
    }
  end

  def to_map(%Player{} = player) do
    %{
      "x" => player.x,
      "y" => player.y,
      "rotation" => player.rotation,
      "id" => player.id,
      "moveLeft" => player.move_left,
      "moveRight" => player.move_right,
      "moveUp" => player.move_up,
      "moveDown" => player.move_down,
    }
  end

end
