defmodule PokemonBattle.MotorCombate do
  @tabla_tipos %{
    "Fuego" => ["Planta", "Hielo", "Bicho"],
    "Agua" => ["Fuego", "Roca", "Tierra"],
    "Planta" => ["Agua", "Roca", "Tierra"],
    "Electrico" => ["Agua", "Volador"],
    "Roca" => ["Fuego", "Hielo", "Volador", "Bicho"]
  }

  def calcular_danio(
        atacante,
        defensor,
        movimiento
      ) do

    ataque =
      atacante["ataque"]

    defensa =
      defensor["defensa"]

    poder =
      movimiento["poder_base"]

    tipo_movimiento =
      movimiento["tipo"]

    tipos_atacante =
      atacante["tipos"] || []

    tipos_defensor =
      defensor["tipos"] || []

    # =========================
    # STAB
    # =========================
    stab =
      if tipo_movimiento in tipos_atacante do
        1.5
      else
        1.0
      end

    # =========================
    # EFECTIVIDAD
    # =========================
    efectividad =
      calcular_efectividad(
        tipo_movimiento,
        tipos_defensor
      )

    # =========================
    # FACTOR ALEATORIO
    # =========================
    factor_random =
      :rand.uniform() * 0.15 + 0.85

    # =========================
    # FORMULA DAÑO
    # =========================
    dano_base =
      trunc(
        (poder * (ataque / defensa)) / 5 + 2
      )

    dano_final =
      trunc(
        dano_base *
        efectividad *
        stab *
        factor_random
      )

    # DAÑO MINIMO
    dano_final =
      max(dano_final, 1)

    %{
      dano: dano_final,
      stab: stab,
      efectividad: efectividad,
      factor_random: Float.round(
        factor_random,
        2
      )
    }
  end

  defp calcular_efectividad(
         tipo_movimiento,
         tipos_defensor
       ) do

    Enum.reduce(
      tipos_defensor,
      1.0,
      fn tipo_defensor, acumulado ->

        cond do
          fuerte_contra?(
            tipo_movimiento,
            tipo_defensor
          ) ->
            acumulado * 2.0

          fuerte_contra?(
            tipo_defensor,
            tipo_movimiento
          ) ->
            acumulado * 0.5

          true ->
            acumulado
        end
      end
    )
  end

  defp fuerte_contra?(
         tipo1,
         tipo2
       ) do

    tipos_fuertes =
      Map.get(
        @tabla_tipos,
        tipo1,
        []
      )

    tipo2 in tipos_fuertes
  end
end
