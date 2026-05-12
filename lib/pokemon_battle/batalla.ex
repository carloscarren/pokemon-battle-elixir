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
        p1 =
          equipo1
          |> Enum.at(0)
          |> Map.put("hp", 100)

        p2 =
          equipo2
          |> Enum.at(0)
          |> Map.put("hp", 100)

        estado = %{
          jugador1: j1,
          jugador2: j2,
          pokemon1: p1,
          pokemon2: p2,
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

    p1 = estado.pokemon1
    p2 = estado.pokemon2

    tipos1 = Persistencia.obtener_tipos(p1["especie"])
    tipos2 = Persistencia.obtener_tipos(p2["especie"])

    p1 = Map.put(p1, "tipos", tipos1)
    p2 = Map.put(p2, "tipos", tipos2)

    mov1 = Enum.random(p1["movimientos"])
    mov2 = Enum.random(p2["movimientos"])

    if p1["velocidad"] >= p2["velocidad"] do
      ejecutar_turno(estado, j1, p1, mov1, j2, p2, mov2)
    else
      ejecutar_turno(estado, j2, p2, mov2, j1, p1, mov1)
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
      verificar_fin(%{estado | pokemon1: pA, pokemon2: pB})
    else
      res2 = MotorCombate.calcular_danio(pB, pA, movB)

      hpA = max(pA["hp"] - res2.dano, 0)

      IO.puts("#{jB} usa #{movB["nombre"]} y hace #{res2.dano} daño")

      pA = Map.put(pA, "hp", hpA)

      IO.puts("HP #{jA}: #{hpA} | HP #{jB}: #{hpB}")

      verificar_fin(%{estado | pokemon1: pA, pokemon2: pB})
    end
  end

  # =========================
  # FIN DE BATALLA
  # =========================
  defp verificar_fin(estado) do
    cond do
      estado.pokemon1["hp"] <= 0 ->
        IO.puts("Gana #{estado.jugador2}")

        GestorEntrenadores.agregar_monedas(estado.jugador2, 100)
        GestorEntrenadores.registrar_victoria(estado.jugador2)

        GestorEntrenadores.agregar_monedas(estado.jugador1, 30)

        {:stop, :normal, estado}

      estado.pokemon2["hp"] <= 0 ->
        IO.puts("Gana #{estado.jugador1}")

        GestorEntrenadores.agregar_monedas(estado.jugador1, 100)
        GestorEntrenadores.registrar_victoria(estado.jugador1)

        GestorEntrenadores.agregar_monedas(estado.jugador2, 30)

        {:stop, :normal, estado}

      true ->
        {:noreply, %{estado | turno: estado.turno + 1, acciones: %{}}}
    end
  end
end
