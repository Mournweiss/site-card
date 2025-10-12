export function getPastelColor(str) {
    if (!str) return "#c4c6e6";
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = Math.abs(hash) % 360;
    return `hsl(${h}, 57%, 76%)`;
}

export function getInitial(name) {
    if (!name || !(typeof name === "string")) return "?";
    name = name.trim();
    if (!name) return "?";
    return name[0].toUpperCase();
}

export function initAvatarComponent(el) {
    if (!el) return;
    const img = el.querySelector(".avatar-img");
    const fallback = el.querySelector(".avatar-fallback");
    let name = el.dataset.name || "";
    let initial = getInitial(name);
    fallback.textContent = initial;
    fallback.setAttribute("aria-label", initial === "?" ? "Avatar fallback: unknown" : `Avatar fallback: ${initial}`);
    fallback.style.background = getPastelColor(name);

    let hasImage = img && img.src && img.src.length > 6;
    if (hasImage) {
        img.onerror = function () {
            img.classList.add("d-none");
            fallback.classList.remove("d-none");
        };
        img.onload = function () {
            img.classList.remove("d-none");
            fallback.classList.add("d-none");
        };
    } else {
        img.classList.add("d-none");
        fallback.classList.remove("d-none");
    }
}

window.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".avatar-image-wrapper").forEach(wrapper => initAvatarComponent(wrapper));
});
