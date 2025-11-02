// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Generates a pastel color in HSL format based on text hash. Used for avatars).
 *
 * @param {string} str - Any string (usually a name or identifier).
 * @returns {string} HSL color for background styling.
 */
export function getPastelColor(str) {
    if (!str) return "#c4c6e6";
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash) % 360;
    return `hsl(${h}, 57%, 76%)`;
}

/**
 * Extracts the initial character from a name. Used for avatar fallback.
 *
 * @param {string} name - Full name or identifier string.
 * @returns {string} Single uppercase letter, or '?' if unavailable.
 */
export function getInitial(name) {
    if (!name || !(typeof name === "string")) return "?";
    name = name.trim();
    if (!name) return "?";
    return name[0].toUpperCase();
}

/**
 * Initializes the avatar display logic for given DOM element.
 * Shows either an image avatar or a fallback (initial & pastel bg),
 * also wires up onerror/onload for dynamic image switching.
 *
 * @param {HTMLElement} el - The root element containing avatar elements with class avatar-img/avatar-fallback.
 * @returns {void}
 */
export function initAvatarComponent(el) {
    if (!el) return;
    const img = el.querySelector(".avatar-img");
    const fallback = el.querySelector(".avatar-fallback");
    let name = el.dataset.name || "";
    let initial = getInitial(name);
    fallback.textContent = initial; // Fallback initial, e.g. "A" or "?"
    fallback.setAttribute("aria-label", initial === "?" ? "Avatar fallback: unknown" : `Avatar fallback: ${initial}`);
    fallback.style.background = getPastelColor(name);

    // Image is only considered okay if points to valid file (.png/.jpg, >6 chars)
    let imgOk = img && img.src && img.src.length > 6 && img.src.match(/\.(png|jpe?g)$/i);
    if (imgOk) {
        img.classList.remove("d-none");
        fallback.classList.add("d-none");
    } else {
        img.classList.add("d-none");
        fallback.classList.remove("d-none");
    }
    if (img) {
        img.onerror = function () {
            img.classList.add("d-none");
            fallback.classList.remove("d-none");
        };
        img.onload = function () {
            img.classList.remove("d-none");
            fallback.classList.add("d-none");
        };
    }
}

// Make available for global HTML event usage
window.initAvatarComponent = initAvatarComponent;

// On DOM ready, initialize all avatar wrappers found (robust to errors)
window.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".avatar-image-wrapper").forEach(wrapper => {
        try {
            initAvatarComponent(wrapper);
        } catch (e) {
            console.error("Avatar init failed", e);
        }
    });
});

import { initAvatarCvDownload } from "./cv.js";

// On DOM ready, initialize CV download button (if present)
window.addEventListener("DOMContentLoaded", () => {
    try {
        initAvatarCvDownload(document.getElementById("avatar-cv-download-btn"));
    } catch (e) {
        console.error("[CV Downloader initialization failed:", e);
    }
});
