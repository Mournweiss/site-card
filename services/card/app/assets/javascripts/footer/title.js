document.addEventListener("DOMContentLoaded", function () {
    var titleSpan = document.getElementById("footer-title");
    if (titleSpan) {
        titleSpan.textContent = new Date().getFullYear() + " SiteCard";
    }
});
