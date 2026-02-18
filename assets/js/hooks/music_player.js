const STORAGE_KEY = "blog:music_player:v1"

const formatTime = (value) => {
  if (!Number.isFinite(value) || value < 0) return "--:--"
  const minutes = Math.floor(value / 60)
  const seconds = Math.floor(value % 60)
  return `${minutes}:${String(seconds).padStart(2, "0")}`
}

const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

function getGlobalAudio() {
  if (!window.__musicPlayerAudio) {
    window.__musicPlayerAudio = new Audio()
    window.__musicPlayerAudio.preload = "metadata"
  }
  return window.__musicPlayerAudio
}

const MusicPlayer = {
  mounted() {
    this.audio = getGlobalAudio()

    this.state = {
      current_track_id: null,
      current_time: 0,
      is_playing: false,
      volume: 0.8,
      is_muted: false,
      repeat_mode: "off",
      shuffle_enabled: false,
      is_expanded: false,
    }

    this.lastSavedAt = 0
    this.isSeeking = false
    this.pendingSeekTime = null
    this.hadTracks = false
    this.restoreApplied = false

    this.refreshElements()
    this.loadState()
    this.applyState()
    this.syncFromDataset()

    this.onClick = (event) => {
      const play = event.target.closest("[data-player-play]")
      if (play) {
        event.preventDefault()
        this.togglePlay()
        return
      }

      const expand = event.target.closest("[data-player-expand]")
      if (expand) {
        event.preventDefault()
        this.setExpanded(true)
        return
      }

      const collapse = event.target.closest("[data-player-collapse]")
      if (collapse) {
        event.preventDefault()
        this.setExpanded(false)
        return
      }

      const mute = event.target.closest("[data-player-mute]")
      if (mute) {
        event.preventDefault()
        this.toggleMute()
      }
    }

    this.onInput = (event) => {
      if (event.target.matches("[data-player-seek]")) {
        this.isSeeking = true
        const percent = clamp(Number(event.target.value) || 0, 0, 100)
        this.updateProgress(percent)
        return
      }

      if (event.target.matches("[data-player-volume]")) {
        const volume = clamp(Number(event.target.value) || 0, 0, 100) / 100
        this.setVolume(volume)
      }
    }

    this.onChange = (event) => {
      if (event.target.matches("[data-player-seek]")) {
        const percent = clamp(Number(event.target.value) || 0, 0, 100)
        this.seekToPercent(percent)
        this.isSeeking = false
        return
      }
    }

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("change", this.onChange)
  },

  updated() {
    this.refreshElements()
    this.applyState()
    this.syncFromDataset()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("change", this.onChange)
    this.saveState(true)
    this.detachAudio()
    // Audio keeps playing — global Audio object survives navigation
  },

  refreshElements() {
    this.progressEl = this.el.querySelector("[data-player-progress]")
    this.seekInput = this.el.querySelector("[data-player-seek]")
    this.volumeInput = this.el.querySelector("[data-player-volume]")
    this.currentTimeEl = this.el.querySelector("[data-player-current-time]")
    this.durationEl = this.el.querySelector("[data-player-duration]")
    this.collapsedPanel = this.el.querySelector("[data-player-collapsed]")
    this.expandedPanel = this.el.querySelector("[data-player-expanded]")
    this.playIcons = this.el.querySelectorAll("[data-player-icon-play]")
    this.pauseIcons = this.el.querySelectorAll("[data-player-icon-pause]")
    this.volumeIcons = this.el.querySelectorAll("[data-player-icon-volume]")
    this.mutedIcons = this.el.querySelectorAll("[data-player-icon-muted]")
    this.trackButtons = this.el.querySelectorAll("[data-track-id]")

    if (this.hadTracks === false && this.trackButtons.length > 0) {
      this.restoreApplied = false
    }
    this.hadTracks = this.trackButtons.length > 0

    this.attachAudio()
  },

  attachAudio() {
    if (!this.audio || this.audio === this.boundAudio) return

    this.detachAudio()
    this.boundAudio = this.audio

    this.onTimeUpdate = () => this.updateTime()
    this.onLoadedMetadata = () => {
      if (Number.isFinite(this.pendingSeekTime)) {
        this.audio.currentTime = this.pendingSeekTime
        this.pendingSeekTime = null
      }
      this.updateTime()
      this.tryPlayIfNeeded()
    }
    this.onPlay = () => this.setPlaying(true)
    this.onPause = () => this.setPlaying(false)
    this.onEnded = () => {
      this.setPlaying(false)
      this.saveState()
      this.pushEvent("player_next", {})
    }
    this.onVolumeChange = () => {
      this.state.volume = this.audio.volume
      this.state.is_muted = this.audio.muted
      this.syncMuteIcons()
      this.saveState()
    }

    this.audio.addEventListener("timeupdate", this.onTimeUpdate)
    this.audio.addEventListener("loadedmetadata", this.onLoadedMetadata)
    this.audio.addEventListener("play", this.onPlay)
    this.audio.addEventListener("pause", this.onPause)
    this.audio.addEventListener("ended", this.onEnded)
    this.audio.addEventListener("volumechange", this.onVolumeChange)
  },

  detachAudio() {
    if (!this.boundAudio) return
    this.boundAudio.removeEventListener("timeupdate", this.onTimeUpdate)
    this.boundAudio.removeEventListener("loadedmetadata", this.onLoadedMetadata)
    this.boundAudio.removeEventListener("play", this.onPlay)
    this.boundAudio.removeEventListener("pause", this.onPause)
    this.boundAudio.removeEventListener("ended", this.onEnded)
    this.boundAudio.removeEventListener("volumechange", this.onVolumeChange)
    this.boundAudio = null
  },

  loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (!raw) return
      const parsed = JSON.parse(raw)
      if (parsed && typeof parsed === "object") {
        this.state = {...this.state, ...parsed}
      }
    } catch (_error) {
      // ignore
    }
  },

  saveState(force = false) {
    const now = Date.now()
    if (!force && now - this.lastSavedAt < 900) return
    this.lastSavedAt = now

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state))
    } catch (_error) {
      // ignore
    }
  },

  applyState() {
    if (!this.audio) return
    this.setExpanded(Boolean(this.state.is_expanded))
    this.setVolume(this.state.volume)
    this.audio.muted = Boolean(this.state.is_muted)
    this.syncMuteIcons()

    // Sync playing state from actual audio (survives navigation)
    if (!this.audio.paused) {
      this.state.is_playing = true
    }
    this.syncPlayIcons()

    // Only set pending seek if audio hasn't started yet (fresh page load)
    if (this.audio.paused && this.audio.currentTime === 0 &&
        Number.isFinite(this.state.current_time) && this.state.current_time > 0) {
      this.pendingSeekTime = this.state.current_time
    }
  },

  syncFromDataset() {
    const trackId = this.el.dataset.currentTrackId
    const src = this.el.dataset.currentSrc

    if (!this.restoreApplied && this.state.current_track_id && trackId) {
      const desired = String(this.state.current_track_id)
      const current = String(trackId)
      if (desired !== current && this.trackExists(desired)) {
        this.restoreApplied = true
        this.pushEvent("player_select_track", {track_id: desired})
        return
      }
    }

    if (trackId && String(trackId) !== String(this.state.current_track_id)) {
      this.state.current_track_id = trackId
      this.state.current_time = 0
      this.pendingSeekTime = 0
      this.saveState(true)
    }

    if (src && this.audio && src !== this.audio._currentSrc) {
      this.audio._currentSrc = src
      this.audio.src = src
      this.audio.load()
    }

    const repeatMode = this.el.dataset.repeatMode || "off"
    const shuffleEnabled = this.el.dataset.shuffleEnabled === "true"
    this.state.repeat_mode = repeatMode
    this.state.shuffle_enabled = shuffleEnabled
    this.saveState()

    if (!trackId && this.state.current_track_id && this.trackExists(this.state.current_track_id)) {
      this.pushEvent("player_select_track", {track_id: this.state.current_track_id})
    }
  },

  togglePlay() {
    if (!this.audio) return
    if (this.audio.paused) {
      this.audio.play().catch(() => {})
    } else {
      this.audio.pause()
    }
  },

  setPlaying(playing) {
    this.state.is_playing = playing
    this.syncPlayIcons()
    this.saveState()
  },

  syncPlayIcons() {
    this.playIcons.forEach((el) => el.classList.toggle("hidden", this.state.is_playing))
    this.pauseIcons.forEach((el) => el.classList.toggle("hidden", !this.state.is_playing))
  },

  setVolume(volume) {
    if (!this.audio) return
    const normalized = clamp(Number(volume) || 0, 0, 1)
    this.audio.volume = normalized
    if (this.volumeInput) {
      this.volumeInput.value = Math.round(normalized * 100)
    }
    this.state.volume = normalized
    this.saveState()
  },

  toggleMute() {
    if (!this.audio) return
    this.audio.muted = !this.audio.muted
    this.state.is_muted = this.audio.muted
    this.syncMuteIcons()
    this.saveState()
  },

  syncMuteIcons() {
    const muted = this.state.is_muted
    this.volumeIcons.forEach((el) => el.classList.toggle("hidden", muted))
    this.mutedIcons.forEach((el) => el.classList.toggle("hidden", !muted))
  },

  updateTime() {
    if (!this.audio) return
    const duration = Number.isFinite(this.audio.duration) ? this.audio.duration : 0
    const current = this.audio.currentTime || 0

    if (!this.isSeeking) {
      const percent = duration > 0 ? (current / duration) * 100 : 0
      if (this.seekInput) this.seekInput.value = Math.round(percent)
      this.updateProgress(percent)
    }

    if (this.currentTimeEl) this.currentTimeEl.textContent = formatTime(current)
    if (this.durationEl) this.durationEl.textContent = duration > 0 ? formatTime(duration) : "--:--"

    this.state.current_time = current
    this.saveState()
  },

  updateProgress(percent) {
    if (!this.progressEl) return
    this.progressEl.style.width = `${clamp(percent, 0, 100)}%`
  },

  seekToPercent(percent) {
    if (!this.audio) return
    const duration = Number.isFinite(this.audio.duration) ? this.audio.duration : 0
    if (duration <= 0) return
    const target = (clamp(percent, 0, 100) / 100) * duration
    this.audio.currentTime = target
    this.state.current_time = target
    this.saveState(true)
  },

  setExpanded(expanded) {
    this.state.is_expanded = expanded
    if (this.collapsedPanel) this.collapsedPanel.classList.toggle("hidden", expanded)
    if (this.expandedPanel) this.expandedPanel.classList.toggle("hidden", !expanded)
    this.saveState(true)
  },

  tryPlayIfNeeded() {
    if (!this.state.is_playing || !this.audio || !this.audio.paused) return
    this.audio.play().catch(() => {})
  },

  trackExists(trackId) {
    if (!trackId) return false
    return Array.from(this.trackButtons || []).some((el) => el.dataset.trackId === String(trackId))
  },
}

export default MusicPlayer
