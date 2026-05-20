defmodule PokemonBattle.Comunicacion do

  alias PokemonBattle.SupervisorBatallas

  # =========================
  # INICIAR RECEPTOR
  # =========================
  def iniciar_receptor do
    pid =
      spawn(
        __MODULE__,
        :escuchar,
        []
      )

    Process.register(
      pid,
      :receptor
    )

    pid
  end

  # =========================
  # ENVIAR MENSAJE
  # =========================
  def enviar_mensaje(
        nodo,
        mensaje
      ) do

    send(
      {:receptor, nodo},
      mensaje
    )
  end

  # =========================
  # ESCUCHAR
  # =========================
  def escuchar do

    receive do

      {:mensaje, texto} ->
        IO.puts(
          "Mensaje recibido: #{texto}"
        )

      {:iniciar_batalla, j1, j2, pid_cliente} ->

  IO.puts(
    "Solicitud recibida: #{j1} vs #{j2}"
  )

  {:ok, pid_batalla} =
    SupervisorBatallas.crear_batalla(
      j1,
      j2
    )

  send(
    pid_cliente,
    {:batalla_creada, pid_batalla}
  )

      otro ->
        IO.inspect(
          otro,
          label: "Mensaje desconocido"
        )

    end

    escuchar()
  end
end
