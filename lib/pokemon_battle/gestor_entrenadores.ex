defmodule PokemonBattle.GestorEntrenadores do
  alias PokemonBattle.Persistencia

  def iniciar(usuario, clave) do
    data = Persistencia.cargar()

    case Map.get(data, usuario) do
      nil ->
        nuevo = crear_entrenador(usuario, clave)

        nuevo_data =
          Map.put(data, usuario, nuevo)

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

  def agregar_monedas(usuario, cantidad) do
    data = Persistencia.cargar()

    entrenador = Map.get(data, usuario)

    if entrenador do
      monedas_actuales =
        entrenador["monedas"] || 0

      acumuladas =
        entrenador["monedas_acumuladas"] || 0

      actualizado =
        entrenador
        |> Map.put(
          "monedas",
          monedas_actuales + cantidad
        )
        |> Map.put(
          "monedas_acumuladas",
          acumuladas + cantidad
        )

      nuevo_data =
        Map.put(data, usuario, actualizado)

      Persistencia.guardar(nuevo_data)

      {:ok, actualizado}
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  def descontar_monedas(usuario, cantidad) do
    data = Persistencia.cargar()

    entrenador = Map.get(data, usuario)

    if entrenador do
      monedas =
        entrenador["monedas"] || 0

      if monedas >= cantidad do
        actualizado =
          Map.put(
            entrenador,
            "monedas",
            monedas - cantidad
          )

        nuevo_data =
          Map.put(data, usuario, actualizado)

        Persistencia.guardar(nuevo_data)

        {:ok, actualizado}
      else
        {:error, "Monedas insuficientes"}
      end
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  def registrar_victoria(usuario) do
    data = Persistencia.cargar()

    entrenador = Map.get(data, usuario)

    if entrenador do
      victorias =
        entrenador["victorias"] || 0

      actualizado =
        Map.put(
          entrenador,
          "victorias",
          victorias + 1
        )

      nuevo_data =
        Map.put(data, usuario, actualizado)

      Persistencia.guardar(nuevo_data)

      {:ok, actualizado}
    else
      {:error, "Entrenador no encontrado"}
    end
  end

  def obtener_entrenador(usuario) do
    data = Persistencia.cargar()

    Map.get(data, usuario)
  end

  def guardar_entrenador(usuario, entrenador) do
    data = Persistencia.cargar()

    nuevo_data =
      Map.put(data, usuario, entrenador)

    Persistencia.guardar(nuevo_data)

    :ok
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
      "equipos" => %{}
    }
  end
end
