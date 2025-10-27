(function () {
    const rail = document.querySelector(".portfolio-rail");
    const left = document.querySelector(".portfolio-arrow-left");
    const right = document.querySelector(".portfolio-arrow-right");
    if (!rail || !left || !right) return;

    const getStep = () => {
        const card = rail.querySelector(".project-card");
        if (!card) return 340;
        const gap = parseInt(getComputedStyle(rail).gap) || 32;
        return card.offsetWidth + gap;
    };

    left.addEventListener("click", function () {
        rail.scrollBy({ left: -getStep(), behavior: "smooth" });
    });
    right.addEventListener("click", function () {
        rail.scrollBy({ left: getStep(), behavior: "smooth" });
    });
})();
