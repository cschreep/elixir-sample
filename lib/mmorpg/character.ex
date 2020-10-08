defmodule Mmorpg.Character do

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

  def new(character_info) do
    IO.inspect(character_info)
    %Character{
      rotation: 0,
      x: Map.get(character_info, "x", :math.floor(:rand.uniform() * 400) + 50),
      y: Map.get(character_info, "y", :math.floor(:rand.uniform() * 500) + 50),
      id: Map.get(character_info, "characterId"),
      move_left: false,
      move_right: false,
      move_up: false,
      move_down: false,
    }
  end

  def to_map(%Character{} = character) do
    %{
      "x" => character.x,
      "y" => character.y,
      "rotation" => character.rotation,
      "id" => character.id,
      "moveLeft" => character.move_left,
      "moveRight" => character.move_right,
      "moveUp" => character.move_up,
      "moveDown" => character.move_down,
    }
  end

end
