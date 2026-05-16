/**
 * Main Application JavaScript
 *
 * Archivo principal de entrada para el frontend de la aplicación Phoenix.
 * Configura la conexión LiveSocket, la barra de carga (topbar) y registra
 * los event listeners personalizados para la interoperabilidad con LiveView.
 */

import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/azar_app"
import topbar from "../vendor/topbar"

// 1. Configuración del Token CSRF para seguridad
const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// 2. Event Listeners Personalizados (Eventos emitidos desde LiveView)

/**
 * Escucha el evento `phx:scroll_to_panel` emitido desde el servidor
 * para hacer scroll suave hacia el panel de selección de tickets.
 */
window.addEventListener("phx:scroll_to_panel", () => {
  const panel = document.getElementById("panel-seleccion");
  if (panel) panel.scrollIntoView({ behavior: "smooth", block: "center" });
});


// 3. Inicialización y Configuración de LiveSocket
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// 4. Configuración de Topbar (Indicador de carga en la navegación)
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// 5. Conectar LiveView
liveSocket.connect()

// Exponer liveSocket globalmente para debug en la consola del navegador
window.liveSocket = liveSocket

// 6. Herramientas del Entorno de Desarrollo (Live Reload & Debugging)
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    reloader.enableServerLogs()

    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      // Click + 'c' = Abre el editor en la ubicación de la llamada
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      // Click + 'd' = Abre el editor en la definición del componente
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}