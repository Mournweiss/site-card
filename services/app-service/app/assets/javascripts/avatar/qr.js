// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

import QRCode from "qrcode";
import { closePopup, openPopup } from "../common/popup.js";

/**
 * Loads and returns HTML markup for the QR modal popup by fetching server template.
 * Throws error if template cannot be loaded.
 *
 * @returns {Promise<HTMLElement>} DOM element for QR popup content.
 */
async function getQRPopupMarkup() {
    const res = await fetch("/public/component/qr_form");
    if (!res.ok) throw new Error("Cannot load QR popup template");
    const html = await res.text();
    const temp = document.createElement("div");
    temp.innerHTML = html.trim();
    return temp.firstElementChild;
}

/**
 * Initializes QR code button for Avatar section.
 * Adds click handler which opens popup and generates QR code.
 *
 * @returns {void}
 */
export function initAvatarQRButton() {
    const btn = document.getElementById("avatar-qr-btn");
    if (!btn) return;
    btn.addEventListener(
        "click",
        function () {
            showQRPopup(window.location.origin);
        },
        false
    );
}

/**
 * Generates a QR code in the provided canvas with a rounded-rectangle clip.
 *
 * @param {HTMLCanvasElement} el - Canvas for QR code output.
 * @param {string} url - Payload to encode.
 * @param {string} [dark] - Foreground color (hex or CSS color).
 * @param {string} [light] - Background color (hex or CSS color).
 * @returns {void}
 */
function generateQRCodeCanvas(el, url, dark, light) {
    if (!el) return;
    // Use provided or fallback to CSS variables as defaults
    const rootStyle = getComputedStyle(document.documentElement);
    const qrDark = dark || rootStyle.getPropertyValue("--color-accent").trim() || "#a8b8e2";
    const qrLight = light || rootStyle.getPropertyValue("--color-surface").trim() || "#23242a";
    const w = el.width;
    const h = el.height;
    const radius = 58; // px, adjust for visual match

    // Prepare off-screen canvas for qr-paint without clipping quality
    const tmp = document.createElement("canvas");
    tmp.width = w;
    tmp.height = h;

    QRCode.toCanvas(
        tmp,
        url,
        {
            width: w,
            color: {
                dark: qrDark,
                light: qrLight,
            },
        },
        function (error) {
            if (error) {
                el.parentNode.innerHTML =
                    '<div style="color:#e88;padding:2em">QR generation failed. Try again later.</div>';
                return;
            }
            // Draw to visible canvas with rounded clip
            const ctx = el.getContext("2d");
            ctx.clearRect(0, 0, w, h);
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(radius, 0);
            ctx.lineTo(w - radius, 0);
            ctx.arcTo(w, 0, w, radius, radius);
            ctx.lineTo(w, h - radius);
            ctx.arcTo(w, h, w - radius, h, radius);
            ctx.lineTo(radius, h);
            ctx.arcTo(0, h, 0, h - radius, radius);
            ctx.lineTo(0, radius);
            ctx.arcTo(0, 0, radius, 0, radius);
            ctx.closePath();
            ctx.clip();
            ctx.drawImage(tmp, 0, 0, w, h);
            ctx.restore();
        }
    );
}

/**
 * Loads popup markup, shows QR popup with QR code and copy-to-clipboard logic.
 * Integrates dynamic color selectors and re-renders QR on color change.
 *
 * @param {string} url - URL to encode in the QR code.
 * @returns {Promise<void>}
 */
async function showQRPopup(url) {
    const contentEl = await getQRPopupMarkup();
    openPopup(contentEl.outerHTML, {
        onClose: () => {}, // Extension point
    });
    const closeBtn = document.querySelector(".popup-close");
    closeBtn.addEventListener("click", closePopup);
    const qrCanvas = document.getElementById("qr-canvas");
    const darkInput = document.getElementById("qr-color-dark");
    const lightInput = document.getElementById("qr-color-light");
    // Set to initial values (defaults from current CSS variables)
    const rootStyle = getComputedStyle(document.documentElement);
    darkInput.value = cssVarToHex(rootStyle.getPropertyValue("--color-accent"), "#a8b8e2");
    lightInput.value = cssVarToHex(rootStyle.getPropertyValue("--color-surface"), "#23242a");
    let currentDark = darkInput.value;
    let currentLight = lightInput.value;
    generateQRCodeCanvas(qrCanvas, url, currentDark, currentLight);

    // Debounced QR update for color pickers
    let regenTimeout;
    function scheduleRegen() {
        clearTimeout(regenTimeout);
        regenTimeout = setTimeout(() => {
            currentDark = darkInput.value;
            currentLight = lightInput.value;
            generateQRCodeCanvas(qrCanvas, url, currentDark, currentLight);
        }, 80);
    }
    darkInput.addEventListener("input", scheduleRegen);
    lightInput.addEventListener("input", scheduleRegen);

    const copyBtn = document.getElementById("qr-copy-btn");
    copyBtn.addEventListener("click", async function () {
        try {
            qrCanvas.toBlob(async function (blob) {
                if (!blob) return;
                try {
                    await navigator.clipboard.write([new window.ClipboardItem({ "image/png": blob })]);
                    const oldText = copyBtn.textContent;
                    copyBtn.textContent = "Copied!";
                    copyBtn.disabled = true;
                    setTimeout(() => {
                        copyBtn.textContent = oldText;
                        copyBtn.disabled = false;
                    }, 1600);
                } catch (err) {
                    copyBtn.textContent = "Error";
                    setTimeout(() => (copyBtn.textContent = "Copy"), 1800);
                }
            }, "image/png");
        } catch (e) {
            copyBtn.textContent = "Error";
            setTimeout(() => (copyBtn.textContent = "Copy"), 1800);
        }
    });
}

/**
 * Utility: Convert CSS variable color (hex or rgb(a)) to hex string, fallback if invalid.
 * @param {string} cssColor
 * @param {string} fallback
 * @returns {string}
 */
function cssVarToHex(cssColor, fallback) {
    if (!cssColor) return fallback;
    cssColor = cssColor.trim();
    // Hex direct
    if (cssColor.startsWith("#") && (cssColor.length === 7 || cssColor.length === 4)) return cssColor;
    // Try rgb/rgba
    const rgbMatch = cssColor.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
    if (rgbMatch) {
        const r = Number(rgbMatch[1]);
        const g = Number(rgbMatch[2]);
        const b = Number(rgbMatch[3]);
        return (
            "#" +
            [r, g, b]
                .map(v => {
                    const str = v.toString(16);
                    return str.length < 2 ? "0" + str : str;
                })
                .join("")
        );
    }
    // HSL, named, etc., fallback
    return fallback;
}

// Attach QR button initialization after DOM load
window.addEventListener("DOMContentLoaded", initAvatarQRButton);
