// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const focusSearch = () => {
  const search = document.getElementById("search")
  if (search) {
    search.focus()
    search.select()
  }
}

const enhanceCodeBlocks = () => {
  if (window.hljs) {
    document.querySelectorAll("pre code").forEach((block) => window.hljs.highlightElement(block))
  }

  document.querySelectorAll("pre code").forEach((block) => {
    const pre = block.parentElement
    if (!pre || pre.dataset.enhanced === "true") return

    pre.dataset.enhanced = "true"
    pre.classList.add("group", "relative")

    const button = document.createElement("button")
    button.type = "button"
    button.textContent = "Copy"
    button.className =
      "absolute right-2 top-2 hidden rounded-md bg-slate-900 px-2 py-1 text-xs font-semibold text-white shadow group-hover:block dark:bg-slate-700"

    button.addEventListener("click", async (event) => {
      event.preventDefault()
      const text = block.innerText
      try {
        if (navigator.clipboard?.writeText) {
          await navigator.clipboard.writeText(text)
        } else {
          const textarea = document.createElement("textarea")
          textarea.value = text
          textarea.style.position = "fixed"
          textarea.style.opacity = "0"
          document.body.appendChild(textarea)
          textarea.select()
          document.execCommand("copy")
          document.body.removeChild(textarea)
        }
        button.textContent = "Copied"
        setTimeout(() => (button.textContent = "Copy"), 1200)
      } catch (_error) {
        button.textContent = "Error"
        setTimeout(() => (button.textContent = "Copy"), 1200)
      }
    })

    pre.appendChild(button)
  })
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

document.addEventListener('keydown', function (event) {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault()
    focusSearch()
  }
});

document.addEventListener("DOMContentLoaded", enhanceCodeBlocks)

window.addEventListener("phx:page-loading-stop", () => {
  topbar.hide()
  enhanceCodeBlocks()
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
