defmodule PokemonBattle.Servidor do
  alias PokemonBattle.GestorEntrenadores

  def iniciar() do
    IO.puts("Bienvenido a Pokémon Battle")

    loop(nil)
  end

  defp loop(usuario_actual) do
    comando = IO.gets("> ") |> String.trim()

    case String.split(comando) do
      ["iniciar", usuario, clave] ->
        case GestorEntrenadores.iniciar(usuario, clave) do
          {:ok, tipo, _} ->
            IO.puts("Sesión iniciada (#{tipo})")
            loop(usuario)

          {:error, msg} ->
            IO.puts(msg)
            loop(nil)
        end

      ["salir"] ->
        IO.puts("Sesión cerrada")
        loop(nil)

      _ ->
        IO.puts("Comando no reconocido")
        loop(usuario_actual)
    end
  end
end
