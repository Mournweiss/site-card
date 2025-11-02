// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Loads and renders experience radar chart for the portfolio section.
 * Dynamically imports Chart.js from CDN only when needed.
 * Expects context data in #context-experience in JSON (labels, datasets).
 */
(function () {
    /**
     * Asynchronously loads Chart.js from CDN if not already present on window.
     * Calls callback after script is loaded or Chart is already present.
     *
     * @param {function} callback - Function to call after Chart.js is available.
     * @returns {void}
     */
    function loadChartJs(callback) {
        if (window.Chart) return callback();
        var script = document.createElement("script");
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
        script.onload = callback;
        document.head.appendChild(script);
    }

    // Data to be used for radar chart; loaded from a script tag or inline json
    var radarData;
    try {
        var el = document.getElementById("context-experience");
        radarData = el ? JSON.parse(el.textContent) : {};
    } catch (e) {
        radarData = {};
    }

    // Chart.js radar options, appearance and accessibility settings
    var radarOptions = {
        responsive: true,
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

    /**
     * Renders the radar chart on target canvas if data and Chart.js present.
     * Chart will visually represent experience/skills by area.
     *
     * @returns {void}
     */
    function renderRadar() {
        var radarCtx = document.getElementById("about-experience-radar");
        if (radarCtx && window.Chart && radarData && radarData.labels && radarData.datasets) {
            radarCtx.width = 1161; // force fixed size for consistent render
            radarCtx.height = 845;
            new Chart(radarCtx, { type: "radar", data: radarData, options: radarOptions });
        }
    }

    // Load Chart.js and render the chart once DOM and library are ready
    loadChartJs(function () {
        setTimeout(renderRadar, 0);
    });
})();
