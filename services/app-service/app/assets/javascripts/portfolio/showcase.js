// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Horizontal scrolling for portfolio/project showcase rail.
 * Attaches click event listeners to arrow controls to scroll project cards smoothly left/right.
 *
 * Expects elements:
 *   - .portfolio-rail (scrollable container for cards)
 *   - .portfolio-arrow-left / .portfolio-arrow-right (controls)
 *
 * Adapts scroll step to card width + gap. Uses smooth behavior for UX.
 */
(function () {
    const rail = document.querySelector(".portfolio-rail");
    const left = document.querySelector(".portfolio-arrow-left");
    const right = document.querySelector(".portfolio-arrow-right");
    if (!rail || !left || !right) return;

    /**
     * Determines number of pixels to scroll by (1 card + grid gap).
     * Falls back to 340px if measurement fails.
     * @returns {number}
     */
    const getStep = () => {
        const card = rail.querySelector(".project-card");
        if (!card) return 340;
        const gap = parseInt(getComputedStyle(rail).gap) || 32;
        return card.offsetWidth + gap;
    };

    // Scrolls left by one card width
    left.addEventListener("click", function () {
        rail.scrollBy({ left: -getStep(), behavior: "smooth" });
    });

    // Scrolls right by one card width
    right.addEventListener("click", function () {
        rail.scrollBy({ left: getStep(), behavior: "smooth" });
    });
})();
