defmodule PokemonBattle.Batalla do
  use GenServer

  alias PokemonBattle.Persistencia
  alias PokemonBattle.MotorCombate
  alias PokemonBattle.GestorEntrenadores

  def start_link({jugador1, jugador2}) do
    GenServer.start_link(
      __MODULE__,
      {jugador1, jugador2}
    )
  end

  def init({j1, j2}) do
    data = Persistencia.cargar()

    entrenador1 = data[j1]
    entrenador2 = data[j2]

    inv1 =
      if entrenador1,
        do: entrenador1["inventario"],
        else: []

    inv2 =
      if entrenador2,
        do: entrenador2["inventario"],
        else: []

    cond do
      length(inv1) < 3 ->
        IO.puts(
          "Error: #{j1} no tiene suficientes Pokémon"
        )

        {:stop, :error}

      length(inv2) < 3 ->
        IO.puts(
          "Error: #{j2} no tiene suficientes Pokémon"
        )

        {:stop, :error}

      true ->
        p1 =
          inv1
          |> Enum.at(0)
          |> Map.put("hp", 100)

        p2 =
          inv2
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

        IO.puts(
          "Batalla iniciada entre #{j1} y #{j2}"
        )

        {:ok, estado}
    end
  end

  def enviar_accion(pid, jugador, accion) do
    GenServer.cast(
      pid,
      {:accion, jugador, accion}
    )
  end

  def handle_cast(
        {:accion, jugador, accion},
        estado
      ) do
    nuevas_acciones =
      Map.put(
        estado.acciones,
        jugador,
        accion
      )

    estado = %{
      estado
      | acciones: nuevas_acciones
    }

    if map_size(nuevas_acciones) == 2 do
      resolver_turno(estado)
    else
      {:noreply, estado}
    end
  end

  defp resolver_turno(estado) do
    IO.puts(
      "Resolviendo turno #{estado.turno}"
    )

    j1 = estado.jugador1
    j2 = estado.jugador2

    p1 = estado.pokemon1
    p2 = estado.pokemon2

    tipos1 =
      Persistencia.obtener_tipos(
        p1["especie"]
      )

    tipos2 =
      Persistencia.obtener_tipos(
        p2["especie"]
      )

    p1 =
      Map.put(
        p1,
        "tipos",
        tipos1
      )

    p2 =
      Map.put(
        p2,
        "tipos",
        tipos2
      )

    mov1 =
      Enum.random(
        p1["movimientos"]
      )

    mov2 =
      Enum.random(
        p2["movimientos"]
      )

    vel1 = p1["velocidad"]
    vel2 = p2["velocidad"]

    if vel1 >= vel2 do
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

  defp ejecutar_turno(
         estado,
         jA,
         pA,
         movA,
         jB,
         pB,
         movB
       ) do
    res1 =
      MotorCombate.calcular_danio(
        pA,
        pB,
        movA
      )

    hpB =
      max(
        pB["hp"] - res1.dano,
        0
      )

    IO.puts(
      "#{jA} usa #{movA["nombre"]} y hace #{res1.dano} daño"
    )

    pB =
      Map.put(
        pB,
        "hp",
        hpB
      )

    if hpB <= 0 do
      IO.puts(
        "#{jB} ha sido derrotado"
      )

      nuevo_estado =
        actualizar_estado(
          estado,
          jA,
          pA,
          jB,
          pB
        )

      verificar_fin(nuevo_estado)
    else
      res2 =
        MotorCombate.calcular_danio(
          pB,
          pA,
          movB
        )

      hpA =
        max(
          pA["hp"] - res2.dano,
          0
        )

      IO.puts(
        "#{jB} usa #{movB["nombre"]} y hace #{res2.dano} daño"
      )

      pA =
        Map.put(
          pA,
          "hp",
          hpA
        )

      IO.puts(
        "HP #{jA}: #{hpA} | HP #{jB}: #{hpB}"
      )

      nuevo_estado =
        actualizar_estado(
          estado,
          jA,
          pA,
          jB,
          pB
        )

      verificar_fin(nuevo_estado)
    end
  end

  defp actualizar_estado(
         estado,
         j1,
         p1,
         j2,
         p2
       ) do
    cond do
      estado.jugador1 == j1 ->
        %{
          estado
          | turno: estado.turno + 1,
            acciones: %{},
            pokemon1: p1,
            pokemon2: p2
        }

      true ->
        %{
          estado
          | turno: estado.turno + 1,
            acciones: %{},
            pokemon1: p2,
            pokemon2: p1
        }
    end
  end

  defp verificar_fin(estado) do
    cond do
      estado.pokemon1["hp"] <= 0 ->
        IO.puts(
          "Gana #{estado.jugador2}"
        )

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

        IO.puts(
          "#{estado.jugador2} recibe 100 monedas"
        )

        IO.puts(
          "#{estado.jugador1} recibe 30 monedas por participación"
        )

        {:stop, :normal, estado}

      estado.pokemon2["hp"] <= 0 ->
        IO.puts(
          "Gana #{estado.jugador1}"
        )

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

        IO.puts(
          "#{estado.jugador1} recibe 100 monedas"
        )

        IO.puts(
          "#{estado.jugador2} recibe 30 monedas por participación"
        )

        {:stop, :normal, estado}

      true ->
        {:noreply, estado}
    end
  end
end
