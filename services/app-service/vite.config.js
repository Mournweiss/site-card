// SPDX-FileCopyrightText: 2025 Maxim Selin <selinmax05@mail.ru>
//
// SPDX-License-Identifier: MIT

// Vite build and asset pipeline for SiteCard
import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
    // Root directory for all asset building
    root: "app/assets",
    build: {
        // Output dir is public so it is directly http-served by backend/static
        outDir: resolve(__dirname, "public/assets"),
        assetsDir: ".",
        emptyOutDir: true,
        // JS and CSS entry points (chunk per asset for easy backend include)
        rollupOptions: {
            input: {
                // Each distinct feature/section as a separate build output
                "avatar-avatar": resolve(__dirname, "app/assets/javascripts/avatar/avatar.js"),
                "avatar-base": resolve(__dirname, "app/assets/stylesheets/avatar/base.css"),
                "avatar-image": resolve(__dirname, "app/assets/stylesheets/avatar/image.css"),
                "avatar-info": resolve(__dirname, "app/assets/stylesheets/avatar/info.css"),
                "avatar-buttons": resolve(__dirname, "app/assets/stylesheets/avatar/buttons.css"),
                "avatar-cv": resolve(__dirname, "app/assets/javascripts/avatar/cv.js"),
                "avatar-qr": resolve(__dirname, "app/assets/javascripts/avatar/qr.js"),
                "avatar-qr-style": resolve(__dirname, "app/assets/stylesheets/avatar/qr.css"),
                "contacts-message": resolve(__dirname, "app/assets/javascripts/contacts/message.js"),
                "experience-charts": resolve(__dirname, "app/assets/javascripts/experience/charts.js"),
                "skills-charts": resolve(__dirname, "app/assets/javascripts/skills/charts.js"),
                "skills-base": resolve(__dirname, "app/assets/stylesheets/skills/base.css"),
                "portfolio-rail": resolve(__dirname, "app/assets/stylesheets/portfolio/rail.css"),
                "portfolio-arrows": resolve(__dirname, "app/assets/stylesheets/portfolio/arrows.css"),
                "portfolio-card": resolve(__dirname, "app/assets/stylesheets/portfolio/card.css"),
                "portfolio-content": resolve(__dirname, "app/assets/stylesheets/portfolio/content.css"),
                "portfolio-showcase": resolve(__dirname, "app/assets/javascripts/portfolio/showcase.js"),
                "about-base": resolve(__dirname, "app/assets/stylesheets/about/base.css"),
                "experience-base": resolve(__dirname, "app/assets/stylesheets/experience/base.css"),
                "contacts-base": resolve(__dirname, "app/assets/stylesheets/contacts/base.css"),
                "contacts-icons": resolve(__dirname, "app/assets/stylesheets/contacts/icons.css"),
                common: resolve(__dirname, "app/assets/stylesheets/common/common.css"),
                "common-fadeinup": resolve(__dirname, "app/assets/javascripts/common/fadeinup.js"),
                "common-uisurface-contrast": resolve(__dirname, "app/assets/javascripts/common/uisurface-contrast.js"),
                "common-scroll-center": resolve(__dirname, "app/assets/javascripts/common/scroll-center.js"),
                "common-popup": resolve(__dirname, "app/assets/javascripts/common/popup.js"),
                "footer-base": resolve(__dirname, "app/assets/stylesheets/footer/base.css"),
                "footer-title": resolve(__dirname, "app/assets/javascripts/footer/title.js"),
                "navbar-base": resolve(__dirname, "app/assets/stylesheets/navbar/base.css"),
                "navbar-toggle": resolve(__dirname, "app/assets/javascripts/navbar/toggle.js"),
                "admin-panel": resolve(__dirname, "app/assets/javascripts/admin/panel.js"),
                "cookie-notice": resolve(__dirname, "app/assets/javascripts/cookie/notice.js"),
                "cookie-notice-style": resolve(__dirname, "app/assets/stylesheets/cookie/notice.css"),
                popup: resolve(__dirname, "app/assets/stylesheets/common/popup.css"),
                "auth-base": resolve(__dirname, "app/assets/stylesheets/auth/base.css"),
                "auth-webapp": resolve(__dirname, "app/assets/javascripts/auth/webapp.js"),
            },
            // Output files match input chunknames for easy backend mapping
            output: {
                entryFileNames: "[name].js",
                assetFileNames: "[name].css",
            },
        },
    },
    server: {
        open: false, // Do not auto-open browser
    },
});
