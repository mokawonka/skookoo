// app/javascript/controllers/audio_unlocker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const unlockAudio = () => {
      //console.log("Unlocking audio context on user gesture")

      const silent = new Audio("/assets/sounds/silent.mp3")
      silent.volume = 0
      silent.play().catch(() => {})  // silent fail is ok

      // Optional: notify your sound controller
      document.dispatchEvent(new CustomEvent("unlock-audio"))

      // Only unlock once
      document.removeEventListener("click", unlockAudio)
      document.removeEventListener("touchstart", unlockAudio)
      document.removeEventListener("keydown", unlockAudio)
    }

    // Listen for first real user interaction
    document.addEventListener("click", unlockAudio, { once: true })
    document.addEventListener("touchstart", unlockAudio, { once: true })
    document.addEventListener("keydown", unlockAudio, { once: true })
  }
}