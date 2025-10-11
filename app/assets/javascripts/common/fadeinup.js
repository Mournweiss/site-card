(function () {
    if (!("IntersectionObserver" in window)) return;
    const fadeElems = Array.prototype.slice.call(document.querySelectorAll(".fadein-up"));
    if (!fadeElems.length) return;
    const obs = new IntersectionObserver(
        entries => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add("fadein-up--active");
                } else {
                    entry.target.classList.remove("fadein-up--active");
                }
            });
        },
        { threshold: 0.3 }
    );
    fadeElems.forEach(el => obs.observe(el));
})();
