import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
    root: "app/assets",
    build: {
        outDir: resolve(__dirname, "public/assets"),
        assetsDir: ".",
        emptyOutDir: true,
        rollupOptions: {
            input: {
                "avatar-avatar": resolve(__dirname, "app/assets/javascripts/avatar/avatar.js"),
                "avatar-base": resolve(__dirname, "app/assets/stylesheets/avatar/base.css"),
                "avatar-image": resolve(__dirname, "app/assets/stylesheets/avatar/image.css"),
                "avatar-info": resolve(__dirname, "app/assets/stylesheets/avatar/info.css"),
                "avatar-buttons": resolve(__dirname, "app/assets/stylesheets/avatar/buttons.css"),
                "experience-charts": resolve(__dirname, "app/assets/javascripts/experience/charts.js"),
                "skills-charts": resolve(__dirname, "app/assets/javascripts/skills/charts.js"),
                "skills-base": resolve(__dirname, "app/assets/stylesheets/skills/base.css"),
                "portfolio-rail": resolve(__dirname, "app/assets/stylesheets/portfolio/rail.css"),
                "portfolio-arrows": resolve(__dirname, "app/assets/stylesheets/portfolio/arrows.css"),
                "portfolio-card": resolve(__dirname, "app/assets/stylesheets/portfolio/card.css"),
                "portfolio-content": resolve(__dirname, "app/assets/stylesheets/portfolio/content.css"),
                "portfolio-showcase": resolve(__dirname, "app/assets/javascripts/portfolio/showcase.js"),
                about: resolve(__dirname, "app/assets/stylesheets/about/about.css"),
                experience: resolve(__dirname, "app/assets/stylesheets/experience/experience.css"),
                "contacts-base": resolve(__dirname, "app/assets/stylesheets/contacts/base.css"),
                "contacts-icons": resolve(__dirname, "app/assets/stylesheets/contacts/icons.css"),
                common: resolve(__dirname, "app/assets/stylesheets/common/common.css"),
                "common-fadeinup": resolve(__dirname, "app/assets/javascripts/common/fadeinup.js"),
                "common-uisurface-contrast": resolve(__dirname, "app/assets/javascripts/common/uisurface-contrast.js"),
                "common-scroll-center": resolve(__dirname, "app/assets/javascripts/common/scroll-center.js"),
                "footer-base": resolve(__dirname, "app/assets/stylesheets/footer/base.css"),
                "navbar-base": resolve(__dirname, "app/assets/stylesheets/navbar/base.css"),
                "navbar-toggle": resolve(__dirname, "app/assets/javascripts/navbar/toggle.js"),
                "admin-panel": resolve(__dirname, "app/assets/javascripts/admin/panel.js"),
            },
            output: {
                entryFileNames: "[name].js",
                assetFileNames: "[name].css",
            },
        },
    },
    server: {
        open: false,
    },
});
