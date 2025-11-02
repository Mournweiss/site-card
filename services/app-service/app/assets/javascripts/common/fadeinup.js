/**
 * Applies fade-in-up animation classes to elements when scrolled into view.
 * Uses IntersectionObserver for visibility detection. Only runs if IntersectionObserver is supported.
 *
 * Elements should have .fadein-up; class .fadein-up--active toggles animation.
 */
(function () {
    // Feature detect IntersectionObserver
    if (!("IntersectionObserver" in window)) return;
    const fadeElems = Array.prototype.slice.call(document.querySelectorAll(".fadein-up"));
    if (!fadeElems.length) return;

    /**
     * Handles intersection changes, toggles active animation class.
     * @param {IntersectionObserverEntry[]} entries
     */
    const obs = new IntersectionObserver(
        entries => {
            entries.forEach(entry => {
                const ratio = entry.intersectionRatio;
                if (ratio >= 0.4) {
                    entry.target.classList.add("fadein-up--active");
                } else if (ratio <= 0.05) {
                    entry.target.classList.remove("fadein-up--active");
                }
            });
        },
        { threshold: [0.05, 0.4] }
    );
    fadeElems.forEach(el => obs.observe(el));
})();
