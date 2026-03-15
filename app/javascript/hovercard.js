document.addEventListener("turbo:load", function () {

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

});