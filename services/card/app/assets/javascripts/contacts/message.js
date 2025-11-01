import { openPopup, closePopup } from "../common/popup.js";

async function createMessagePopupMarkup() {
    const res = await fetch("/public/component/message_form");
    if (!res.ok) throw new Error("Cannot load form template");
    const html = await res.text();
    const temp = document.createElement("div");
    temp.innerHTML = html.trim();
    return temp.firstElementChild;
}

async function showMessagePopup() {
    const form = await createMessagePopupMarkup();
    const contentHtml = `
        <button class="popup-close" type="button">&times;</button>
        ${form.outerHTML}
    `;
    openPopup(contentHtml);
    const closeBtn = document.querySelector(".popup-close");
    closeBtn.addEventListener("click", closePopup);
    const insertedForm = document.querySelector("#popup-modal form");
    if (insertedForm) {
        insertedForm.addEventListener("submit", async function (e) {
            e.preventDefault();
            const name = insertedForm.elements["name"].value.trim();
            const email = insertedForm.elements["email"].value.trim();
            const body = insertedForm.elements["body"].value.trim();
            const errorDiv = insertedForm.querySelector("#popup-msg-error");
            const successDiv = insertedForm.querySelector("#popup-msg-success");
            const loadingDiv = insertedForm.querySelector("#popup-msg-loading");
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
                insertedForm.reset();
            } catch (err) {
                errorDiv.textContent = err.message || "Error occurred";
            } finally {
                loadingDiv.style.display = "none";
            }
        });
    }
}

export function initContactsMessageBtn() {
    const btn = document.getElementById("contacts-message-btn");
    if (!btn) return;
    btn.addEventListener("click", showMessagePopup);
}

window.addEventListener("DOMContentLoaded", initContactsMessageBtn);
