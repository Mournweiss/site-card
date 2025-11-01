let tg = window.Telegram?.WebApp;
document.getElementById("initData").value = tg?.initData || "";

document.getElementById("authForm").onsubmit = async e => {
    e.preventDefault();
    let form = e.target;
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
        if (resp.ok && tg) tg.close();
    } catch (err) {
        document.getElementById("formMsg").textContent = "Error: " + (err.message || err);
    }
};
