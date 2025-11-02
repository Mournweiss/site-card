// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

// List of manageable admin sections
const SECTIONS = ["avatar", "about", "experience", "skills", "portfolio", "contacts"];

/**
 * Safely sanitizes a string for HTML injection.
 *
 * @param {string|null} input - Value to sanitize.
 * @returns {string} Sanitized string safe for innerHTML assignment.
 */
function sanitize(input) {
    const div = document.createElement("div");
    div.textContent = input == null ? "" : String(input);
    return div.innerHTML;
}

/**
 * Populates a section's form inputs with key-value data.
 *
 * @param {string} section - Section name (should be one of SECTIONS).
 * @param {object} data - Key/value pairs for this section. Keys are field names.
 * @returns {void}
 */
function fillSection(section, data) {
    const el = document.getElementById(`admin-${section}`);

    // If section root element is missing, silently exit
    if (!el) return;
    el.innerHTML = "";

    // Create labeled input for each key/value present in loaded data
    for (const [k, v] of Object.entries(data || {})) {
        el.innerHTML += `<label>${sanitize(
            k
        )}<input class="form-control mb-2" type="text" data-section="${section}" data-key="${sanitize(
            k
        )}" value="${sanitize(v)}"></label>`;
    }
}

/**
 * Loads every editable section from the server.
 * Uses fetch API to obtain current data for each admin section.
 * If fetch fails, displays error for each section independently.
 *
 * @returns {Promise<void>} Resolves when all sections have been attempted.
 */
async function loadAllSections() {
    for (const section of SECTIONS) {
        try {
            // Always use same-origin credentials for admin endpoints
            const r = await fetch(`/admin/api/${section}`, { credentials: "same-origin" });
            if (!r.ok) throw new Error(`Failed to load ${section}`);
            const data = await r.json();
            fillSection(section, data);
        } catch (e) {
            document.getElementById("admin-panel-status").textContent = `Error loading ${section}: ${e.message}`;
        }
    }
}

/**
 * Collects all input field data currently visible in admin sections.
 * Returns a structured object to be sent for saving.
 *
 * @returns {object} Dictionary mapping section name to its {field: value} pairs.
 */
function gatherAllSections() {
    const payload = {};
    for (const section of SECTIONS) {
        const el = document.getElementById(`admin-${section}`);
        if (!el) continue;
        const fields = el.querySelectorAll("input[data-section]");
        payload[section] = {};

        // Each key is stored as data-key attribute on the input
        fields.forEach(input => {
            payload[section][input.dataset.key] = input.value;
        });
    }
    return payload;
}

// When DOM is ready, setup all section loading, save and logout event listeners
/**
 * Main admin panel initialization for editable sections and actions.
 * Loads initial data, wires up save/logout handlers
 */
document.addEventListener("DOMContentLoaded", () => {
    loadAllSections();
    const saveBtn = document.getElementById("admin-save");
    if (saveBtn) {
        // Save button handler: gather all form data and send to server
        saveBtn.addEventListener("click", async () => {
            /**
             * Gathers, validates, and saves current admin panel data via POST request.
             * Handles and displays success/failure.
             */
            const payload = gatherAllSections();
            document.getElementById("admin-panel-status").textContent = "Saving...";
            try {
                const r = await fetch("/admin/api/update", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    credentials: "same-origin",
                    body: JSON.stringify(payload),
                });
                if (!r.ok) throw new Error(`Update failed (${r.status})`);
                document.getElementById("admin-panel-status").textContent = "Update successful.";
            } catch (e) {
                document.getElementById("admin-panel-status").textContent = "Error: " + e.message;
            }
        });
    }
    const logoutBtn = document.getElementById("admin-logout");
    if (logoutBtn) {
        // Logout via POST, handle server redirect or send home
        logoutBtn.addEventListener("click", async () => {
            /**
             * Logs out the current admin session and redirects appropriately.
             * Errors redirect to homepage for security.
             */
            try {
                const r = await fetch("/admin/logout", { method: "POST", credentials: "same-origin" });
                if (r.redirected) {
                    window.location = r.url;
                } else {
                    window.location = "/";
                }
            } catch (e) {
                window.location = "/";
            }
        });
    }
});
