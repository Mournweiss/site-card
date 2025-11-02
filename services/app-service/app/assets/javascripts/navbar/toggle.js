/**
 * Navbar-toggle interaction logic for responsive/mobile navigation.
 * Toggles nav visibility and aria-expanded attribute for accessibility.
 *
 * Expects one .navbar-toggle button and an element with id 'navbar-list'.
 * Applies/removes 'navbar-list-expanded' class to control nav expansion.
 */
(function () {
    var toggle = document.querySelector(".navbar-toggle");
    var nav = document.getElementById("navbar-list");
    if (toggle && nav) {
        /**
         * Handler for nav toggle button: switches visibility class and aria-expanded for a11y.
         *
         * @this {HTMLElement} Button that was clicked.
         * @returns {void}
         */
        toggle.addEventListener("click", function () {
            var expanded = this.getAttribute("aria-expanded") === "true";
            this.setAttribute("aria-expanded", !expanded);
            nav.classList.toggle("navbar-list-expanded", !expanded);
        });
    }
})();
