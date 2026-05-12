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
      "sobres" => [],
      "equipos" => %{},
      "equipo_activo" => nil
    }
  end
end
