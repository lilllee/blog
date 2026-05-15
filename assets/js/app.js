import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const getStoredLocale = () => localStorage.getItem("locale") || "ko"

const setStoredLocale = (locale) => {
  localStorage.setItem("locale", locale)
  document.cookie = `locale=${locale};path=/;max-age=${365 * 24 * 60 * 60};SameSite=Lax`
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: () => ({_csrf_token: csrfToken, locale: getStoredLocale()})
})

window.addEventListener("phx:locale-changed", (e) => {
  if (e.detail && e.detail.locale) setStoredLocale(e.detail.locale)
})

topbar.config({barColors: {0: "#a0a0a0"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", () => topbar.show(300))
window.addEventListener("phx:page-loading-stop", () => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket
