(function () {
    const avatarContainer = document.getElementById("about-avatar");
    if (!avatarContainer) return;
    function extractInitial() {
        const nameElem = document.querySelector(".about-name h2:nth-child(2)");
        if (nameElem && nameElem.textContent.trim().length > 0) {
            return nameElem.textContent.trim()[0].toUpperCase();
        }
        throw new Error("Can't extract initial: .about-name h2:nth-child(2) is missing or empty.");
    }
    function randomPastel() {
        const hue = Math.floor(Math.random() * 360);
        return `hsl(${hue},82%,78%)`;
    }
    function clearAvatarContainer() {
        avatarContainer.innerHTML = "";
        avatarContainer.removeAttribute("style");
    }
    const testImg = new window.Image();
    testImg.onload = function () {
        clearAvatarContainer();
        const img = document.createElement("img");
        img.src = "/avatar.jpg";
        img.alt = "Profile Photo";
        img.width = 160;
        img.height = 160;
        img.className = "about-avatar rounded-circle shadow";
        avatarContainer.appendChild(img);
    };
    testImg.onerror = function () {
        clearAvatarContainer();
        try {
            const initial = extractInitial();
            avatarContainer.style.background = randomPastel();
            avatarContainer.style.display = "flex";
            avatarContainer.style.justifyContent = "center";
            avatarContainer.style.alignItems = "center";
            avatarContainer.style.fontSize = "3.8rem";
            avatarContainer.style.fontWeight = "bold";
            avatarContainer.style.color = "#fff";
            avatarContainer.textContent = initial;
        } catch (err) {
            console.error("Cannot fallback avatar: " + err.message);
            throw err;
        }
    };
    try {
        testImg.src = "/avatar.jpg";
    } catch (e) {
        testImg.onerror();
    }
})();
