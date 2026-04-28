defmodule PokemonBattle.Persistencia do
  @archivo "data/trainers.json"

  def cargar() do
    case File.read(@archivo) do
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
end
