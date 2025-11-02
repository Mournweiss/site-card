<div align="center">

# App Service

Ruby-based web application and API service for SiteCard project

[![Ruby](https://img.shields.io/badge/Ruby-3.3.0-CC342D?style=for-the-badge&logo=ruby)](https://www.ruby-lang.org/)
[![Rack](https://img.shields.io/badge/Rack-3.2-red?style=for-the-badge&logo=ruby)](https://rack.github.io/)
[![Webrick](https://img.shields.io/badge/Webrick-1.9-E96A10?style=for-the-badge&logo=ruby)](https://rubygems.org/gems/webrick)
[![Bundler](https://img.shields.io/badge/Bundler-2.x-990000?style=for-the-badge&logo=ruby)](https://bundler.io/)
[![pg](https://img.shields.io/badge/pg-1.5.x-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://rubygems.org/gems/pg)
[![dotenv](https://img.shields.io/badge/dotenv-3.0-green?style=for-the-badge&logo=dotenv&logoColor=white)](https://github.com/bkeepers/dotenv)
[![gRPC](https://img.shields.io/badge/gRPC-1.76.0-blueviolet?style=for-the-badge&logo=grpc)](https://grpc.io/)
[![Protobuf](https://img.shields.io/badge/Protobuf-3.25.8-FFCC00?style=for-the-badge&logo=protocol-buffers&logoColor=black)](https://developers.google.com/protocol-buffers)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?style=for-the-badge&logo=node.js)](https://nodejs.org/)
[![Vite](https://img.shields.io/badge/Vite-7.1.9-646cff?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev/)
[![nginx](https://img.shields.io/badge/nginx-1.x-brightgreen?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![ruby:3.3-slim](https://img.shields.io/badge/ruby:3.3--slim-CC342D?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/_/ruby)
[![node:20-slim](https://img.shields.io/badge/node:20--slim-339933?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/_/node)

</div>

## Overview

App Service is the core user-facing application and API for the SiteCard platform. Implemented in Ruby (Rack) and deployed as a containerized microservice, it provides:

-   Dynamic profile and portfolio web pages (public and admin UI)
-   Secure admin authentication (optional Telegram WebApp support)
-   REST-style and gRPC interfaces for data and notification integration
-   PostgreSQL data storage, with persistent models for profile, experience, skills, and more
-   Modern interactive frontend bundled by Vite (Node.js), supporting editable sections, admin panel, and responsive design
-   Integrated build pipeline with Docker Compose / Podman Compose orchestration

### Tech Stack

-   **Ruby 3.3** (Backend, Rack, Sinatra-esque style)
-   **Rack** (Rack web server/abstraction)
-   **Webrick** (WEBrick HTTP server for local/dev use)
-   **Bundler** (gem management)
-   **pg** (PostgreSQL integration)
-   **dotenv** (env configuration)
-   **gRPC & Protobuf** (API, inter-service comms)
-   **Node.js 20** (frontend asset build)
-   **Vite 7** (modern JS/CSS bundling)
-   **nginx** (static files/proxy)
-   **Docker/Podman** (deployment)

## Usage

After deployment and startup, the SiteCard app-service features a dynamic, multi-section personal site. The following main user-facing sections and features are available:

### Site Sections

-   **Avatar** — Displays profile photo or initials, with quick links to CV download and QR code (for sharing the profile)
-   **About** — Personal background: age, location, education, language skills
-   **Experience** — Visualizes professional experience as a radar chart
-   **Skills** — Doughnut charts for individual and grouped skills
-   **Portfolio** — Interactive project cards, horizontal scroll, technology badges, code & demo links
-   **Contacts** — Icons for various services plus a message button (opens a popup/modal form for direct message submission)

### Interactive Features

-   **Send Message:** Use the Contacts section form to send a message directly. The popup/modal handles input and displays confirmation.
-   **Download CV:** Instantly download the current resume as a file using the button in the Avatar section
-   **Show QR Code:** Generate a scannable QR code for your portfolio/profile (also in Avatar section)
-   **WebApp Authorization:** Admins can login via a special WebApp page (using Telegram authentication)

## Environment Variables

-   `NGINX_PORT` — nginx listen port (default: 8080)
-   `RACKUP_PORT` — Ruby backend port (default: 9292)
