import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    if (this.hasUrlValue) {
      // console.log("Notification sound preloaded:", this.urlValue)
      this.audio = new Audio(this.urlValue)
      this.audio.preload = "auto"
      this.audio.volume = 0.6
    } else {
      console.warn("No sound URL provided")
    }

    // Prepare bound functions for cleanup
    this.playBound = this.play.bind(this)
    this.onUnlock = this.handleUnlock.bind(this)

    // Listen for play-sound (from your Turbo Stream custom action)
    document.addEventListener("play-sound", this.playBound)

    // Listen for unlock-audio (from audio-unlocker or manual unlock)
    document.addEventListener("unlock-audio", this.onUnlock)
  }

  disconnect() {
    document.removeEventListener("play-sound", this.playBound)
    document.removeEventListener("unlock-audio", this.onUnlock)
  }

  // This was the missing method
  handleUnlock() {
    // console.log("Audio context unlocked — future plays should now be allowed")
    // You can add extra logic here if needed (rarely necessary)
  }

  play() {
    if (!this.audio) {
      console.warn("No preloaded audio available")
      return
    }

    this.audio.currentTime = 0

    this.audio.play()
      .then(() => {
        //console.log("Sound playback started successfully")
      })
      .catch(err => {
        console.error("Audio play failed:", err.name, err.message)

        if (err.name === "NotAllowedError") {
          if (!localStorage.getItem("soundGestureShown")) {
            //alert("Click anywhere on the page to enable notification sounds!")
            localStorage.setItem("soundGestureShown", "true")
          }
        }
      })
  }
}