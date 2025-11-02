// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

/**
 * Automatically adjusts text contrast for .ui-surface elements based on the computed background image region.
 * Uses canvas to analyze background behind each surface, calculates average luminance,
 * and toggles --light-text/--dark-text utility classes for accessibility.
 *
 * Only runs if at least one .ui-surface and a background image are present.
 */
(function () {
    var surfaces = document.querySelectorAll(".ui-surface");
    var bgUrl = getBackgroundImageUrl();
    if (!surfaces.length || !bgUrl) return;
    var img = new window.Image();
    img.crossOrigin = "anonymous";

    /**
     * Main onload: samples each surface area using a temporary canvas,
     * analyzes average luminance, and applies best text contrast class.
     */
    img.onload = function () {
        surfaces.forEach(function (surf) {
            try {
                var box = surf.getBoundingClientRect();
                var can = document.createElement("canvas");
                can.width = Math.round(box.width);
                can.height = Math.round(box.height);
                var ctx = can.getContext("2d");
                ctx.drawImage(img, box.left, box.top, box.width, box.height, 0, 0, box.width, box.height);
                var data = ctx.getImageData(0, 0, can.width, can.height).data;
                var total = 0,
                    count = 0;

                // For each pixel, compute luminance (Y) and build running average.
                for (var i = 0; i < data.length; i += 4) {
                    var r = data[i],
                        g = data[i + 1],
                        b = data[i + 2];
                    var y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
                    total += y;
                    count++;
                }
                var avgY = count ? total / count : 0;

                // Remove both classes, then conditionally apply based on luminance threshold
                surf.classList.remove("ui-surface--light-text", "ui-surface--dark-text");
                if (avgY < 140) {
                    surf.classList.add("ui-surface--light-text");
                } else {
                    surf.classList.add("ui-surface--dark-text");
                }
            } catch (e) {}
        });
    };
    img.src = bgUrl;

    /**
     * Extracts the URL of the current body's background image, if defined in CSS.
     *
     * @returns {string|null} The background image URL or null.
     */
    function getBackgroundImageUrl() {
        var style = window.getComputedStyle(document.body),
            url = style.backgroundImage;
        if (!url || url === "none") return null;
        var match = url.match(/url\(["']?(.*?)["']?\)/);
        return match ? match[1] : null;
    }

    // On window resize, retrigger image analysis for updated surface dimensions
    window.addEventListener("resize", function () {
        img.src = bgUrl;
    });
})();
