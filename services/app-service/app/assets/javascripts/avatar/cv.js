/**
 * Initializes a download button for the user CV (PDF file).
 * Adds a click handler which fetches the file,
 * triggers forced download via a temporary <a> tag, and handles browser cleanup.
 *
 * @param {HTMLElement|string} buttonOrSelector - Button element, or selector-string for querySelector.
 * @param {object} [options={}] - Optional configuration.
 * @param {string} [options.filePath="/userdata/CV.pdf"] - Path to CV file.
 * @param {string} [options.fallbackName="CV.pdf"] - Filename for download prompt.
 * @returns {void}
 */
export function initAvatarCvDownload(buttonOrSelector, options = {}) {
    const btn = typeof buttonOrSelector === "string" ? document.querySelector(buttonOrSelector) : buttonOrSelector;
    if (!btn) return;
    const filePath = options.filePath || "/userdata/CV.pdf";
    const fallbackName = options.fallbackName || "CV.pdf";

    /**
     * Fetches, processes, and triggers CV file download.
     * Verifies file exists via HEAD request, fetches as blob, and triggers download.
     * Handles network/unavailability errors by user alert.
     *
     * @returns {Promise<void>}
     */
    async function handleDownload() {
        try {
            // HEAD request to quickly check file exists
            const headResp = await fetch(filePath, { method: "HEAD" });
            if (!headResp.ok) throw new Error("File not found");

            const resp = await fetch(filePath);
            if (!resp.ok) throw new Error("Failed to fetch CV file");
            const blob = await resp.blob();

            // Create a temporary <a> to trigger download
            const a = document.createElement("a");
            a.style.display = "none";
            const url = URL.createObjectURL(blob);
            a.href = url;
            a.download = fallbackName;
            document.body.appendChild(a);
            a.click();

            // Cleanup URL and element after short timeout
            setTimeout(() => {
                URL.revokeObjectURL(url);
                document.body.removeChild(a);
            }, 250);
        } catch (e) {
            alert("Unable to download CV. The file is currently unavailable.");
        }
    }

    // Attach download logic to the target button
    btn.addEventListener(
        "click",
        function (e) {
            e.preventDefault();
            handleDownload();
        },
        false
    );
}
