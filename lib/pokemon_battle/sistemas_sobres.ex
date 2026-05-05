defmodule PokemonBattle.SistemaSobres do
  alias PokemonBattle.Persistencia

  def abrir_sobre(usuario, tipo) do
    pokedex = cargar_json("data/pokemon.json")
    moves = cargar_json("data/moves.json")

    pokemons =
      for _ <- 1..3 do
        crear_pokemon(usuario, tipo, pokedex, moves)
      end

    Enum.each(pokemons, fn p ->
      guardar_pokemon(usuario, p)
    end)

    IO.puts("¡Sobre abierto!")
    Enum.each(pokemons, &IO.inspect/1)
  end

  defp crear_pokemon(usuario, tipo_sobre, pokedex, moves) do
    especie = pokedex |> Map.keys() |> Enum.random()
    base = pokedex[especie]

    rareza = generar_rareza(tipo_sobre)
    factor = generar_factor(rareza)
    stats = calcular_stats(base, factor)

    movimientos = asignar_movimientos(base["tipos"], moves)

    %{
      "id" => :rand.uniform(100000),
      "especie" => especie,
      "rareza" => rareza,
      "ataque" => stats.ataque,
      "defensa" => stats.defensa,
      "velocidad" => stats.velocidad,
      "movimientos" => movimientos,
      "dueño_original" => usuario
    }
  end

  defp cargar_json(ruta) do
    {:ok, contenido} = File.read(ruta)
    Jason.decode!(contenido)
  end

  defp generar_rareza("basico") do
    r = :rand.uniform()

    cond do
      r < 0.7 -> "comun"
      r < 0.95 -> "raro"
      true -> "epico"
    end
  end

  defp generar_rareza("avanzado") do
    r = :rand.uniform()

    cond do
      r < 0.4 -> "comun"
      r < 0.85 -> "raro"
      true -> "epico"
    end
  end

  defp generar_factor("comun"), do: Enum.random(2..8)
  defp generar_factor("raro"), do: Enum.random(10..20)
  defp generar_factor("epico"), do: Enum.random(25..40)

  defp calcular_stats(base, factor) do
    %{
      ataque: round(base["ataque_base"] * (1 + factor / 100)),
      defensa: round(base["defensa_base"] * (1 + factor / 100)),
      velocidad: round(base["velocidad_base"] * (1 + factor / 100))
    }
  end

  defp asignar_movimientos(tipos, moves) do
    movimientos_tipo =
      tipos
      |> Enum.flat_map(fn tipo -> moves[tipo] || [] end)

    movimientos_random =
      moves
      |> Map.values()
      |> List.flatten()

    (Enum.take_random(movimientos_tipo, 2) ++
     Enum.take_random(movimientos_random, 2))
    |> Enum.uniq_by(& &1["nombre"])
    |> Enum.take(4)
  end

  defp guardar_pokemon(usuario, pokemon) do
    data = Persistencia.cargar()

    entrenador = data[usuario] || %{"inventario" => []}
    inventario = entrenador["inventario"] ++ [pokemon]

    nuevo = Map.put(entrenador, "inventario", inventario)
    nuevo_data = Map.put(data, usuario, nuevo)

    Persistencia.guardar(nuevo_data)
  end
end
