import QRCode from "qrcode";

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

function showQRPopup(url) {
    let root = document.getElementById("qr-popup-root");
    if (!root) return;
    root.innerHTML = "";
    const backdrop = document.createElement("div");
    backdrop.id = "popup-backdrop";
    backdrop.tabIndex = -1;
    backdrop.addEventListener("mousedown", function (e) {
        if (e.target === backdrop) closeQRPopup();
    });

    const modal = document.createElement("div");
    modal.id = "popup-modal";

    const close = document.createElement("button");
    close.className = "popup-close";
    close.innerHTML = "&times;";
    close.addEventListener("click", closeQRPopup);
    modal.appendChild(close);

    const qrCanvas = document.createElement("canvas");
    qrCanvas.width = 480;
    qrCanvas.height = 480;
    modal.appendChild(qrCanvas);

    const copyBtn = document.createElement("button");
    copyBtn.className = "sitecard-btn";
    copyBtn.id = "qr-copy-btn";
    copyBtn.type = "button";
    copyBtn.style.marginTop = "1em";
    copyBtn.textContent = "Copy";
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
    modal.appendChild(copyBtn);
    const label = document.createElement("div");
    label.style.marginTop = "1.1em";
    label.style.textAlign = "center";
    label.style.fontSize = "1.08em";
    const rootStyle = getComputedStyle(document.documentElement);
    label.style.color = rootStyle.getPropertyValue("--color-accent") || "#a9b8e3";
    label.textContent = "Scan to open homepage of this site";
    modal.appendChild(label);

    backdrop.appendChild(modal);
    root.appendChild(backdrop);

    setTimeout(() => close.focus(), 250);
    generateQRCodeCanvas(qrCanvas, url);

    window.addEventListener("keydown", escHandler, true);
}
function closeQRPopup() {
    let root = document.getElementById("qr-popup-root");
    if (root) root.innerHTML = "";
    window.removeEventListener("keydown", escHandler, true);
}
function escHandler(e) {
    if (e.key === "Escape") closeQRPopup();
}

window.addEventListener("DOMContentLoaded", initAvatarQRButton);
