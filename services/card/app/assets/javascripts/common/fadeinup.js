(function () {
    if (!("IntersectionObserver" in window)) return;
    const fadeElems = Array.prototype.slice.call(document.querySelectorAll(".fadein-up"));
    if (!fadeElems.length) return;
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
