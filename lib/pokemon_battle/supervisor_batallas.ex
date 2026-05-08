defmodule PokemonBattle.SupervisorBatallas do
  use DynamicSupervisor

  alias PokemonBattle.Batalla

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def crear_batalla(jugador1, jugador2) do
    spec = {Batalla, {jugador1, jugador2}}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def batallas_activas() do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
