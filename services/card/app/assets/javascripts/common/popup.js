let popupBackdrop = null;
let popupOnClose = null;

export function openPopup(contentHtml, opts = {}) {
    closePopup();
    popupOnClose = typeof opts.onClose === "function" ? opts.onClose : null;
    popupBackdrop = document.createElement("div");
    popupBackdrop.id = "popup-backdrop";
    popupBackdrop.tabIndex = -1;
    popupBackdrop.innerHTML = `<div id="popup-modal">${contentHtml}</div>`;
    popupBackdrop.addEventListener("mousedown", function (e) {
        if (e.target === popupBackdrop) closePopup();
    });
    document.body.appendChild(popupBackdrop);
    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", popupEscHandler, true);
    const closeBtn = popupBackdrop.querySelector(".popup-close");
    if (closeBtn && typeof closeBtn.focus === "function") setTimeout(() => closeBtn.focus(), 200);
}

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

function popupEscHandler(e) {
    if (e.key === "Escape") closePopup();
}
