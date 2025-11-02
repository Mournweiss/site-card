<div align="center">

# Site Card

Containerized microservices web platform with Telegram integration, gRPC, and PostgreSQL backend.

[![Authors](https://img.shields.io/badge/-AUTHORS-blue?style=for-the-badge&logoWidth=40)](AUTHORS.md)
[![TODO](https://img.shields.io/badge/-TODO-blue?style=for-the-badge&logoWidth=40)](TODO.md)
[![Keygen](https://img.shields.io/badge/PQC--Key--Generator-7c3aed?style=for-the-badge)](https://github.com/Mournweiss/PQC-Key-Generator)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge&logoWidth=40)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white&logoWidth=40)](https://www.docker.com/)
[![Ruby](https://img.shields.io/badge/Ruby-3.2.2-CC342D?style=for-the-badge&logo=ruby&logoColor=white&logoWidth=40)](https://www.ruby-lang.org/)
[![Python](https://img.shields.io/badge/Python-3.11-blue.svg?style=for-the-badge&logo=python&logoColor=white&logoWidth=40)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?style=for-the-badge&logo=postgresql&logoColor=white&logoWidth=40)](https://www.postgresql.org/)
[![gRPC](https://img.shields.io/badge/gRPC-1.76.0-blueviolet?style=for-the-badge&logo=grpc)](https://grpc.io/)

</div>

## Overview

SiteCard is a multi-service, container-ready web platform for creating interactive personal/business web cards with Telegram WebApp integration.

### Services & Tools

-   [**App Service**](services/app-service/README.md): Ruby web application (Sinatra/Hanami-style). Handles primary site UI, authentication, asset delivery, and gRPC notifications.
-   [**Notification Bot**](services/notification-bot/README.md): Python, async Telegram bot (aiogram/telethon, gRPC). Delivers contact forms, manages user authorization, and pushes notifications for site events.
-   [**Database**](services/db-service/README.md): PostgreSQL service with migration/init scripts. Stores user data, contacts, portfolio, skills, and experience records.
-   [**Keygen Utility**](keygen/README.md): Containerized Go + OpenSSL tool to generate PQC admin keys (setup/maintenance).

## Deployment

1. Clone the repository:

    ```bash
    git clone https://github.com/Mournweiss/site-card.git

    cd site-card
    ```

2. Prepare and run [orchestration script](build.sh):

    ```bash
    chmod +x build.sh

    ./build.sh
    ```

    **build.sh arguments:**

    ```text
    --docker, -d              Use docker-compose backend orchestration
    --podman, -p              Use podman-compose as orchestrator
    --telegram-token, -t ARG  Inject a Telegram bot token into .env
    --no-keygen, -n           Skip admin key generation (useful for debug/re-run)
    --foreground, -f          Run containers in foreground (not detached)
    ```

3. Access app:
    - Main site: [http://localhost:8080](http://localhost:8080)
    - Telegram Bot: As specified by `NOTIFICATION_BOT_TOKEN`.

## User Data Volume

This project uses the `userdata/` directory (Docker volume) to support runtime file updates without rebuilding containers, enabling dynamic management of:

-   `avatar.<ext>` - user avatar (must be exactly named `avatar` with one of the supported extensions (`png`, `jpg`, `jpeg`); extension must match the `image_ext` field in the database table `avatars`)

-   `CV.pdf` - user CV/resume in PDF format

-   `favicon.ico` - optional site favicon for browser tab and branding (replaceable at runtime)

## Primary Environment Variables

-   `ADMIN_KEY` — PQC admin key for privileged panel access (auto-generated or manual)
-   `DOMAIN` — Public domain (for links and Telegram WebApp integration)
-   `NOTIFICATION_BOT_TOKEN` — Telegram Bot token from @BotFather
-   `DEBUG` — Enable debug output (`true`/`false`)
-   `PROJECT_NAME` — Project identifier shown in logs
-   `NGINX_PORT` — Host port for nginx/main site (default: 8080)
-   `RACKUP_PORT` — Internal Ruby backend port (default: 9292)
-   `NOTIFICATION_BOT_PORT` — gRPC port for notification bot microservice (default: 50051)
