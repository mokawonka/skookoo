function runPostsPostprocessing() {
    $('.todecode').each(function(){
        $(this).text(he.decode($(this).text()));
    });

    var carLmt = 300;
    var readMoreTxt = " read more";
    var readLessTxt = " read less";
    $(".addReadMore").each(function() {

        if ($(this).find(".firstSec").length) return;

        var allstr = $(this).text();
        if (allstr.length > carLmt) {
            var firstSet = allstr.substring(0, carLmt);
            var secdHalf = allstr.substring(carLmt, allstr.length);
            var strtoadd = firstSet + "<span class='SecSec'>" + secdHalf + "</span><span class='btn btn-sm btn-link readMore'>" + readMoreTxt + "</span><span class='btn btn-sm btn-link readLess'>" + readLessTxt + "</span>";
            $(this).html(strtoadd);
        }

    });
}

function initReadMoreClick() {
    $(document).off("click.readMoreLess", ".readMore,.readLess");
    $(document).on("click.readMoreLess", ".readMore,.readLess", function(e) {
        e.preventDefault();
        $(this).closest('.addReadMore').toggleClass("showlesscontent showmorecontent");
    });
}

function initPostsPostprocessing() {
    runPostsPostprocessing();
    initReadMoreClick();
}

$(function() {
    initPostsPostprocessing();
});

// Re-run when Turbo loads new page content (e.g. clicking user link from another page)
document.addEventListener("turbo:load", function() {
    initPostsPostprocessing();
});