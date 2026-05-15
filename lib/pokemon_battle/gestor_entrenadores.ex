defmodule PokemonBattle.GestorEntrenadores do
  alias PokemonBattle.Persistencia

  # =========================
  # LOGIN / REGISTRO
  # =========================
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

  # =========================
  # MONEDAS
  # =========================
  def agregar_monedas(usuario, cantidad) do
    data = Persistencia.cargar()
    entrenador = Map.get(data, usuario)

    if entrenador do
      actualizado =
        entrenador
        |> Map.update("monedas", cantidad, &(&1 + cantidad))
        |> Map.update("monedas_acumuladas", cantidad, &(&1 + cantidad))

      guardar_entrenador(usuario, actualizado)
      {:ok, actualizado}
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  def descontar_monedas(usuario, cantidad) do
    data = Persistencia.cargar()
    entrenador = Map.get(data, usuario)

    if entrenador do
      monedas = entrenador["monedas"] || 0

      if monedas >= cantidad do
        actualizado =
          Map.put(entrenador, "monedas", monedas - cantidad)

        guardar_entrenador(usuario, actualizado)
        {:ok, actualizado}
      else
        {:error, "Monedas insuficientes"}
      end
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  # =========================
  # VICTORIAS
  # =========================
  def registrar_victoria(usuario) do
    data = Persistencia.cargar()
    entrenador = Map.get(data, usuario)

    if entrenador do
      victorias = entrenador["victorias"] || 0

      actualizado =
        Map.put(entrenador, "victorias", victorias + 1)

      guardar_entrenador(usuario, actualizado)
      {:ok, actualizado}
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  # =========================
  # CONSULTA SEGURA
  # =========================
  def obtener_entrenador(usuario) do
    data = Persistencia.cargar()
    Map.get(data, usuario)
  end

  # =========================
  # EQUIPOS (CORREGIDO)
  # =========================
  def crear_equipo(usuario, nombre, ids) do
    data = Persistencia.cargar()
    entrenador = Map.get(data, usuario)

    if is_nil(entrenador) do
      {:error, "Entrenador no encontrado"}
    else
      inventario = entrenador["inventario"] || []

      equipo =
        Enum.filter(inventario, fn p ->
          p["id"] in ids
        end)

      if length(equipo) != length(ids) do
        {:error, "Algún Pokémon no existe en inventario"}
      else
        equipos = entrenador["equipos"] || %{}

        actualizado =
          Map.put(
            entrenador,
            "equipos",
            Map.put(equipos, nombre, equipo)
          )

        guardar_entrenador(usuario, actualizado)
        {:ok, actualizado}
      end
    end
  end

  def usar_equipo(usuario, nombre) do
    data = Persistencia.cargar()
    entrenador = Map.get(data, usuario)

    if is_nil(entrenador) do
      {:error, "Entrenador no encontrado"}
    else
      equipo = get_in(entrenador, ["equipos", nombre])

      if is_nil(equipo) do
        {:error, "Equipo no existe"}
      else
        actualizado =
          Map.put(entrenador, "equipo_activo", equipo)

        guardar_entrenador(usuario, actualizado)
        {:ok, equipo}
      end
    end
  end
  def listar_equipos(usuario) do
  entrenador =
    obtener_entrenador(usuario)

  equipos =
    entrenador["equipos"] || %{}

  if map_size(equipos) == 0 do
    IO.puts(
      "\nNo tienes equipos guardados"
    )
  else
    IO.puts(
      "\n=== EQUIPOS GUARDADOS ===\n"
    )

    Enum.each(equipos, fn {nombre, pokemons} ->

      lista =
        pokemons
        |> Enum.map(fn p ->
          "[##{p["id"]}] #{p["especie"]}"
        end)
        |> Enum.join(", ")

      IO.puts(
        "#{nombre} " <>
        "[#{length(pokemons)}/3]: " <>
        lista
      )
    end)
  end
end
def agregar_pokemon_equipo(
      usuario,
      nombre_equipo,
      id_pokemon
    ) do

  entrenador =
    obtener_entrenador(usuario)

  equipos =
    entrenador["equipos"] || %{}

  equipo =
    equipos[nombre_equipo]

  cond do

    equipo == nil ->
      {:error, "Equipo no existe"}

    length(equipo) >= 3 ->
      {:error, "El equipo ya tiene 3 Pokémon"}

    true ->

      inventario =
        entrenador["inventario"] || []

      pokemon =
        Enum.find(
          inventario,
          fn p ->
            p["id"] == id_pokemon
          end
        )

      cond do

        pokemon == nil ->
          {:error, "Pokémon no encontrado"}

        Enum.any?(equipo, fn p ->
          p["id"] == id_pokemon
        end) ->
          {:error, "Ese Pokémon ya está en el equipo"}

        true ->

          nuevo_equipo =
            equipo ++ [pokemon]

          nuevos_equipos =
            Map.put(
              equipos,
              nombre_equipo,
              nuevo_equipo
            )

          actualizado =
            Map.put(
              entrenador,
              "equipos",
              nuevos_equipos
            )

          guardar_entrenador(
            usuario,
            actualizado
          )

          {:ok, nuevo_equipo}
      end
  end
end
def quitar_pokemon_equipo(
      usuario,
      nombre_equipo,
      id_pokemon
    ) do

  entrenador =
    obtener_entrenador(usuario)

  equipos =
    entrenador["equipos"] || %{}

  equipo =
    equipos[nombre_equipo]

  cond do

    equipo == nil ->
      {:error, "Equipo no existe"}

    length(equipo) <= 1 ->
      {:error, "No puedes dejar el equipo vacío"}

    true ->

      existe =
        Enum.any?(equipo, fn p ->
          p["id"] == id_pokemon
        end)

      if existe do

        nuevo_equipo =
          Enum.reject(
            equipo,
            fn p ->
              p["id"] == id_pokemon
            end
          )

        nuevos_equipos =
          Map.put(
            equipos,
            nombre_equipo,
            nuevo_equipo
          )

        actualizado =
          Map.put(
            entrenador,
            "equipos",
            nuevos_equipos
          )

        guardar_entrenador(
          usuario,
          actualizado
        )

        {:ok, nuevo_equipo}

      else
        {:error, "Pokémon no está en el equipo"}
      end
  end
end

  # =========================
  # GUARDADO CENTRAL
  # =========================
  def guardar_entrenador(usuario, entrenador) do
    data = Persistencia.cargar()
    nuevo_data = Map.put(data, usuario, entrenador)

    Persistencia.guardar(nuevo_data)
    :ok
  end

  # =========================
  # CREACIÓN DE USUARIO
  # =========================
 defp crear_entrenador(usuario, clave) do
  %{
    "usuario" => usuario,
    "clave" => clave,
    "monedas" => 0,
    "monedas_acumuladas" => 0,
    "victorias" => 0,
    "inventario" => [],

    "sobres" => [
      %{
        "id" => System.unique_integer([:positive]),
        "tipo" => "basico"
      }
    ],

    "equipos" => %{}
  }
end
end
