// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import Rails from "@rails/ujs"
import * as ActiveStorage from "@rails/activestorage"
// import "channels"
import "controllers"
import "@hotwired/turbo-rails"

import "trix"
import "@rails/actiontext"

import "readmore"
import "dictionary"
import "mentions"
import "livesearch"




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

let hoverTimer;
let hideTimer;

$(document).on("mouseenter", ".user-hover-trigger", function(e){
    const userId = $(this).data("user-id");
    if(!userId) return;
    clearTimeout(hideTimer);
    hoverTimer = setTimeout(function(){

        $.get(`/users/${userId}/hovercard`, function(html){
            $("#user-hover-content").html(html);
            $("#user-hover-card")
              .removeClass("d-none")
              .css({
                top: e.pageY + 15,
                left: e.pageX + 15
              });
        });
    }, 250);
});

$(document).on("mouseleave", ".user-hover-trigger", function(){
    clearTimeout(hoverTimer);
    hideTimer = setTimeout(function(){
        $("#user-hover-card").addClass("d-none");
    }, 300);
});

$(document).on("mouseenter", "#user-hover-card", function(){
    clearTimeout(hideTimer);
});

$(document).on("mouseleave", "#user-hover-card", function(){
    hideTimer = setTimeout(function(){
        $("#user-hover-card").addClass("d-none");
    }, 300);
});