function runPostsPostprocessing() {
  function decodeHtmlEntities(str) {
    const txt = document.createElement("textarea");
    txt.innerHTML = str;
    return txt.value;
  }

  $('.todecode').each(function() {
    $(this).text(decodeHtmlEntities($(this).text()));
  });

  var carLmt = 300;
  var readMoreTxt = " read more";
  var readLessTxt = " read less";

  $(".addReadMore").each(function() {
    if ($(this).find(".readMore").length) return;

    var allstr = $(this).text();
    if (allstr.length > carLmt) {
      var firstSet = allstr.substring(0, carLmt);
      var secdHalf = allstr.substring(carLmt, allstr.length);
      var strtoadd = firstSet +
        "<span class='SecSec' style='display:none'>" + secdHalf + "</span>" +
        "<span class='btn btn-sm btn-link readMore'>" + readMoreTxt + "</span>" +
        "<span class='btn btn-sm btn-link readLess' style='display:none'>" + readLessTxt + "</span>";
      $(this).html(strtoadd);
    }
  });
}

function initReadMoreClick() {
  $(document).off("click.readMoreLess", ".readMore,.readLess");

  $(document).on("click.readMoreLess", ".readMore", function(e) {
    e.preventDefault();
    var container = $(this).closest('.addReadMore');
    container.find(".SecSec").show();
    container.find(".readMore").hide();
    container.find(".readLess").show();
  });

  $(document).on("click.readMoreLess", ".readLess", function(e) {
    e.preventDefault();
    var container = $(this).closest('.addReadMore');
    container.find(".SecSec").hide();
    container.find(".readMore").show();
    container.find(".readLess").hide();
  });
}

document.addEventListener("turbo:load", function() {
  runPostsPostprocessing();
  initReadMoreClick();
});

document.addEventListener("turbo:frame-load", function() {
  runPostsPostprocessing();
});
