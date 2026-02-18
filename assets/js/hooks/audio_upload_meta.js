const AudioUploadMeta = {
  mounted() {
    // Find the file input for audio uploads
    this.fileInput = this.el.querySelector('input[type="file"]')
    if (!this.fileInput) return

    this.onFileChange = (event) => {
      const file = event.target.files?.[0]
      if (!file || !file.type.startsWith('audio/')) return

      // Create a temporary audio element to extract metadata
      const url = URL.createObjectURL(file)
      const audio = new Audio()

      audio.addEventListener('loadedmetadata', () => {
        const duration = Math.round(audio.duration)

        // Push the duration to the LiveView
        this.pushEvent('audio_duration', { duration_sec: duration })

        // Clean up the object URL
        URL.revokeObjectURL(url)
      })

      audio.addEventListener('error', () => {
        // Clean up on error
        URL.revokeObjectURL(url)
      })

      audio.src = url
    }

    this.fileInput.addEventListener('change', this.onFileChange)
  },

  destroyed() {
    if (this.fileInput && this.onFileChange) {
      this.fileInput.removeEventListener('change', this.onFileChange)
    }
  }
}

export default AudioUploadMeta
