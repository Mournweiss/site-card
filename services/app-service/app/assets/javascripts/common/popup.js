// Module-level references for single open popup state
let popupBackdrop = null;
let popupOnClose = null;

/**
 * Opens a modal popup with specified HTML content.
 * Installs backdrop, wires up close/esc/focus logic.
 *
 * @param {string} contentHtml - HTML string to be injected into popup modal.
 * @param {object} [opts={}] - Optional settings.
 * @param {function} [opts.onClose] - Callback executed when popup is closed.
 * @returns {void}
 */
export function openPopup(contentHtml, opts = {}) {
    closePopup(); // Always close previous if open
    popupOnClose = typeof opts.onClose === "function" ? opts.onClose : null;
    popupBackdrop = document.createElement("div");
    popupBackdrop.id = "popup-backdrop";
    popupBackdrop.tabIndex = -1;
    popupBackdrop.innerHTML = `<div id="popup-modal">${contentHtml}</div>`;

    // Close popup on click outside modal (backdrop click)
    popupBackdrop.addEventListener("mousedown", function (e) {
        if (e.target === popupBackdrop) closePopup();
    });
    document.body.appendChild(popupBackdrop);
    document.body.style.overflow = "hidden";

    // Allow ESC-key closing
    window.addEventListener("keydown", popupEscHandler, true);

    // If a ".popup-close" exists, focus on it for accessibility
    const closeBtn = popupBackdrop.querySelector(".popup-close");
    if (closeBtn && typeof closeBtn.focus === "function") setTimeout(() => closeBtn.focus(), 200);
}

/**
 * Closes the popup modal (if present), restores scroll, calls onClose handler.
 *
 * @returns {void}
 */
export function closePopup() {
    if (popupBackdrop) {
        popupBackdrop.remove();
        popupBackdrop = null;
    }
    document.body.style.overflow = "";
    window.removeEventListener("keydown", popupEscHandler, true);
    if (typeof popupOnClose === "function") {
        popupOnClose();
        popupOnClose = null;
    }
}

/**
 * Internal keyboard handler: Closes popup on Escape key.
 *
 * @param {KeyboardEvent} e - Keydown event.
 * @returns {void}
 */
function popupEscHandler(e) {
    if (e.key === "Escape") closePopup();
}
