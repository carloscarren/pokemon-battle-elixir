defmodule PokemonBattle.GestorEntrenadores do
  alias PokemonBattle.Persistencia

  def iniciar(usuario, clave) do
    data = Persistencia.cargar()

    case Map.get(data, usuario) do
      nil ->
        nuevo = crear_entrenador(usuario, clave)
        nuevo_data = Map.put(data, usuario, nuevo)
        Persistencia.guardar(nuevo_data)
        {:ok, :registrado, nuevo}

      entrenador ->
        if entrenador["clave"] == clave do
          {:ok, :login, entrenador}
        else
          {:error, "Clave incorrecta"}
        end
    end
  end

  def perfil(usuario) do
    data = Persistencia.cargar()

    case Map.get(data, usuario) do
      nil ->
        IO.puts("Usuario no encontrado")

      entrenador ->
        IO.puts("=== Perfil de #{usuario} ===")
        IO.puts("Monedas: #{entrenador["monedas"]}")
        IO.puts("Sobres pendientes: #{length(entrenador["sobres"])}")
        IO.puts("Pokémon en inventario: #{length(entrenador["inventario"])}")
    end
  end

  def inventario(usuario) do
    data = Persistencia.cargar()

    case Map.get(data, usuario) do
      nil ->
        IO.puts("Usuario no encontrado")

      entrenador ->
        inventario = Map.get(entrenador, "inventario", [])
        pokedex = cargar_json("data/pokemon.json")

        IO.puts("=== Inventario de #{usuario} (#{length(inventario)} Pokémon) ===")

        inventario
        |> Enum.with_index(1)
        |> Enum.each(fn {p, i} ->
          especie = p["especie"]
          base = pokedex[especie]
          tipos = Enum.join(base["tipos"], "/")

          movimientos =
            p["movimientos"]
            |> Enum.map(fn m -> "#{m["nombre"]}(#{m["poder_base"]})" end)
            |> Enum.join(", ")

          IO.puts("  #{i}. [##{p["id"]}] #{String.capitalize(especie)} (#{tipos}) [#{p["rareza"]}]")
          IO.puts("     Ataque: #{p["ataque"]} | Defensa: #{p["defensa"]} | Velocidad: #{p["velocidad"]} | Salud máx: 100")
          IO.puts("     Dueño original: #{p["dueño_original"]}")
          IO.puts("     Movimientos: #{movimientos}")
          IO.puts("")
        end)
    end
  end

  def crear_equipo(usuario, nombre, ids) do
    data = Persistencia.cargar()
    entrenador = data[usuario]
    equipos = entrenador["equipos"]
    inventario = entrenador["inventario"]

    cond do
      Map.has_key?(equipos, nombre) ->
        IO.puts("Ya existe un equipo con ese nombre")

      length(ids) == 0 or length(ids) > 3 ->
        IO.puts("El equipo debe tener entre 1 y 3 Pokémon")

      true ->
        pokemons =
          Enum.map(ids, fn id ->
            Enum.find(inventario, fn p -> p["id"] == id end)
          end)

        if Enum.any?(pokemons, &is_nil/1) do
          IO.puts("Algún Pokémon no existe en el inventario")
        else
          nuevos_equipos = Map.put(equipos, nombre, ids)

          nuevo_entrenador =
            entrenador
            |> Map.put("equipos", nuevos_equipos)

          nuevo_data = Map.put(data, usuario, nuevo_entrenador)
          Persistencia.guardar(nuevo_data)

          IO.puts("Equipo creado correctamente")
        end
    end
  end

  def listar_equipos(usuario) do
    data = Persistencia.cargar()
    entrenador = data[usuario]

    equipos = entrenador["equipos"]
    inventario = entrenador["inventario"]

    IO.puts("Equipos guardados:")

    Enum.each(equipos, fn {nombre, ids} ->
      nombres =
        ids
        |> Enum.map(fn id ->
          p = Enum.find(inventario, fn x -> x["id"] == id end)
          if p, do: "[##{id}] #{String.capitalize(p["especie"])}", else: "[##{id}] ?"
        end)
        |> Enum.join(", ")

      IO.puts("  #{nombre} [#{length(ids)}/3]: #{nombres}")
    end)
  end

  def usar_equipo(usuario, nombre) do
    data = Persistencia.cargar()
    entrenador = data[usuario]
    equipos = entrenador["equipos"]
    inventario = entrenador["inventario"]

    case Map.get(equipos, nombre) do
      nil ->
        IO.puts("Equipo no existe")

      ids ->
        valido =
          Enum.all?(ids, fn id ->
            Enum.any?(inventario, fn p -> p["id"] == id end)
          end)

        if valido do
          nuevo_entrenador = Map.put(entrenador, "equipo_actual", ids)
          nuevo_data = Map.put(data, usuario, nuevo_entrenador)
          Persistencia.guardar(nuevo_data)

          IO.puts("Equipo cargado")
        else
          IO.puts("Faltan Pokémon en el inventario")
        end
    end
  end

  def agregar_pokemon_equipo(usuario, nombre, id) do
    data = Persistencia.cargar()
    entrenador = data[usuario]

    equipos = entrenador["equipos"]
    inventario = entrenador["inventario"]

    case Map.get(equipos, nombre) do
      nil ->
        IO.puts("Equipo no existe")

      ids ->
        cond do
          length(ids) >= 3 ->
            IO.puts("El equipo ya tiene 3 Pokémon")

          Enum.member?(ids, id) ->
            IO.puts("El Pokémon ya está en el equipo")

          true ->
            existe = Enum.any?(inventario, fn p -> p["id"] == id end)

            if existe do
              nuevos_ids = ids ++ [id]
              nuevos_equipos = Map.put(equipos, nombre, nuevos_ids)

              nuevo_entrenador = Map.put(entrenador, "equipos", nuevos_equipos)
              nuevo_data = Map.put(data, usuario, nuevo_entrenador)

              Persistencia.guardar(nuevo_data)
              IO.puts("Pokémon agregado")
            else
              IO.puts("El Pokémon no está en el inventario")
            end
        end
    end
  end

  def quitar_pokemon_equipo(usuario, nombre, id) do
    data = Persistencia.cargar()
    entrenador = data[usuario]

    equipos = entrenador["equipos"]

    case Map.get(equipos, nombre) do
      nil ->
        IO.puts("Equipo no existe")

      ids ->
        cond do
          not Enum.member?(ids, id) ->
            IO.puts("El Pokémon no está en el equipo")

          length(ids) == 1 ->
            IO.puts("No puedes dejar el equipo vacío")

          true ->
            nuevos_ids = Enum.filter(ids, fn x -> x != id end)
            nuevos_equipos = Map.put(equipos, nombre, nuevos_ids)

            nuevo_entrenador = Map.put(entrenador, "equipos", nuevos_equipos)
            nuevo_data = Map.put(data, usuario, nuevo_entrenador)

            Persistencia.guardar(nuevo_data)
            IO.puts("Pokémon eliminado del equipo")
        end
    end
  end

  defp crear_entrenador(usuario, clave) do
    %{
      "usuario" => usuario,
      "clave" => clave,
      "monedas" => 0,
      "monedas_acumuladas" => 0,
      "victorias" => 0,
      "inventario" => [],
      "sobres" => [],
      "equipos" => %{},
      "equipo_actual" => []
    }
  end

  defp cargar_json(ruta) do
    {:ok, contenido} = File.read(ruta)
    Jason.decode!(contenido)
  end
end
