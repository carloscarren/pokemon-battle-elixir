defmodule PokemonBattle.SupervisorBatallas do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def crear_batalla(jugador1, jugador2) do
    spec = {PokemonBattle.Batalla, {jugador1, jugador2}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
