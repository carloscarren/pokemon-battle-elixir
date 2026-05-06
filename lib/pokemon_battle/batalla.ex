defmodule PokemonBattle.Batalla do
  use GenServer

  alias PokemonBattle.Persistencia
  alias PokemonBattle.MotorCombate

  def start_link({jugador1, jugador2}) do
    GenServer.start_link(__MODULE__, {jugador1, jugador2})
  end

  def init({j1, j2}) do
    data = Persistencia.cargar()

    with %{"inventario" => inv1} <- data[j1],
         %{"inventario" => inv2} <- data[j2],
         true <- length(inv1) >= 3,
         true <- length(inv2) >= 3 do

      equipo1 = Enum.take(inv1, 3) |> Enum.map(&Map.put(&1, "hp", 100))
      equipo2 = Enum.take(inv2, 3) |> Enum.map(&Map.put(&1, "hp", 100))

      estado = %{
        jugador1: j1,
        jugador2: j2,
        equipo1: equipo1,
        equipo2: equipo2,
        idx1: 0,
        idx2: 0,
        turno: 1,
        acciones: %{}
      }

      IO.puts("Batalla iniciada entre #{j1} y #{j2}")
      {:ok, estado}
    else
      _ ->
        IO.puts("Error: ambos jugadores deben tener al menos 3 Pokémon")
        {:stop, :error}
    end
  end

  def enviar_accion(pid, jugador, accion) do
    GenServer.cast(pid, {:accion, jugador, accion})
  end

  def handle_cast({:accion, jugador, accion}, estado) do
    acciones = Map.put(estado.acciones, jugador, accion)
    estado = %{estado | acciones: acciones}

    if map_size(acciones) == 2 do
      resolver_turno(estado)
    else
      {:noreply, estado}
    end
  end

  defp seleccionar_movimiento(pokemon, accion) do
    index =
      case accion do
        "mov1" -> 0
        "mov2" -> 1
        "mov3" -> 2
        "mov4" -> 3
        _ -> 0
      end

    Enum.at(pokemon["movimientos"], index) ||
      Enum.at(pokemon["movimientos"], 0)
  end

  defp resolver_turno(estado) do
    IO.puts("Resolviendo turno #{estado.turno}")

    j1 = estado.jugador1
    j2 = estado.jugador2

    p1 = Enum.at(estado.equipo1, estado.idx1)
    p2 = Enum.at(estado.equipo2, estado.idx2)

    tipos1 = Persistencia.obtener_tipos(p1["especie"])
    tipos2 = Persistencia.obtener_tipos(p2["especie"])

    p1 = Map.put(p1, "tipos", tipos1)
    p2 = Map.put(p2, "tipos", tipos2)

    mov1 = seleccionar_movimiento(p1, estado.acciones[j1])
    mov2 = seleccionar_movimiento(p2, estado.acciones[j2])

    {primero, segundo} =
      if p1["velocidad"] >= p2["velocidad"] do
        {{j1, p1, mov1, :p1}, {j2, p2, mov2, :p2}}
      else
        {{j2, p2, mov2, :p2}, {j1, p1, mov1, :p1}}
      end

    atacar(estado, primero, segundo)
  end

  defp atacar(estado, {jA, pA, movA, tagA}, {jB, pB, movB, tagB}) do
    res = MotorCombate.calcular_danio(pA, pB, movA)
    hpB = max(pB["hp"] - res.dano, 0)

    nombreA = movA["nombre"]
    IO.puts("#{jA} usa #{nombreA} y hace #{res.dano} daño")

    if hpB <= 0 do
      IO.puts("#{jB} ha sido derrotado")

      estado
      |> actualizar_pokemon(tagB, Map.put(pB, "hp", 0))
      |> cambiar_pokemon(tagB)
      |> verificar_fin_o_continuar()

    else
      pB = Map.put(pB, "hp", hpB)

      res2 = MotorCombate.calcular_danio(pB, pA, movB)
      hpA = max(pA["hp"] - res2.dano, 0)

      nombreB = movB["nombre"]
      IO.puts("#{jB} usa #{nombreB} y hace #{res2.dano} daño")

      IO.puts("HP #{estado.jugador1}: #{hpA} | HP #{estado.jugador2}: #{hpB}")

      estado
      |> actualizar_pokemon(tagA, Map.put(pA, "hp", hpA))
      |> actualizar_pokemon(tagB, pB)
      |> avanzar_turno()
    end
  end

  defp actualizar_pokemon(estado, :p1, poke) do
    equipo = List.replace_at(estado.equipo1, estado.idx1, poke)
    %{estado | equipo1: equipo}
  end

  defp actualizar_pokemon(estado, :p2, poke) do
    equipo = List.replace_at(estado.equipo2, estado.idx2, poke)
    %{estado | equipo2: equipo}
  end

  defp cambiar_pokemon(estado, :p1) do
    if estado.idx1 < 2 do
      IO.puts("#{estado.jugador1} envía nuevo Pokémon")
      %{estado | idx1: estado.idx1 + 1}
    else
      estado
    end
  end

  defp cambiar_pokemon(estado, :p2) do
    if estado.idx2 < 2 do
      IO.puts("#{estado.jugador2} envía nuevo Pokémon")
      %{estado | idx2: estado.idx2 + 1}
    else
      estado
    end
  end

  defp verificar_fin_o_continuar(estado) do
    cond do
      estado.idx1 >= 2 and Enum.at(estado.equipo1, 2)["hp"] <= 0 ->
        IO.puts("Gana #{estado.jugador2}")
        {:stop, :normal, estado}

      estado.idx2 >= 2 and Enum.at(estado.equipo2, 2)["hp"] <= 0 ->
        IO.puts("Gana #{estado.jugador1}")
        {:stop, :normal, estado}

      true ->
        avanzar_turno(estado)
    end
  end

  defp avanzar_turno(estado) do
    {:noreply, %{estado | turno: estado.turno + 1, acciones: %{}}}
  end
end
