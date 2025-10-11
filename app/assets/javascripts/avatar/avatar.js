(function () {
    const avatarContainer = document.getElementById("avatar");
    if (!avatarContainer) return;
    function extractInitial() {
        const nameElem = document.querySelector(".name");
        if (nameElem && nameElem.textContent.trim().length > 0) {
            const match = nameElem.textContent.trim().match(/[A-Za-zА-Яа-яЁё]/);
            if (match) {
                return match[0].toUpperCase();
            }
        }
        return "?";
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
        img.className = "avatar rounded-circle shadow";
        avatarContainer.appendChild(img);
    };
    testImg.onerror = function () {
        clearAvatarContainer();
        const initial = extractInitial();
        avatarContainer.style.background = randomPastel();
        avatarContainer.style.display = "flex";
        avatarContainer.style.justifyContent = "center";
        avatarContainer.style.alignItems = "center";
        avatarContainer.style.fontSize = "3.8rem";
        avatarContainer.style.fontWeight = "bold";
        avatarContainer.style.color = "#fff";
        avatarContainer.textContent = initial;
    };
    try {
        testImg.src = "/avatar.jpg";
    } catch (e) {
        testImg.onerror();
    }
})();
