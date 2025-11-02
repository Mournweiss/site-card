/**
 * Scrolls the target element to the center of the viewport (vertically and horizontally).
 * Uses native scrollIntoView if supported, falls back to manual scroll.
 *
 * @param {HTMLElement|string} target - Element or id (with or without #) to scroll to.
 * @returns {void}
 */
(function () {
    function scrollToCenter(target) {
        let el = typeof target === "string" ? document.getElementById(target.replace(/^#/, "")) : target;
        if (!el) return;
        let ok = false;
        try {
            // Native smooth scroll, block:center, if browser supports.
            el.scrollIntoView({ behavior: "smooth", block: "center", inline: "center" });
            ok = true;
        } catch (e) {}
        if (!ok) {
            // Manual fallback: compute and scroll so element is centered
            const elRect = el.getBoundingClientRect();
            const absoluteElementTop = elRect.top + window.pageYOffset;
            const absoluteElementLeft = elRect.left + window.pageXOffset;
            const targetTop = absoluteElementTop - window.innerHeight / 2 + elRect.height / 2;
            const targetLeft = absoluteElementLeft - window.innerWidth / 2 + elRect.width / 2;
            window.scrollTo({ top: targetTop, left: targetLeft, behavior: "smooth" });
        }
    }

    /**
     * Handles navbar .navbar-link clicks - prevents default and scrolls to section.
     * Updates browser history with new hash.
     *
     * @param {MouseEvent} e - Click event.
     */
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

    /**
     * Responds to hashchange events (from URL), scrolls to target section if found.
     * Used for navigation via anchor/hash links directly.
     */
    function onHashChange() {
        const id = location.hash.replace(/^#/, "");
        if (id) {
            const section = document.getElementById(id);
            if (section) {
                scrollToCenter(section);
            }
        }
    }

    // Register navigation handlers on page ready
    document.addEventListener("DOMContentLoaded", function () {
        document.body.addEventListener("click", onNavbarClick, false);
        window.addEventListener("hashchange", onHashChange, false);

        // If page loaded with hash, attempt scroll
        if (location.hash.length > 1) {
            setTimeout(onHashChange, 1);
        }
    });

    // Export as window global for manual scroll usage elsewhere
    window.scrollToSectionCenter = scrollToCenter;
})();
