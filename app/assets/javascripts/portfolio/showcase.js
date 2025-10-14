(function () {
    const rail = document.querySelector(".portfolio-rail");
    const left = document.querySelector(".portfolio-arrow-left");
    const right = document.querySelector(".portfolio-arrow-right");
    if (!rail || !left || !right) return;
    const getStep = () => {
        const card = rail.querySelector(".project-card");
        return card ? card.offsetWidth + 32 : 340;
    };
    function scrollSnapToNearestCard() {
        const cards = [...rail.querySelectorAll(".project-card")];
        if (!cards.length) return;
        const scroll = rail.scrollLeft;
        let minDelta = Infinity;
        let snapPos = 0;
        for (let card of cards) {
            const left = card.offsetLeft;
            const delta = Math.abs(left - scroll);
            if (delta < minDelta) {
                minDelta = delta;
                snapPos = left;
            }
        }
        rail.scrollTo({ left: snapPos, behavior: "smooth" });
    }
    left.addEventListener("click", function () {
        rail.scrollBy({ left: -getStep(), behavior: "smooth" });
        setTimeout(scrollSnapToNearestCard, 400);
    });
    right.addEventListener("click", function () {
        rail.scrollBy({ left: getStep(), behavior: "smooth" });
        setTimeout(scrollSnapToNearestCard, 400);
    });
    let startX = null,
        lastX = null;
    let isDragging = false,
        moved = false;
    let dxInertia = 0,
        rafId = null;
    function animateInertia() {
        if (Math.abs(dxInertia) > 0.5) {
            rail.scrollLeft -= dxInertia;
            dxInertia *= 0.93;
            rafId = requestAnimationFrame(animateInertia);
        } else {
            dxInertia = 0;
            rafId = null;
            scrollSnapToNearestCard(); // Snap after inertia ends
        }
    }
    rail.addEventListener("touchstart", function (e) {
        if (e.touches.length === 1) {
            isDragging = true;
            startX = lastX = e.touches[0].clientX;
            if (rafId) {
                cancelAnimationFrame(rafId);
                rafId = null;
            }
        }
        moved = false;
    });
    rail.addEventListener("touchmove", function (e) {
        if (!isDragging) return;
        moved = true;
        let x = e.touches[0].clientX;
        let dx = x - lastX;
        rail.scrollLeft -= dx;
        dxInertia = dx;
        lastX = x;
    });
    rail.addEventListener("touchend", function () {
        isDragging = false;
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        else scrollSnapToNearestCard();
        startX = lastX = null;
    });
    rail.addEventListener("mousedown", function (e) {
        if (e.button !== 0 || e.target.closest(".portfolio-arrow")) return;
        isDragging = true;
        startX = lastX = e.clientX;
        moved = false;
        dxInertia = 0;
        rail.classList.add("is-dragging");
        document.body.style.userSelect = "none";
        if (rafId) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
    });
    document.addEventListener("mousemove", function (e) {
        if (!isDragging) return;
        moved = true;
        let dx = e.clientX - lastX;
        rail.scrollLeft -= dx;
        dxInertia = dx;
        lastX = e.clientX;
    });
    document.addEventListener("mouseup", function () {
        if (!isDragging) return;
        isDragging = false;
        rail.classList.remove("is-dragging");
        document.body.style.userSelect = "";
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        else scrollSnapToNearestCard();
        startX = lastX = null;
    });
    rail.addEventListener("mouseleave", function () {
        if (!isDragging) return;
        isDragging = false;
        rail.classList.remove("is-dragging");
        document.body.style.userSelect = "";
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        else scrollSnapToNearestCard();
        startX = lastX = null;
    });
})();
