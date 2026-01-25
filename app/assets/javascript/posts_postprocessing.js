$('.todecode').each(function(){
    $(this).text(he.decode($(this).text()));
});

function AddReadMore()
{
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

    $(document).on("click", ".readMore,.readLess", function(e) {
        e.preventDefault();
        $(this).closest('.addReadMore').toggleClass("showlesscontent showmorecontent");
    });
}

$(function() {
    // Calling function after Page Load
    AddReadMore();
});