// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

// Reference to Telegram WebApp JS interface
let tg = window.Telegram?.WebApp;

// Set hidden field with Telegram init data, if present
// Used for backend validation
document.getElementById("initData").value = tg?.initData || "";

/**
 * Handles the authorization form submission event for Telegram web app login.
 * Prevents default submit, posts form data via AJAX to backend,
 * and displays the result status as a formatted message.
 *
 * @param {Event} e - Form submission event.
 * @returns {Promise<void>} Nothing, but displays UI updates and closes WebApp on success.
 */
document.getElementById("authForm").onsubmit = async e => {
    e.preventDefault();
    let form = e.target;

    // Gather all form data
    let data = new FormData(form);
    document.getElementById("formMsg").textContent = "Processing...";
    try {
        // Send form data as POST (will be handled as multipart/form-data by browser)
        let resp = await fetch("/auth/webapp", {
            method: "POST",
            body: data,
        });
        let text = await resp.text();

        // Display a message depending on result text.
        document.getElementById("formMsg").innerHTML = text.includes("success")
            ? '<span class="auth-success">Authorization successful!</span>'
            : '<span class="auth-error">' + text.replace(/<[^>]*>?/gm, "") + "</span>";

        // If Telegram WebApp present and all OK, close the WebApp UI popup
        if (resp.ok && tg) tg.close();
    } catch (err) {
        document.getElementById("formMsg").textContent = "Error: " + (err.message || err);
    }
};
