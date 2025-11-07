// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Parses all search-string params (euid, token, etc) from the current URL.
 * Converts query parameters into a key-value object.
 *
 * @returns {Object.<string, string>} params - Map from parameter name to value.
 */
function parseSearchParams() {
    const params = {};
    (window.location.search || "")
        .replace(/^[?#]/, "")
        .split("&")
        .forEach(s => {
            if (!s) return;
            const [k, v] = s.split("=");
            params[decodeURIComponent(k)] = decodeURIComponent(v || "");
        });
    return params;
}

// List of required fields for authorization flow: euid, token (from URL), admin_key (input)
const REQUIRED_FIELDS = ["euid", "token", "admin_key"];

// Extract parameters from URL
const params = parseSearchParams();

// Auth form element
const form = document.getElementById("authForm");

// Remove any preexisting hidden inputs to prevent duplicates
[...form.querySelectorAll('input[type="hidden"]')].forEach(e => e.parentNode.removeChild(e));

// Add hidden fields for euid and token from URL
["euid", "token"].forEach(field => {
    let input = document.createElement("input");
    input.type = "hidden";
    input.name = field;
    input.value = params[field] || "";
    form.appendChild(input);
});

const submitBtn = form.querySelector('button[type="submit"]');
const adminKeyInput = form.querySelector('[name="admin_key"]');
const toggleBtn = document.getElementById("toggleAdminKey");
const eyeIcon = document.getElementById("eyeIcon");
if (toggleBtn && adminKeyInput && eyeIcon) {
    toggleBtn.addEventListener("click", function () {
        const showing = adminKeyInput.getAttribute("type") === "password";
        adminKeyInput.setAttribute("type", showing ? "text" : "password");
        eyeIcon.className = showing ? "bi bi-eye-slash" : "bi bi-eye";
    });
}

/**
 * Updates the enabled/disabled state of the form elements (admin key input and submit button)
 * depending on the presence of valid euid and token parameters.
 * Adds a user-facing message if parameters are missing or invalid.
 *
 * @returns {void}
 */
function updateFormState() {
    const hasEuid = !!params["euid"] && params["euid"].length >= 8;
    const hasToken = !!params["token"] && params["token"].length >= 8;
    submitBtn.disabled = !(hasEuid && hasToken);
    if (!(hasEuid && hasToken)) {
        document.getElementById("formMsg").innerHTML =
            '<span class="auth-error">Open this page via Telegram WebApp link only</span>';
        submitBtn.classList.add("disabled");
    } else {
        submitBtn.classList.remove("disabled");
    }
}

// Initialize form state/check on page load
updateFormState();

/**
 * Handles form submission for Telegram WebApp authorization.
 * Submits admin_key (input), euid and token (from URL) via POST to /auth/webapp.
 * Shows status messages for error, progress, and result. Prevents submission if fields are invalid.
 *
 * @param {Event} e - Submit event
 * @returns {Promise<void>}
 */
form.onsubmit = async e => {
    e.preventDefault();
    const euid = params["euid"];
    const token = params["token"];
    const admin_key = adminKeyInput.value;
    if (!euid || euid.length < 8 || !token || token.length < 8) return;
    if (!admin_key || admin_key.length < 4) {
        document.getElementById("formMsg").innerHTML = `<span class='auth-error'>Admin key required<\/span>`;
        return;
    }
    let data = new FormData(form);
    data.set("admin_key", admin_key);
    document.getElementById("formMsg").textContent = "Processing...";
    try {
        let resp = await fetch("/auth/webapp", {
            method: "POST",
            body: data,
        });
        let text = await resp.text();
        const isSuccess = text.includes("success");
        document.getElementById("formMsg").innerHTML = isSuccess
            ? '<span class="auth-success">Authorization successful!</span>'
            : '<span class="auth-error">' + text.replace(/<[^>]*>?/gm, "") + "</span>";

        if (isSuccess) {
            submitBtn.disabled = true;
            adminKeyInput.disabled = true;
            submitBtn.style.display = "none";
            if (window.Telegram && window.Telegram.WebApp && typeof window.Telegram.WebApp.close === "function") {
                setTimeout(() => {
                    window.Telegram.WebApp.close();
                }, 1250);
            } else {
                const fallback = document.createElement("div");
                fallback.className = "auth-msg-fallback";
                fallback.textContent = "You are now authorized. You may close this window";
                document.getElementById("formMsg").appendChild(fallback);
                if (typeof window.Telegram === "undefined" || typeof window.Telegram.WebApp === "undefined") {
                    console.info("Telegram.WebApp API not detected. Not in WebView?");
                }
            }
        }
    } catch (err) {
        document.getElementById("formMsg").textContent = "Error: " + (err.message || err);
    }
};
