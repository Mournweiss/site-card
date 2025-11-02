// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Footer title updater for copyright.
 * On DOM ready, sets #footer-title to 'YYYY SiteCard' where YYYY is the current year.
 *
 * Requires an element with id 'footer-title'.
 */
document.addEventListener("DOMContentLoaded", function () {
    var titleSpan = document.getElementById("footer-title");
    if (titleSpan) {
        titleSpan.textContent = new Date().getFullYear() + " SiteCard";
    }
});
