defmodule PokemonBattle.MotorCombate do
  @efectividades %{
    "Fuego" => ["Planta", "Hielo", "Bicho"],
    "Agua" => ["Fuego", "Roca", "Tierra"],
    "Planta" => ["Agua", "Roca", "Tierra"],
    "Electrico" => ["Agua", "Volador"],
    "Roca" => ["Fuego", "Hielo", "Volador", "Bicho"]
  }

  def calcular_danio(atacante, defensor, movimiento) do
    ataque = atacante["ataque"]
    defensa = defensor["defensa"]
    poder = movimiento["poder_base"]

    dano_base =
      trunc((poder * (ataque / defensa)) / 5 + 2)

    stab = calcular_stab(atacante, movimiento)
    efectividad = calcular_efectividad(movimiento, defensor)
    factor = :rand.uniform() * (1.0 - 0.85) + 0.85

    dano_final =
      trunc(dano_base * stab * efectividad * factor)
      |> max(1)

    %{
      dano: dano_final,
      stab: stab,
      efectividad: efectividad
    }
  end

  defp calcular_stab(atacante, movimiento) do
    tipos = atacante["tipos"] || []

    if movimiento["tipo"] in tipos do
      1.5
    else
      1.0
    end
  end

  defp calcular_efectividad(movimiento, defensor) do
    tipo_mov = movimiento["tipo"]
    tipos_def = defensor["tipos"] || []

    Enum.reduce(tipos_def, 1.0, fn tipo_def, acc ->
      acc * modificador(tipo_mov, tipo_def)
    end)
  end

  defp modificador(tipo_atk, tipo_def) do
    cond do
      tipo_def in Map.get(@efectividades, tipo_atk, []) -> 2.0
      tipo_atk in Map.get(@efectividades, tipo_def, []) -> 0.5
      true -> 1.0
    end
  end
end
