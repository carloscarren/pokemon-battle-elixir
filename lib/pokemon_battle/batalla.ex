defmodule PokemonBattle.Batalla do
  use GenServer

  alias PokemonBattle.Persistencia
  alias PokemonBattle.MotorCombate
  alias PokemonBattle.GestorEntrenadores

  # =========================
  # START
  # =========================
  def start_link({jugador1, jugador2}) do
    GenServer.start_link(
      __MODULE__,
      {jugador1, jugador2}
    )
  end

  # =========================
  # INIT
  # =========================
  def init({j1, j2}) do
    data = Persistencia.cargar()

    entrenador1 = data[j1]
    entrenador2 = data[j2]

    equipo1 = (entrenador1 && entrenador1["equipo_activo"]) || []
    equipo2 = (entrenador2 && entrenador2["equipo_activo"]) || []

    cond do
      equipo1 == [] ->
        IO.puts("#{j1} no tiene equipo activo")
        {:stop, :no_equipo}

      equipo2 == [] ->
        IO.puts("#{j2} no tiene equipo activo")
        {:stop, :no_equipo}

      true ->
equipo1_hp =
  Enum.map(equipo1, fn p ->
    Map.put(p, "hp", 100)
  end)

equipo2_hp =
  Enum.map(equipo2, fn p ->
    Map.put(p, "hp", 100)
  end)

estado = %{
  jugador1: j1,
  jugador2: j2,

  equipo1: equipo1_hp,
  equipo2: equipo2_hp,

  activo1: 0,
  activo2: 0,

  turno: 1,
  acciones: %{}
}

        IO.puts("Batalla iniciada entre #{j1} y #{j2}")

        {:ok, estado}
    end
  end

  # =========================
  # ACCIONES
  # =========================
  def enviar_accion(pid, jugador, accion) do
    GenServer.cast(pid, {:accion, jugador, accion})
  end

  def handle_cast({:accion, jugador, accion}, estado) do
    nuevas =
      Map.put(estado.acciones, jugador, accion)

    estado = %{estado | acciones: nuevas}

    if map_size(nuevas) == 2 do
      resolver_turno(estado)
    else
      {:noreply, estado}
    end
  end

  # =========================
  # TURNOS
  # =========================
defp resolver_turno(estado) do
  j1 = estado.jugador1
  j2 = estado.jugador2

  equipo1 = estado.equipo1
  equipo2 = estado.equipo2

  activo1 = estado.activo1
  activo2 = estado.activo2

  p1 = Enum.at(equipo1, activo1)
  p2 = Enum.at(equipo2, activo2)

  tipos1 =
    Persistencia.obtener_tipos(
      p1["especie"]
    )

  tipos2 =
    Persistencia.obtener_tipos(
      p2["especie"]
    )

  p1 = Map.put(p1, "tipos", tipos1)
  p2 = Map.put(p2, "tipos", tipos2)

  nombre_mov1 =
    estado.acciones[j1]

  nombre_mov2 =
    estado.acciones[j2]

  mov1 =
    Enum.find(
      p1["movimientos"],
      fn m ->
        m["nombre"] == nombre_mov1
      end
    )

  mov2 =
    Enum.find(
      p2["movimientos"],
      fn m ->
        m["nombre"] == nombre_mov2
      end
    )

  if p1["velocidad"] >= p2["velocidad"] do
    ejecutar_turno(
      estado,
      j1,
      p1,
      mov1,
      j2,
      p2,
      mov2
    )
  else
    ejecutar_turno(
      estado,
      j2,
      p2,
      mov2,
      j1,
      p1,
      mov1
    )
  end
end

  # =========================
  # EJECUCIÓN TURNO
  # =========================
  defp ejecutar_turno(estado, jA, pA, movA, jB, pB, movB) do
    res1 = MotorCombate.calcular_danio(pA, pB, movA)

    hpB = max(pB["hp"] - res1.dano, 0)

    IO.puts("#{jA} usa #{movA["nombre"]} y hace #{res1.dano} daño")

    pB = Map.put(pB, "hp", hpB)

    if hpB <= 0 do
      IO.puts("#{jB} ha sido derrotado")
      nuevo_estado =
  actualizar_pokemones(
    estado,
    pA,
    pB
  )

