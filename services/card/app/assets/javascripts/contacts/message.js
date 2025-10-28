async function createMessagePopupMarkup() {
    const res = await fetch("/public/component/message_form");
    if (!res.ok) throw new Error("Cannot load form template");
    const html = await res.text();
    const temp = document.createElement("div");
    temp.innerHTML = html.trim();
    return temp.firstElementChild;
}

async function showMessagePopup() {
    let root = document.getElementById("contacts-message-popup-root");
    if (!root) return;
    root.innerHTML = "";
    const backdrop = document.createElement("div");
    backdrop.id = "popup-backdrop";
    backdrop.tabIndex = -1;
    const modal = document.createElement("div");
    modal.id = "popup-modal";
    const close = document.createElement("button");
    close.className = "popup-close";
    close.innerHTML = "&times;";
    close.type = "button";
    close.addEventListener("click", closeMessagePopup);
    modal.appendChild(close);

    createMessagePopupMarkup().then(form => {
        modal.appendChild(form);
        backdrop.appendChild(modal);
        root.appendChild(backdrop);
        setTimeout(() => close.focus(), 250);
        window.addEventListener("keydown", escHandler, true);

        form.addEventListener("submit", async function (e) {
            e.preventDefault();
            const name = form.elements["name"].value.trim();
            const email = form.elements["email"].value.trim();
            const body = form.elements["body"].value.trim();
            const errorDiv = form.querySelector("#popup-msg-error");
            const successDiv = form.querySelector("#popup-msg-success");
            const loadingDiv = form.querySelector("#popup-msg-loading");
            errorDiv.textContent = "";
            successDiv.textContent = "";
            loadingDiv.style.display = "none";
            if (!name || !email || !body) {
                errorDiv.textContent = "All fields are required";
                return;
            }
            if (!/^[^@\s]+@[^@\s\.]+\.[^@\.\s]+$/.test(email)) {
                errorDiv.textContent = "Invalid email format";
                return;
            }
            loadingDiv.style.display = "block";
            try {
                const resp = await fetch("/api/message", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ name, email, body }),
                });
                const data = await resp.json();
                if (!resp.ok || data.error) {
                    throw new Error(data.error || "Sending failed, try again later");
                }
                successDiv.textContent = "Message sent successfully!";
                form.reset();
            } catch (err) {
                errorDiv.textContent = err.message || "Error occurred";
            } finally {
                loadingDiv.style.display = "none";
            }
        });
    });
}

function closeMessagePopup() {
    let root = document.getElementById("contacts-message-popup-root");
    if (root) root.innerHTML = "";
    window.removeEventListener("keydown", escHandler, true);
}
function escHandler(e) {
    if (e.key === "Escape") closeMessagePopup();
}

export function initContactsMessageBtn() {
    const btn = document.getElementById("contacts-message-btn");
    if (!btn) return;
    btn.addEventListener("click", showMessagePopup);
}

window.addEventListener("DOMContentLoaded", initContactsMessageBtn);
