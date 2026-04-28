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
