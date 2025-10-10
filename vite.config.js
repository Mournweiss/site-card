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
                "about-progress": resolve(__dirname, "app/assets/javascripts/about/progress.js"),
                "about-avatar": resolve(__dirname, "app/assets/javascripts/about/avatar.js"),
                "portfolio-showcase": resolve(__dirname, "app/assets/javascripts/portfolio/showcase.js"),
                style: resolve(__dirname, "app/assets/stylesheets/custom.css"),
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
