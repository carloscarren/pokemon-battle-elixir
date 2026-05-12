defmodule PokemonBattle.SupervisorBatallas do
  use DynamicSupervisor

  alias PokemonBattle.Batalla

  # =========================
  # START SUPERVISOR
  # =========================
  def start_link(_arg) do
  DynamicSupervisor.start_link(
    __MODULE__,
    :ok,
    name: __MODULE__
  )
end

  # =========================
  # INIT
  # =========================
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # =========================
  # CREAR BATALLA
  # =========================
  def crear_batalla(jugador1, jugador2) do
    spec = %{
      id: {Batalla, :crypto.strong_rand_bytes(4)},
      start: {Batalla, :start_link, [{jugador1, jugador2}]},
      restart: :temporary
    }

   DynamicSupervisor.start_child(
  PokemonBattle.SupervisorBatallas,
  spec
)
  end

  # =========================
  # BATALLAS ACTIVAS
  # =========================
  def batallas_activas do
    DynamicSupervisor.which_children({PokemonBattle.SupervisorBatallas, __MODULE__})
  end
end
