defmodule PokemonBattleTest do
  use ExUnit.Case
  doctest PokemonBattle

  test "greets the world" do
    assert PokemonBattle.hello() == :world
  end
end
