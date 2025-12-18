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

const RECENT_SEARCHES_KEY = "blog:recent_searches:v1"
const RECENT_SEARCHES_MAX = 3
let recentSearchStoreTimer = null

const focusSearch = () => {
  const search = document.getElementById("search")
  if (search) {
    search.focus()
    search.select()
  }
}

const readRecentSearches = () => {
  try {
    const raw = localStorage.getItem(RECENT_SEARCHES_KEY)
    const parsed = raw ? JSON.parse(raw) : []
    return Array.isArray(parsed) ? parsed.filter((x) => typeof x === "string") : []
  } catch (_error) {
    return []
  }
}

const writeRecentSearches = (list) => {
  try {
    localStorage.setItem(RECENT_SEARCHES_KEY, JSON.stringify(list.slice(0, RECENT_SEARCHES_MAX)))
  } catch (_error) {
    // ignore (private mode / quota)
  }
}

const storeRecentSearch = (query) => {
  const cleaned = (query || "").trim()
  if (cleaned.length < 2) return

  const list = readRecentSearches().filter((item) => item !== cleaned)
  list.unshift(cleaned)
  writeRecentSearches(list)
  window.dispatchEvent(new CustomEvent("recent-searches:updated"))
}

const scheduleStoreRecentSearchFromUrl = () => {
  window.clearTimeout(recentSearchStoreTimer)
  recentSearchStoreTimer = window.setTimeout(() => {
    const params = new URLSearchParams(window.location.search)
    const query = (params.get("query") || "").trim()
    storeRecentSearch(query)
  }, 500)
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

const RecentSearches = {
  mounted() {
    this.input = this.el.querySelector("input")
    this.panel = this.el.querySelector("[data-recent-searches-panel]")
    this.activeIndex = -1
    this.hideTimer = null

    if (!this.input || !this.panel) return

    this.onRecentUpdated = () => this.renderPanel()
    window.addEventListener("recent-searches:updated", this.onRecentUpdated)

    this.onFocus = () => {
      this.activeIndex = -1
      this.renderPanel()
      this.showPanelIfHasItems()
    }

    this.onBlur = () => {
      window.clearTimeout(this.hideTimer)
      this.hideTimer = window.setTimeout(() => this.hidePanel(), 120)
    }

    this.onInput = () => {
      this.activeIndex = -1
      this.renderPanel()
      this.showPanelIfHasItems()
    }

    this.onKeyDown = (event) => {
      if (this.panel.classList.contains("hidden")) return

      const items = Array.from(this.panel.querySelectorAll("[data-recent-item]"))
      if (items.length === 0) return

      if (event.key === "ArrowDown") {
        event.preventDefault()
        this.activeIndex = (this.activeIndex + 1) % items.length
        this.updateActive(items)
      } else if (event.key === "ArrowUp") {
        event.preventDefault()
        this.activeIndex = (this.activeIndex - 1 + items.length) % items.length
        this.updateActive(items)
      } else if (event.key === "Enter" && this.activeIndex >= 0) {
        event.preventDefault()
        const selected = items[this.activeIndex]?.dataset?.value
        if (selected) this.selectQuery(selected)
      } else if (event.key === "Escape") {
        event.preventDefault()
        this.hidePanel()
      }
    }

    this.input.addEventListener("focus", this.onFocus)
    this.input.addEventListener("blur", this.onBlur)
    this.input.addEventListener("input", this.onInput)
    this.input.addEventListener("keydown", this.onKeyDown)

    this.panel.addEventListener("mousedown", (event) => {
      const button = event.target.closest("[data-recent-item]")
      if (!button) return
      event.preventDefault()
      this.selectQuery(button.dataset.value)
    })
  },

  updated() {
    this.renderPanel()
  },

  destroyed() {
    if (this.onRecentUpdated) window.removeEventListener("recent-searches:updated", this.onRecentUpdated)
    if (this.input) {
      this.input.removeEventListener("focus", this.onFocus)
      this.input.removeEventListener("blur", this.onBlur)
      this.input.removeEventListener("input", this.onInput)
      this.input.removeEventListener("keydown", this.onKeyDown)
    }
    window.clearTimeout(this.hideTimer)
    this.input = null
    this.panel = null
  },

  showPanel() {
    if (this.panel) this.panel.classList.remove("hidden")
  },

  hidePanel() {
    if (this.panel) this.panel.classList.add("hidden")
  },

  showPanelIfHasItems() {
    const items = Array.from(this.panel.querySelectorAll("[data-recent-item]"))
    if (items.length > 0) this.showPanel()
    else this.hidePanel()
  },

  updateActive(items) {
    items.forEach((el, idx) => {
      el.classList.toggle("bg-indigo-50", idx === this.activeIndex)
      el.classList.toggle("dark:bg-indigo-900/20", idx === this.activeIndex)
    })
    const el = items[this.activeIndex]
    if (el) el.scrollIntoView({block: "nearest"})
  },

  selectQuery(query) {
    this.input.value = query
    this.input.dispatchEvent(new Event("input", {bubbles: true}))
    this.input.dispatchEvent(new Event("change", {bubbles: true}))
    this.hidePanel()
    this.input.focus()
    this.input.select()
  },

  renderPanel() {
    if (!this.panel) return

    const filter = (this.input?.value || "").trim().toLowerCase()
    let items = readRecentSearches()

    if (filter) {
      items = items.filter((q) => q.toLowerCase().includes(filter))
    }

    items = items.slice(0, RECENT_SEARCHES_MAX)

    if (items.length === 0) {
      this.panel.innerHTML = ""
      this.hidePanel()
      return
    }

    const escape = (text) =>
      text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;")

    this.panel.innerHTML = `
      <div class="px-3 py-2 text-[11px] font-semibold text-gray-500 dark:text-gray-400">
        Recent searches
      </div>
      <div class="max-h-40 overflow-auto">
        ${items
          .map(
            (q) => `
          <button
            type="button"
            data-recent-item
            data-value="${escape(q)}"
            class="block w-full px-3 py-2 text-left text-sm text-gray-800 hover:bg-gray-50 dark:text-gray-100 dark:hover:bg-gray-800/60"
          >
            ${escape(q)}
          </button>
        `
          )
          .join("")}
      </div>
    `
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {RecentSearches},
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

document.addEventListener('keydown', function (event) {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault()
    focusSearch()
  }
});

document.addEventListener("DOMContentLoaded", () => {
  enhanceCodeBlocks()
  scheduleStoreRecentSearchFromUrl()
})

window.addEventListener("phx:page-loading-stop", () => {
  topbar.hide()
  enhanceCodeBlocks()
  scheduleStoreRecentSearchFromUrl()
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
