(function () {
    const list = document.querySelector(".portfolio-list");
    const left = document.querySelector(".portfolio-arrow-left");
    const right = document.querySelector(".portfolio-arrow-right");
    if (!list || !left || !right) return;
    const CARD_STEP = list.querySelector(".portfolio-card")
        ? list.querySelector(".portfolio-card").offsetWidth + 24
        : 324;
    left.addEventListener("click", function () {
        list.scrollBy({ left: -CARD_STEP, behavior: "smooth" });
    });
    right.addEventListener("click", function () {
        list.scrollBy({ left: CARD_STEP, behavior: "smooth" });
    });

    let startX = null,
        lastX = null;
    let isDragging = false;
    let moved = false;
    let dxInertia = 0,
        rafId = null;

    function animateInertia() {
        if (Math.abs(dxInertia) > 0.5) {
            list.scrollLeft -= dxInertia;
            dxInertia *= 0.93;
            rafId = requestAnimationFrame(animateInertia);
        } else {
            dxInertia = 0;
            rafId = null;
        }
    }

    list.addEventListener("touchstart", function (e) {
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
    list.addEventListener("touchmove", function (e) {
        if (!isDragging) return;
        moved = true;
        let x = e.touches[0].clientX;
        let dx = x - lastX;
        list.scrollLeft -= dx;
        dxInertia = dx;
        lastX = x;
    });
    list.addEventListener("touchend", function () {
        isDragging = false;
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        startX = lastX = null;
    });
    list.addEventListener("mousedown", function (e) {
        if (e.button !== 0 || e.target.closest(".portfolio-arrow")) return;
        isDragging = true;
        startX = lastX = e.clientX;
        moved = false;
        dxInertia = 0;
        list.classList.add("is-dragging");
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
        list.scrollLeft -= dx;
        dxInertia = dx;
        lastX = e.clientX;
    });
    document.addEventListener("mouseup", function () {
        if (!isDragging) return;
        isDragging = false;
        list.classList.remove("is-dragging");
        document.body.style.userSelect = "";
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        startX = lastX = null;
    });
    list.addEventListener("mouseleave", function () {
        if (!isDragging) return;
        isDragging = false;
        list.classList.remove("is-dragging");
        document.body.style.userSelect = "";
        if (Math.abs(dxInertia) > 12 && !rafId) rafId = requestAnimationFrame(animateInertia);
        startX = lastX = null;
    });
})();
