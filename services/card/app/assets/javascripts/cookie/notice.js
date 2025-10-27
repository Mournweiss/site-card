document.addEventListener("DOMContentLoaded", function () {
    var banner = document.getElementById("cookie-notice");
    var accept = document.getElementById("cookie-notice-accept");
    if (!banner || !accept) return;
    function getConsentCookie() {
        return document.cookie.split(";").some(function (c) {
            return c.trim().indexOf("sitecard_cookie_consent=") === 0;
        });
    }
    function setConsentCookie() {
        var d = new Date();
        d.setTime(d.getTime() + 365 * 24 * 60 * 60 * 1000);
        document.cookie = "sitecard_cookie_consent=1; path=/; max-age=" + 365 * 24 * 60 * 60 + "; samesite=Strict";
    }
    if (!getConsentCookie()) {
        banner.classList.add("cookie-notice-visible");
    }
    accept.addEventListener("click", function () {
        setConsentCookie();
        banner.classList.remove("cookie-notice-visible");
    });
});
