(function () {
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }
    var pieCharts = [
        {
            id: "about-skill-chart-1",
            label: "Languages",
            data: [50, 30, 20],
            labels: ["JavaScript", "Ruby", "Python"],
            colors: ["#4485FE", "#EA4F52", "#32DCB8"],
        },
        {
            id: "about-skill-chart-2",
            label: "Tools/Tech",
            data: [40, 35, 15, 10],
            labels: ["Docker", "Kubernetes", "Webpack", "Vite"],
            colors: ["#2396ED", "#3759da", "#fbab1d", "#7ba9fa"],
        },
        {
            id: "about-skill-chart-3",
            label: "DevOps",
            data: [60, 30, 10],
            labels: ["CI/CD", "K8s Ops", "Monitoring"],
            colors: ["#5BFFD9", "#6a40c5", "#1e1b2d"],
        },
    ];
    function renderPies() {
        pieCharts.forEach(function (pcfg) {
            var c = document.getElementById(pcfg.id);
            if (c && window.Chart) {
                new Chart(c, {
                    type: "doughnut",
                    data: {
                        labels: pcfg.labels,
                        datasets: [
                            {
                                label: pcfg.label,
                                data: pcfg.data,
                                backgroundColor: pcfg.colors,
                                borderColor: "#22242F",
                                borderWidth: 2,
                            },
                        ],
                    },
                    options: {
                        plugins: {
                            legend: { position: "bottom", labels: { color: "#dbe7fa", font: { size: 12 } } },
                            tooltip: { enabled: true },
                        },
                        cutout: "66%",
                    },
                });
            }
        });
    }
    loadChartJs(function () {
        setTimeout(renderPies, 0);
    });
})();
