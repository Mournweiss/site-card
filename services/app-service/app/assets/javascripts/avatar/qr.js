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
 * Loads popup markup, shows QR popup with QR code and copy-to-clipboard logic.
 * Wires up all necessary event listeners for popup interactivity.
 *
 * @param {string} url - URL to encode in the QR code.
 * @returns {Promise<void>}
 */
async function showQRPopup(url) {
    const contentEl = await getQRPopupMarkup();
    openPopup(contentEl.outerHTML, {
        onClose: () => {}, // No-op here but extension point
    });
    const closeBtn = document.querySelector(".popup-close");
    closeBtn.addEventListener("click", closePopup);
    const qrCanvas = document.getElementById("qr-canvas");
    generateQRCodeCanvas(qrCanvas, url);
    const copyBtn = document.getElementById("qr-copy-btn");

    // Handles copying the rendered QR code to the clipboard
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
 * Generates a QR code in the provided canvas element.
 * Uses computed CSS for color styling.
 *
 * @param {HTMLCanvasElement} el - Canvas for QR code output.
 * @param {string} url - Payload to encode.
 * @returns {void}
 */
function generateQRCodeCanvas(el, url) {
    if (!el) return;
    const rootStyle = getComputedStyle(document.documentElement);
    const qrDark = rootStyle.getPropertyValue("--color-accent") || "#a8b8e2";
    const qrLight = rootStyle.getPropertyValue("--color-surface").trim() || "#23242a";
    QRCode.toCanvas(
        el,
        url,
        {
            width: 480,
            color: {
                dark: qrDark.trim(),
                light: qrLight,
            },
        },
        function (error) {
            if (error) {
                el.parentNode.innerHTML =
                    '<div style="color:#e88;padding:2em">QR generation failed. Try again later.</div>';
            }
        }
    );
}

// Attach QR button initialization after DOM load
window.addEventListener("DOMContentLoaded", initAvatarQRButton);
