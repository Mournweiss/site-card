/**
 * Cookie consent banner logic for site-wide GDPR compliance.
 * Shows a banner unless consent is already set as a cookie.
 * Wires up accept button to set consent cookie for 1 year and hide banner.
 *
 * Requires elements with ids 'cookie-notice' and 'cookie-notice-accept' to be present in the DOM.
 */
document.addEventListener("DOMContentLoaded", function () {
    var banner = document.getElementById("cookie-notice");
    var accept = document.getElementById("cookie-notice-accept");
    if (!banner || !accept) return;

    /**
     * Determines whether consent cookie is already set in document.cookie.
     *
     * @returns {boolean} True if consent cookie present.
     */
    function getConsentCookie() {
        return document.cookie.split(";").some(function (c) {
            return c.trim().indexOf("sitecard_cookie_consent=") === 0;
        });
    }

    /**
     * Sets consent cookie valid for 1 year, path=/, samesite strict.
     *
     * @returns {void}
     */
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
