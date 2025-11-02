// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Renders one or more skill pie charts using Chart.js, per provided configs.
 * Chart configs are expected as an array of objects (see format below) inside #context-skills.
 * Dynamically loads Chart.js from CDN if not already present.
 *
 * Config example for each chart:
 *   {
 *     id: 'canvas-id', width: 378, height: 378,
 *     label: 'Some skills', labels: [...], data: [...], colors: [...]
 *   }
 */
(function () {
    /**
     * Asynchronously loads Chart.js from CDN if not already present.
     * Calls callback after ready.
     *
     * @param {function} callback - Triggered when Chart.js is ready.
     * @returns {void}
     */
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }

    // Chart configs array, parsed from hidden context JSON
    var pieCharts;
    try {
        var el = document.getElementById("context-skills");
        pieCharts = el ? JSON.parse(el.textContent) : [];
    } catch (e) {
        pieCharts = [];
    }

    /**
     * Iterates over config objects, rendering doughnut charts with Chart.js into referenced canvases.
     * Safely no-ops if Chart.js or canvas not found.
     *
     * Each chart config object must have keys: id, label, labels, data, colors, (width, height optional).
     */
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

    // Asynchronously load Chart.js and render pies after DOM is ready
    loadChartJs(function () {
        setTimeout(renderPies, 0);
    });
})();
