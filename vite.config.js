import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
    root: "app/assets",
    build: {
        outDir: resolve(__dirname, "public/assets"),
        emptyOutDir: true,
        rollupOptions: {
            input: {
                main: resolve(__dirname, "app/assets/javascripts/custom.js"),
                style: resolve(__dirname, "app/assets/stylesheets/custom.css"),
            },
        },
    },
    server: {
        open: false,
    },
});
