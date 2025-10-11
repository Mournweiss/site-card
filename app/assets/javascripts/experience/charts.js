(function () {
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }
    var radarData = {
        labels: ["Frontend", "Backend", "DevOps", "Mobile", "Data Science", "UI/UX", "Project Mgmt."],
        datasets: [
            {
                label: "Experience",
                data: [95, 78, 60, 30, 40, 83, 69],
                fill: true,
                backgroundColor: "rgba(60,140,255,0.22)",
                borderColor: "#54a3fa",
                pointBackgroundColor: "#3c7fff",
                tension: 0.4,
            },
        ],
    };
    var radarOptions = {
        responsive: true,
        plugins: {
            legend: { display: false },
            tooltip: { enabled: true },
        },
        scales: {
            r: {
                angleLines: { color: "#343b45" },
                grid: { color: "#2b2e35" },
                pointLabels: { color: "#dbe7fa", font: { size: 14, weight: "bold" } },
                ticks: { color: "#b4bacc" },
            },
        },
    };
    function renderRadar() {
        var radarCtx = document.getElementById("about-experience-radar");
        if (radarCtx && window.Chart) {
            new Chart(radarCtx, { type: "radar", data: radarData, options: radarOptions });
        }
    }
    loadChartJs(function () {
        setTimeout(renderRadar, 0);
    });
})();
