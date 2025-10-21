(function () {
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }
    var radarData;
    try {
        var el = document.getElementById("context-experience");
        radarData = el ? JSON.parse(el.textContent) : {};
    } catch (e) {
        radarData = {};
    }
    var radarOptions = {
        responsive: false,
        maintainAspectRatio: false,
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
        if (radarCtx && window.Chart && radarData && radarData.labels && radarData.datasets) {
            radarCtx.width = 1161;
            radarCtx.height = 845;
            new Chart(radarCtx, { type: "radar", data: radarData, options: radarOptions });
        }
    }
    loadChartJs(function () {
        setTimeout(renderRadar, 0);
    });
})();