verificar_fin(nuevo_estado)
    else
      res2 = MotorCombate.calcular_danio(pB, pA, movB)

      hpA = max(pA["hp"] - res2.dano, 0)

      IO.puts("#{jB} usa #{movB["nombre"]} y hace #{res2.dano} daño")

      pA = Map.put(pA, "hp", hpA)

      IO.puts("HP #{jA}: #{hpA} | HP #{jB}: #{hpB}")

      nuevo_estado =
  actualizar_pokemones(
    estado,
    pA,
    pB
  )

verificar_fin(nuevo_estado)
    end
  end

# =========================
# FIN DE BATALLA
# =========================
defp verificar_fin(estado) do
  vivos1 =
    Enum.any?(
      estado.equipo1,
      fn p -> p["hp"] > 0 end
    )

  vivos2 =
    Enum.any?(
      estado.equipo2,
      fn p -> p["hp"] > 0 end
    )

  cond do

    # =====================
    # GANA JUGADOR 2
    # =====================
    !vivos1 ->
      IO.puts("Gana #{estado.jugador2}")

      GestorEntrenadores.agregar_monedas(
        estado.jugador2,
        100
      )

      GestorEntrenadores.registrar_victoria(
        estado.jugador2
      )

      GestorEntrenadores.agregar_monedas(
        estado.jugador1,
        30
      )

      {:stop, :normal, estado}

    # =====================
    # GANA JUGADOR 1
    # =====================
    !vivos2 ->
      IO.puts("Gana #{estado.jugador1}")

      GestorEntrenadores.agregar_monedas(
        estado.jugador1,
        100
      )

      GestorEntrenadores.registrar_victoria(
        estado.jugador1
      )

      GestorEntrenadores.agregar_monedas(
        estado.jugador2,
        30
      )

      {:stop, :normal, estado}

    true ->

      estado =
        cambiar_si_debilitado(estado)

      {:noreply,
       %{
         estado
         | turno: estado.turno + 1,
           acciones: %{}
       }}
  end
end
  # =========================
# BUSCAR MOVIMIENTO
# =========================
defp buscar_movimiento(
       pokemon,
       nombre_movimiento
     ) do

  Enum.find(
    pokemon["movimientos"],
    fn mov ->
      mov["nombre"] == nombre_movimiento
    end
  )
end
# =========================
# ACTUALIZAR POKÉMONES
# =========================
defp actualizar_pokemones(
       estado,
       p1,
       p2
     ) do

  equipo1 =
    List.replace_at(
      estado.equipo1,
      estado.activo1,
      p1
    )

  equipo2 =
    List.replace_at(
      estado.equipo2,
      estado.activo2,
      p2
    )

  %{
    estado
    | equipo1: equipo1,
      equipo2: equipo2
  }
  end
  # =========================
# CAMBIAR SI DEBILITADO
# =========================
defp cambiar_si_debilitado(estado) do

  activo1 =
    obtener_siguiente_vivo(
      estado.equipo1,
      estado.activo1
    )

  activo2 =
    obtener_siguiente_vivo(
      estado.equipo2,
      estado.activo2
    )

  %{
    estado
    | activo1: activo1,
      activo2: activo2
  }
end
# =========================
# BUSCAR SIGUIENTE VIVO
# =========================
defp obtener_siguiente_vivo(
       equipo,
       actual
     ) do

  pokemon_actual =
    Enum.at(equipo, actual)

  if pokemon_actual["hp"] > 0 do
    actual
  else
    equipo
    |> Enum.with_index()
    |> Enum.find(
      fn {p, _i} ->
        p["hp"] > 0
      end
    )
    |> case do
      nil -> actual
      {_p, i} -> i
    end
  end
end
end
