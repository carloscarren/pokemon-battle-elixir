defmodule PokemonBattle.Persistencia do
  @archivo "data/trainers.json"
  @archivo_pokemon "data/pokemon.json"

  def cargar() do
  case File.read(@archivo) do
    {:ok, ""} ->
      %{}

    {:ok, contenido} ->
      Jason.decode!(contenido)

    _ ->
      %{}
  end
end

  def guardar(data) do
    File.mkdir_p!("data")
    File.write!(@archivo, Jason.encode!(data, pretty: true))
  end

  def cargar_pokedex() do
    case File.read(@archivo_pokemon) do
      {:ok, contenido} ->
        Jason.decode!(contenido)

      _ ->
        %{}
    end
  end

  def obtener_tipos(especie) do
    pokedex = cargar_pokedex()

    case pokedex[especie] do
      nil -> []
      datos -> datos["tipos"]
    end
  end
end
