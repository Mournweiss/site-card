// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

// Parse all search-string params (uid, token, etc) from the URL
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

const REQUIRED_FIELDS = ["euid", "token"];
const params = parseSearchParams();
const form = document.getElementById("authForm");

[...form.querySelectorAll('input[type="hidden"]')].forEach(e => e.parentNode.removeChild(e));

// Fill form with hidden fields for all parameters
REQUIRED_FIELDS.forEach(field => {
    let input = document.createElement("input");
    input.type = "hidden";
    input.name = field;
    input.value = params[field] || "";
    form.appendChild(input);
});

// Warning if any param is missing/invalid. Both euid (encrypted user ID) and token (JWT/nonce) must be present.
const missing = REQUIRED_FIELDS.find(f => !params[f] || params[f].length < 8);
if (missing) {
    const msg = document.createElement("div");
    msg.innerHTML = `<span class="auth-error">Authorization is only available via a secure Telegram WebApp button with valid session parameters (euid and token). (Missing: <b>${missing}</b>)<\/span>`;
    form.insertBefore(msg, document.getElementById("formMsg"));
}

form.onsubmit = async e => {
    e.preventDefault();
    for (const field of REQUIRED_FIELDS) {
        const v = form.querySelector(`[name='${field}']`)?.value;
        if (!v || v.length < 8) {
            document.getElementById(
                "formMsg"
            ).innerHTML = `<span class='auth-error'>Missing or invalid field: ${field}. Authorization is not possible.<\/span>`;
            return;
        }
    }

    // Submit parameters from hidden fields
    let data = new FormData(form);
    document.getElementById("formMsg").textContent = "Processing...";
    try {
        let resp = await fetch("/auth/webapp", {
            method: "POST",
            body: data,
        });
        let text = await resp.text();
        document.getElementById("formMsg").innerHTML = text.includes("success")
            ? '<span class="auth-success">Authorization successful!</span>'
            : '<span class="auth-error">' + text.replace(/<[^>]*>?/gm, "") + "</span>";
    } catch (err) {
        document.getElementById("formMsg").textContent = "Error: " + (err.message || err);
    }
};
