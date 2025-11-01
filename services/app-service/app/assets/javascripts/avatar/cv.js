export function initAvatarCvDownload(buttonOrSelector, options = {}) {
    const btn = typeof buttonOrSelector === "string" ? document.querySelector(buttonOrSelector) : buttonOrSelector;
    if (!btn) return;
    const filePath = options.filePath || "/userdata/CV.pdf";
    const fallbackName = options.fallbackName || "CV.pdf";

    async function handleDownload() {
        try {
            const headResp = await fetch(filePath, { method: "HEAD" });
            if (!headResp.ok) throw new Error("File not found");

            const resp = await fetch(filePath);
            if (!resp.ok) throw new Error("Failed to fetch CV file");
            const blob = await resp.blob();

            const a = document.createElement("a");
            a.style.display = "none";
            const url = URL.createObjectURL(blob);
            a.href = url;
            a.download = fallbackName;
            document.body.appendChild(a);
            a.click();
            setTimeout(() => {
                URL.revokeObjectURL(url);
                document.body.removeChild(a);
            }, 250);
        } catch (e) {
            alert("Unable to download CV. The file is currently unavailable.");
        }
    }
    btn.addEventListener(
        "click",
        function (e) {
            e.preventDefault();
            handleDownload();
        },
        false
    );
}
