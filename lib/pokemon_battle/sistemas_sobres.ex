defmodule PokemonBattle.SistemaSobres do
  alias PokemonBattle.Persistencia
  alias PokemonBattle.GestorEntrenadores

  @sobres %{
    "basico" => %{
      precio: 100,
      probabilidades: %{
        "comun" => 70,
        "raro" => 25,
        "epico" => 5
      }
    },
    "avanzado" => %{
      precio: 250,
      probabilidades: %{
        "comun" => 40,
        "raro" => 45,
        "epico" => 15
      }
    }
  }

  # =========================
  # TIENDA
  # =========================

  def tienda() do
    IO.puts("\n=== TIENDA DE SOBRES ===\n")

    Enum.each(@sobres, fn {tipo, info} ->
      IO.puts("Sobre: #{tipo}")
      IO.puts("Precio: #{info.precio}")

      probs = info.probabilidades

      IO.puts(
        "Probabilidades -> " <>
        "Común: #{probs["comun"]}% | " <>
        "Raro: #{probs["raro"]}% | " <>
        "Épico: #{probs["epico"]}%"
      )

      IO.puts("")
    end)
  end

  # =========================
  # COMPRAR SOBRE
  # =========================

  def comprar_sobre(usuario, tipo) do
    sobre = @sobres[tipo]

    cond do
      sobre == nil ->
        {:error, "Tipo de sobre inválido"}

      true ->
        precio = sobre.precio

        case GestorEntrenadores.descontar_monedas(
               usuario,
               precio
             ) do
          {:error, motivo} ->
            {:error, motivo}

          {:ok, _} ->
            data = Persistencia.cargar()

            entrenador = data[usuario]

            sobres_actuales =
              entrenador["sobres"] || []

            nuevo_sobre = %{
              "id" => generar_id_unico(),
              "tipo" => tipo
            }

            nuevos_sobres =
              sobres_actuales ++ [nuevo_sobre]

            actualizado =
              Map.put(
                entrenador,
                "sobres",
                nuevos_sobres
              )

            nuevo_data =
              Map.put(
                data,
                usuario,
                actualizado
              )

            Persistencia.guardar(nuevo_data)

            IO.puts(
              "Sobre comprado correctamente"
            )

            IO.puts(
              "ID del sobre: #{nuevo_sobre["id"]}"
            )

            {:ok, nuevo_sobre}
        end
    end
  end

  # =========================
  # ABRIR SOBRE
  # =========================

  def abrir_sobre(usuario, "ultimo") do
    data = Persistencia.cargar()

    entrenador = data[usuario]

    sobres =
      entrenador["sobres"] || []

    if length(sobres) == 0 do
      {:error, "No tienes sobres"}
    else
      ultimo = List.last(sobres)

      abrir_sobre(
        usuario,
        ultimo["id"]
      )
    end
  end

  def abrir_sobre(usuario, id_sobre) do
    data = Persistencia.cargar()

    entrenador = data[usuario]

    sobres =
      entrenador["sobres"] || []

    sobre =
      Enum.find(
        sobres,
        fn s ->
          s["id"] == id_sobre
        end
      )

    if sobre == nil do
      {:error, "Sobre no encontrado"}
    else
      pokedex =
        cargar_json("data/pokemon.json")

      moves =
        cargar_json("data/moves.json")

      pokemons =
        for _ <- 1..3 do
          crear_pokemon(
            usuario,
            sobre["tipo"],
            pokedex,
            moves
          )
        end

      inventario =
        entrenador["inventario"] ++
          pokemons

      sobres_restantes =
        Enum.reject(
          sobres,
          fn s ->
            s["id"] == id_sobre
          end
        )

      actualizado =
        entrenador
        |> Map.put(
          "inventario",
          inventario
        )
        |> Map.put(
          "sobres",
          sobres_restantes
        )

      nuevo_data =
        Map.put(
          data,
          usuario,
          actualizado
        )

      Persistencia.guardar(nuevo_data)

      mostrar_pokemons(pokemons)

      {:ok, pokemons}
    end
  end

  # =========================
  # CREACIÓN POKÉMON
  # =========================

  defp crear_pokemon(
         usuario,
         tipo_sobre,
         pokedex,
         moves
       ) do

    especie =
      pokedex
      |> Map.keys()
      |> Enum.random()

    base =
      pokedex[especie]

    rareza =
      generar_rareza(tipo_sobre)

    factor =
      generar_factor(rareza)

    stats =
      calcular_stats(base, factor)

    movimientos =
      asignar_movimientos(
        base["tipos"],
        moves
      )

    %{
      "id" => generar_id_unico(),
      "especie" => especie,
      "rareza" => rareza,
      "ataque" => stats.ataque,
      "defensa" => stats.defensa,
      "velocidad" => stats.velocidad,
      "movimientos" => movimientos,
      "dueño_original" => usuario
    }
  end

  # =========================
  # RAREZA
  # =========================

  defp generar_rareza("basico") do
    r = :rand.uniform(100)

    cond do
      r <= 70 -> "comun"
      r <= 95 -> "raro"
      true -> "epico"
    end
  end

  defp generar_rareza("avanzado") do
    r = :rand.uniform(100)

    cond do
      r <= 40 -> "comun"
      r <= 85 -> "raro"
      true -> "epico"
    end
  end

  # =========================
  # FACTORES
  # =========================

  defp generar_factor("comun") do
    Enum.random(2..8)
  end

  defp generar_factor("raro") do
    Enum.random(10..20)
  end

  defp generar_factor("epico") do
    Enum.random(25..40)
  end

  # =========================
  # STATS
  # =========================

  defp calcular_stats(base, factor) do
    %{
      ataque:
        round(
          base["ataque_base"] *
          (1 + factor / 100)
        ),

      defensa:
        round(
          base["defensa_base"] *
          (1 + factor / 100)
        ),

      velocidad:
        round(
          base["velocidad_base"] *
          (1 + factor / 100)
        )
    }
  end

  # =========================
  # MOVIMIENTOS
  # =========================

  defp asignar_movimientos(
         tipos,
         moves
       ) do

    movimientos_tipo =
      tipos
      |> Enum.flat_map(fn tipo ->
        moves[tipo] || []
      end)

    movimientos_globales =
      moves
      |> Map.values()
      |> List.flatten()

    (
      Enum.take_random(
        movimientos_tipo,
        2
      ) ++
      Enum.take_random(
        movimientos_globales,
        2
      )
    )
    |> Enum.uniq_by(
      & &1["nombre"]
    )
    |> Enum.take(4)
  end

  # =========================
  # MOSTRAR POKÉMON
  # =========================

  defp mostrar_pokemons(pokemons) do
    pokedex =
      cargar_json("data/pokemon.json")

    IO.puts(
      "\n¡Sobre abierto! Obtuviste:\n"
    )

    Enum.with_index(
      pokemons,
      1
    )
    |> Enum.each(fn {p, i} ->

      tipos =
        pokedex[p["especie"]]["tipos"]
        |> Enum.join("/")

      movimientos =
        p["movimientos"]
        |> Enum.map(fn m ->
          "#{m["nombre"]} (#{m["poder_base"]})"
        end)
        |> Enum.join(", ")

      IO.puts(
        "  #{i}. [##{p["id"]}] " <>
        "#{p["especie"]} " <>
        "(#{tipos}) " <>
        "[#{p["rareza"]}] " <>
        "- Dueño original: " <>
        "#{p["dueño_original"]}"
      )

      IO.puts(
        "     Movimientos: #{movimientos}\n"
      )
    end)
  end

  # =========================
  # UTILIDADES
  # =========================

  defp cargar_json(ruta) do
    {:ok, contenido} =
      File.read(ruta)

    Jason.decode!(contenido)
  end

  defp generar_id_unico() do
    :rand.uniform(99999)
  end
end
