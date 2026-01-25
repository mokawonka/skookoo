// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import Rails from "@rails/ujs"
import * as ActiveStorage from "@rails/activestorage"
// import "channels"
import "controllers"
import "@hotwired/turbo-rails"

import "trix"
import "@rails/actiontext"



Rails.start()
ActiveStorage.start()


import { StreamActions } from "@hotwired/turbo"   // or Turbo.StreamActions

StreamActions.play_notification_sound = function () {
  //console.log("Custom action play_notification_sound received!")

  const controllerElement = document.querySelector('[data-controller="notification-sound"][data-turbo-permanent]')
  
  if (controllerElement) {
    //console.log("Found notification-sound element – dispatching event")
    controllerElement.dispatchEvent(new CustomEvent("play-sound", { bubbles: true }))
  } else {
    console.warn("No permanent notification-sound controller found")
  }
}