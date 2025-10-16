(function () {
    function scrollToCenter(target) {
        let el = typeof target === "string" ? document.getElementById(target.replace(/^#/, "")) : target;
        if (!el) return;
        let ok = false;
        try {
            el.scrollIntoView({ behavior: "smooth", block: "center", inline: "center" });
            ok = true;
        } catch (e) {}
        if (!ok) {
            const elRect = el.getBoundingClientRect();
            const absoluteElementTop = elRect.top + window.pageYOffset;
            const absoluteElementLeft = elRect.left + window.pageXOffset;
            const targetTop = absoluteElementTop - window.innerHeight / 2 + elRect.height / 2;
            const targetLeft = absoluteElementLeft - window.innerWidth / 2 + elRect.width / 2;
            window.scrollTo({ top: targetTop, left: targetLeft, behavior: "smooth" });
        }
    }

    function onNavbarClick(e) {
        const link = e.target.closest(".navbar-link");
        if (link && link.hash && link.hash[0] === "#") {
            const sectionId = link.hash.slice(1);
            const section = document.getElementById(sectionId);
            if (section) {
                e.preventDefault();
                scrollToCenter(section);
                history.replaceState(null, "", link.hash);
            }
        }
    }
    function onHashChange() {
        const id = location.hash.replace(/^#/, "");
        if (id) {
            const section = document.getElementById(id);
            if (section) {
                scrollToCenter(section);
            }
        }
    }
    document.addEventListener("DOMContentLoaded", function () {
        document.body.addEventListener("click", onNavbarClick, false);
        window.addEventListener("hashchange", onHashChange, false);
        if (location.hash.length > 1) {
            setTimeout(onHashChange, 1);
        }
    });

    window.scrollToSectionCenter = scrollToCenter;
})();
