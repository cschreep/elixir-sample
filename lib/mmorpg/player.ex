defmodule Mmorpg.Player do

  defstruct [
    :rotation,
    :x,
    :y,
    :flip_x,
    :id,
    :move_left,
    :move_right,
    :move_up,
    :move_down
  ]

  alias __MODULE__

  def new(player_name) do
    %Player{
      rotation: 0,
      x: :math.floor(:rand.uniform() * 400) + 50,
      y: :math.floor(:rand.uniform() * 500) + 50,
      flip_x: false,
      id: player_name,
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
      "flipX" => player.flip_x,
      "rotation" => player.rotation,
      "id" => player.id,
      "left" => player.move_left,
      "right" => player.move_right,
      "up" => player.move_up,
      "down" => player.move_down,
    }
  end

end
