(function () {
    const animateBars = () => {
        const bars = document.querySelectorAll(".about-skill-bar .progress-bar, .about-exp-bar .progress-bar");
        bars.forEach(bar => {
            const target = parseInt(bar.getAttribute("aria-valuenow"), 10) || 0;
            bar.style.width = target + "%";
        });
    };
    const aboutSection = document.getElementById("about");
    if (aboutSection && "IntersectionObserver" in window) {
        const observer = new IntersectionObserver(
            (entries, obs) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        animateBars();
                        obs.unobserve(entry.target);
                    }
                });
            },
            { threshold: 0.22 }
        );
        observer.observe(aboutSection);
    } else {
        animateBars();
    }
})();
