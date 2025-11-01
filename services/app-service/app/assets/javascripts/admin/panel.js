const SECTIONS = ["avatar", "about", "experience", "skills", "portfolio", "contacts"];

function sanitize(input) {
    const div = document.createElement("div");
    div.textContent = input == null ? "" : String(input);
    return div.innerHTML;
}

function fillSection(section, data) {
    const el = document.getElementById(`admin-${section}`);
    if (!el) return;
    el.innerHTML = "";
    for (const [k, v] of Object.entries(data || {})) {
        el.innerHTML += `<label>${sanitize(
            k
        )}<input class="form-control mb-2" type="text" data-section="${section}" data-key="${sanitize(
            k
        )}" value="${sanitize(v)}"></label>`;
    }
}

async function loadAllSections() {
    for (const section of SECTIONS) {
        try {
            const r = await fetch(`/admin/api/${section}`, { credentials: "same-origin" });
            if (!r.ok) throw new Error(`Failed to load ${section}`);
            const data = await r.json();
            fillSection(section, data);
        } catch (e) {
            document.getElementById("admin-panel-status").textContent = `Error loading ${section}: ${e.message}`;
        }
    }
}

function gatherAllSections() {
    const payload = {};
    for (const section of SECTIONS) {
        const el = document.getElementById(`admin-${section}`);
        if (!el) continue;
        const fields = el.querySelectorAll("input[data-section]");
        payload[section] = {};
        fields.forEach(input => {
            payload[section][input.dataset.key] = input.value;
        });
    }
    return payload;
}

document.addEventListener("DOMContentLoaded", () => {
    loadAllSections();
    const saveBtn = document.getElementById("admin-save");
    if (saveBtn) {
        saveBtn.addEventListener("click", async () => {
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
        logoutBtn.addEventListener("click", async () => {
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
