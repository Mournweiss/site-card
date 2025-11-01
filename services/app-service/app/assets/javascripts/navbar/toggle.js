(function () {
    var toggle = document.querySelector(".navbar-toggle");
    var nav = document.getElementById("navbar-list");
    if (toggle && nav) {
        toggle.addEventListener("click", function () {
            var expanded = this.getAttribute("aria-expanded") === "true";
            this.setAttribute("aria-expanded", !expanded);
            nav.classList.toggle("navbar-list-expanded", !expanded);
        });
    }
})();
