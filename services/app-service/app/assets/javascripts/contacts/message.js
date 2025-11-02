// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

import { closePopup, openPopup } from "../common/popup.js";

/**
 * Loads and returns the message form HTML as DOM node from server-side template.
 * Throws error if template cannot be loaded successfully.
 *
 * @returns {Promise<HTMLElement>} Popup content for message form.
 */
async function createMessagePopupMarkup() {
    const res = await fetch("/public/component/message_form");
    if (!res.ok) throw new Error("Cannot load form template");
    const html = await res.text();
    const temp = document.createElement("div");
    temp.innerHTML = html.trim();
    return temp.firstElementChild;
}

/**
 * Opens the message popup form, wires up close and form submit handlers.
 * Handles validation, AJAX message sending and UI status/error feedback.
 *
 * @returns {Promise<void>} Resolves after popup and handlers are set up.
 */
async function showMessagePopup() {
    const form = await createMessagePopupMarkup();
    const contentHtml = `
        <button class="popup-close" type="button">&times;</button>
        ${form.outerHTML}
    `;
    openPopup(contentHtml);
    const closeBtn = document.querySelector(".popup-close");
    closeBtn.addEventListener("click", closePopup);

    // Find inserted form within popup for binding submit handler
    const insertedForm = document.querySelector("#popup-modal form");
    if (insertedForm) {
        insertedForm.addEventListener("submit", async function (e) {
            e.preventDefault();

            // Extract values and UI result elements
            const name = insertedForm.elements["name"].value.trim();
            const email = insertedForm.elements["email"].value.trim();
            const body = insertedForm.elements["body"].value.trim();
            const errorDiv = insertedForm.querySelector("#popup-msg-error");
            const successDiv = insertedForm.querySelector("#popup-msg-success");
            const loadingDiv = insertedForm.querySelector("#popup-msg-loading");
            errorDiv.textContent = "";
            successDiv.textContent = "";
            loadingDiv.style.display = "none";

            // Required field validation
            if (!name || !email || !body) {
                errorDiv.textContent = "All fields are required";
                return;
            }

            // Basic email format validation
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

/**
 * Initializes the contacts message button if it exists, binding click to open popup message form.
 *
 * @returns {void}
 */
export function initContactsMessageBtn() {
    const btn = document.getElementById("contacts-message-btn");
    if (!btn) return;
    btn.addEventListener("click", showMessagePopup);
}

// Auto-attach initialization on DOMContentLoaded
window.addEventListener("DOMContentLoaded", initContactsMessageBtn);
