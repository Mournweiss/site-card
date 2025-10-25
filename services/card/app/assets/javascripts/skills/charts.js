(function () {
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }
    var pieCharts;
    try {
        var el = document.getElementById("context-skills");
        pieCharts = el ? JSON.parse(el.textContent) : [];
    } catch (e) {
        pieCharts = [];
    }
    function renderPies() {
        (pieCharts || []).forEach(function (pcfg) {
            var c = document.getElementById(pcfg.id);
            if (c && window.Chart) {
                c.width = pcfg.width || 378;
                c.height = pcfg.height || 378;
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
