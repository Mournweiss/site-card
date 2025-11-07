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

    function getChartSize() {
        if (window.innerWidth <= 600) {
            const w = Math.min(window.innerWidth * 0.92, 440);
            const h = Math.round(w * 0.8);
            const font = Math.max(10, Math.round(w / 37));
            return { w, h, font };
        }
        if (window.innerWidth <= 900) return { w: 520, h: 370, font: 11 };
        return { w: 1161, h: 845, font: 14 };
    }
    let radarChart = null;
    /**
     * Renders the radar chart on target canvas if data and Chart.js present.
     * Chart will visually represent experience/skills by area.
     *
     * @returns {void}
     */
    function renderRadar() {
        var radarCtx = document.getElementById("about-experience-radar");
        if (radarCtx && window.Chart && radarData && radarData.labels && radarData.datasets) {
            const sz = getChartSize();
            radarCtx.width = sz.w;
            radarCtx.height = sz.h;
            const options = JSON.parse(JSON.stringify(radarOptions));
            options.scales.r.pointLabels.font.size = sz.font;
            options.scales.r.ticks.font = { size: Math.max(9, sz.font - 2) };
            if (radarChart) radarChart.destroy();
            radarChart = new Chart(radarCtx, { type: "radar", data: radarData, options });
        }
    }

    // Responsive resize handler with debounced redraw
    let resizeTimeout;
    let lastRadarWidth = window.innerWidth;
    function handleResize() {
        const curW = window.innerWidth;
        if (curW === lastRadarWidth) return;
        lastRadarWidth = curW;
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(renderRadar, 120);
    }
    window.addEventListener("resize", handleResize);

    // Load Chart.js and render the chart once DOM and library are ready
    loadChartJs(function () {
        setTimeout(renderRadar, 0);
    });
})();
