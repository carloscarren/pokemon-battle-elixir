defmodule PokemonBattle.Intercambios do
  alias PokemonBattle.Persistencia

  def intercambiar_pokemon(
        usuario1,
        id_pokemon1,
        usuario2,
        id_pokemon2
      ) do

    data = Persistencia.cargar()

    entrenador1 = data[usuario1]
    entrenador2 = data[usuario2]

    cond do
      entrenador1 == nil ->
        {:error, "Entrenador 1 no existe"}

      entrenador2 == nil ->
        {:error, "Entrenador 2 no existe"}

      true ->
        inventario1 =
          entrenador1["inventario"]

        inventario2 =
          entrenador2["inventario"]

        pokemon1 =
          Enum.find(
            inventario1,
            fn p ->
              p["id"] == id_pokemon1
            end
          )

        pokemon2 =
          Enum.find(
            inventario2,
            fn p ->
              p["id"] == id_pokemon2
            end
          )

        cond do
          pokemon1 == nil ->
            {:error, "Pokémon 1 no encontrado"}

          pokemon2 == nil ->
            {:error, "Pokémon 2 no encontrado"}

          true ->
            nuevo_inv1 =
              inventario1
              |> Enum.reject(fn p ->
                p["id"] == id_pokemon1
              end)
              |> Kernel.++([pokemon2])

            nuevo_inv2 =
              inventario2
              |> Enum.reject(fn p ->
                p["id"] == id_pokemon2
              end)
              |> Kernel.++([pokemon1])

            nuevo_entrenador1 =
              Map.put(
                entrenador1,
                "inventario",
                nuevo_inv1
              )

            nuevo_entrenador2 =
              Map.put(
                entrenador2,
                "inventario",
                nuevo_inv2
              )

            nuevo_data =
              data
              |> Map.put(
                usuario1,
                nuevo_entrenador1
              )
              |> Map.put(
                usuario2,
                nuevo_entrenador2
              )

            Persistencia.guardar(
              nuevo_data
            )

            IO.puts(
              "\n=== INTERCAMBIO REALIZADO ==="
            )

            IO.puts(
              "#{usuario1} entregó #{pokemon1["especie"]}"
            )

            IO.puts(
              "#{usuario2} entregó #{pokemon2["especie"]}"
            )

            IO.puts(
              "Intercambio completado correctamente"
            )

            {:ok,
             %{
               usuario1: usuario1,
               pokemon1: pokemon2["especie"],
               usuario2: usuario2,
               pokemon2: pokemon1["especie"]
             }}
        end
    end
  end
end
