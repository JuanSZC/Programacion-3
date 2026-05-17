defmodule AzarApp.Mailer.NotificacionEmail do
  import Swoosh.Email
  alias AzarApp.Mailer

  @from {"Azar App", "notificaciones.azarapp@gmail.com"}

  # ── Correo al ganador ──────────────────────────────────────────────
  def premio_ganado(usuario, sorteo, ticket_numero, monto) do
    new()
    |> to({usuario.nombre, usuario.email})
    |> from(@from)
    |> subject("🎉 ¡Ganaste en #{sorteo.titulo}!")
    |> html_body("""
    <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px">
      <h1 style="color:#7c3aed">¡Felicitaciones, #{usuario.nombre}!</h1>
      <p>Tu ticket <strong>##{ticket_numero}</strong> fue el ganador del sorteo
         <strong>#{sorteo.titulo}</strong>.</p>
      <div style="background:#f3f0ff;border-radius:12px;padding:24px;text-align:center;margin:24px 0">
        <p style="margin:0;font-size:14px;color:#6b7280">Premio acreditado</p>
        <p style="margin:8px 0 0;font-size:36px;font-weight:900;color:#7c3aed">
          $#{monto}
        </p>
      </div>
      <p style="color:#6b7280;font-size:13px">
        El saldo ya fue acreditado en tu cuenta. ¡Buena suerte en el próximo sorteo!
      </p>
    </div>
    """)
    |> text_body("""
    ¡Felicitaciones, #{usuario.nombre}!
    Tu ticket ##{ticket_numero} ganó el sorteo #{sorteo.titulo}.
    Premio: $#{monto}
    El saldo ya fue acreditado en tu cuenta.
    """)
    |> Mailer.deliver()
  end

  # ── Correo al comprador cuando compra un ticket ────────────────────
  def ticket_comprado(usuario, sorteo, ticket_numero) do
    new()
    |> to({usuario.nombre, usuario.email})
    |> from(@from)
    |> subject("🎟️ Confirmación de compra — #{sorteo.titulo}")
    |> html_body("""
    <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px">
      <h1 style="color:#7c3aed">¡Compra exitosa!</h1>
      <p>Hola <strong>#{usuario.nombre}</strong>, tu ticket fue reservado correctamente.</p>
      <div style="background:#f3f0ff;border-radius:12px;padding:24px;margin:24px 0">
        <p style="margin:0;font-size:13px;color:#6b7280">Sorteo</p>
        <p style="margin:4px 0 16px;font-size:18px;font-weight:900;color:#7c3aed">#{sorteo.titulo}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Número de ticket</p>
        <p style="margin:4px 0 16px;font-size:32px;font-weight:900;color:#111">##{ticket_numero}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Precio pagado</p>
        <p style="margin:4px 0 0;font-size:18px;font-weight:700;color:#111">$#{sorteo.precio_ticket}</p>
      </div>
      <p style="color:#6b7280;font-size:13px">¡Mucha suerte! 🍀</p>
    </div>
    """)
    |> text_body("""
    ¡Compra exitosa, #{usuario.nombre}!
    Sorteo: #{sorteo.titulo}
    Ticket: ##{ticket_numero}
    Precio: $#{sorteo.precio_ticket}
    ¡Buena suerte!
    """)
    |> Mailer.deliver()
  end

  # ── Correo al admin cuando se crea un sorteo ──────────────────────
  def sorteo_creado(admin_email, sorteo) do
    new()
    |> to(admin_email)
    |> from(@from)
    |> subject("📋 Nuevo sorteo creado — #{sorteo.titulo}")
    |> html_body("""
    <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px">
      <h1 style="color:#7c3aed">Nuevo sorteo creado</h1>
      <div style="background:#f9fafb;border-radius:12px;padding:24px;margin:24px 0">
        <p style="margin:0;font-size:13px;color:#6b7280">Título</p>
        <p style="margin:4px 0 16px;font-size:18px;font-weight:900;color:#111">#{sorteo.titulo}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Tipo de premio</p>
        <p style="margin:4px 0 16px;font-size:15px;font-weight:700;color:#111">#{sorteo.tipo_premio}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Precio por ticket</p>
        <p style="margin:4px 0 16px;font-size:15px;font-weight:700;color:#111">$#{sorteo.precio_ticket}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Total de tickets</p>
        <p style="margin:4px 0 0;font-size:15px;font-weight:700;color:#111">#{sorteo.total_tickets}</p>
      </div>
    </div>
    """)
    |> text_body("""
    Nuevo sorteo creado: #{sorteo.titulo}
    Tipo: #{sorteo.tipo_premio}
    Precio ticket: $#{sorteo.precio_ticket}
    Total tickets: #{sorteo.total_tickets}
    """)
    |> Mailer.deliver()
  end

  # ── Correo al admin cuando se ejecuta un sorteo ───────────────────
  def sorteo_ejecutado(admin_email, sorteo, ganadores, premio_por_ganador) do
    numeros = Enum.join(sorteo.numeros_ganadores, ", ")

    new()
    |> to(admin_email)
    |> from(@from)
    |> subject("✅ Sorteo ejecutado — #{sorteo.titulo}")
    |> html_body("""
    <div style="font-family:sans-serif;max-width:500px;margin:0 auto;padding:32px">
      <h1 style="color:#16a34a">Sorteo finalizado</h1>
      <div style="background:#f0fdf4;border-radius:12px;padding:24px;margin:24px 0">
        <p style="margin:0;font-size:13px;color:#6b7280">Sorteo</p>
        <p style="margin:4px 0 16px;font-size:18px;font-weight:900;color:#111">#{sorteo.titulo}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Tickets ganadores</p>
        <p style="margin:4px 0 16px;font-size:15px;font-weight:700;color:#111">##{numeros}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Premio por ganador</p>
        <p style="margin:4px 0 16px;font-size:15px;font-weight:700;color:#111">$#{premio_por_ganador}</p>
        <p style="margin:0;font-size:13px;color:#6b7280">Cantidad de ganadores</p>
        <p style="margin:4px 0 0;font-size:15px;font-weight:700;color:#111">#{length(ganadores)}</p>
      </div>
    </div>
    """)
    |> text_body("""
    Sorteo finalizado: #{sorteo.titulo}
    Ganadores: ##{numeros}
    Premio por ganador: $#{premio_por_ganador}
    Cantidad de ganadores: #{length(ganadores)}
    """)
    |> Mailer.deliver()
  end
end
