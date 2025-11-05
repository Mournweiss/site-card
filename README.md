<div align="center">

# Site Card

Containerized micro-service web business-card platform

[![Authors](https://img.shields.io/badge/-AUTHORS-blue?style=for-the-badge&logoWidth=40)](AUTHORS.md)
[![TODO](https://img.shields.io/badge/-TODO-blue?style=for-the-badge&logoWidth=40)](TODO.md)
[![Keygen](https://img.shields.io/badge/PQC--Key--Generator-7c3aed?style=for-the-badge)](https://github.com/Mournweiss/PQC-Key-Generator)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge&logoWidth=40)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white&logoWidth=40)](https://www.docker.com/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-CC342D?style=for-the-badge&logo=ruby&logoColor=white&logoWidth=40)](https://www.ruby-lang.org/)
[![Python](https://img.shields.io/badge/Python-3.11-blue.svg?style=for-the-badge&logo=python&logoColor=white&logoWidth=40)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-blue?style=for-the-badge&logo=postgresql&logoColor=white&logoWidth=40)](https://www.postgresql.org/)
[![gRPC](https://img.shields.io/badge/gRPC-1.76.0-blueviolet?style=for-the-badge&logo=grpc)](https://grpc.io/)

</div>

## Overview

SiteCard is a micro-service, container-ready web platform for creating interactive personal/business web cards with Telegram WebApp integration.

### Services & Tools

-   [**App Service**](services/app-service/README.md): Ruby web application. Handles primary site UI, authentication, asset delivery, and gRPC notifications.
-   [**Notification Bot**](services/notification-bot/README.md): Python, async Telegram bot (aiogram/telethon, gRPC). Delivers contact forms, manages user authorization, and pushes notifications for site events.
-   [**Database**](services/db-service/README.md): PostgreSQL service with migration/init scripts. Stores user data, contacts, portfolio, skills, and experience records.
-   [**Keygen Utility**](https://github.com/Mournweiss/PQC-Key-Generator/blob/main/README.md): Containerized Go + OpenSSL tool to generate PQC admin keys (setup/maintenance).

## Deployment

1. Clone the repository:

    ```bash
    git clone https://github.com/Mournweiss/site-card.git

    cd site-card
    ```

2. Place SSL certificates:

    All your SSL certificates (in .crt format: domain, root, intermediate, etc.) and private key (.key) provided by your certificate authority or domain registrar must be put inside the `certs/` directory in the project root. NGINX will automatically detect and process all `.crt` files for use as the certificate chain, and only a single `.key` file (the main private key) must be provided.

    > **Note:** NGINX ONLY accepts certificates in `.crt` format (not in `.der`, `.p7b` or `.p7c`). Do NOT place `.csr` files (certificate signing requests) inside `certs/`. They are only used to request certificates from a Certificate Authority and are not needed by NGINX or the running site.

3. Prepare and run [orchestration script](build.sh):

    ```bash
    chmod +x build.sh

    ./build.sh
    ```

    **build.sh arguments:**

    ```text
    --docker, -d              Use docker-compose backend orchestration
    --podman, -p              Use podman-compose as orchestrator
    --telegram-token, -t ARG  Inject a Telegram bot token into .env (required)
    --domain, -dmn ARG        Inject a public domain name (used for NGINX and service URLs) into the .env file (required)
    --no-keygen, -n           Skip admin key generation
    --foreground, -f          Run containers in foreground
    ```

    > **Note:** `build.sh` automatically selects an available orchestration engine if no specific option is given. To force a specific orchestrator, use the `--podman`/`-p` or `--docker`/`-d` argument as needed.

4. Access app:
    - Main site: [http://localhost:8080](http://localhost:8080)
    - Telegram Bot: as specified by `NOTIFICATION_BOT_TOKEN`.

## User Data Volume

This project uses the [userdata/](userdata/) directory (Docker volume) to support runtime file updates without rebuilding containers, enabling dynamic management of:

-   `avatar.<ext>` - user avatar (must be exactly named `avatar` with one of the supported extensions (`png`, `jpg`, `jpeg`); extension must match the `image_ext` field in the database table `avatars`)

-   `CV.pdf` - user CV/resume in PDF format

-   `favicon.ico` - site favicon for browser tab and branding

## Primary Environment Variables

-   `PRIVATE_KEY_PATH` — Absolute path to the admin's private key (default: /certs/private_key.der).
-   `PUBLIC_KEY_PATH` — Absolute path to the admin's public key (default: /certs/public_key.pem)
-   `KEYS_ENCRYPTION` — Algorithm for admin keypair generation; must match platform requirements (default: ML-KEM-512).
-   `DOMAIN` — Public domain (for links and Telegram WebApp integration)
-   `NOTIFICATION_BOT_TOKEN` — Telegram Bot token from @BotFather
-   `DEBUG` — Enable debug output (`true`/`false`)
-   `PROJECT_NAME` — Project identifier, used as prefix for names of all services and orchestration objects (containers, networks, volumes) in the stack (default: site-card)
-   `NGINX_PORT` — Host port for nginx/main site (default: 8080)
-   `RACKUP_PORT` — Internal Ruby backend port (default: 9292)
-   `NOTIFICATION_BOT_PORT` — gRPC port for notification bot microservice (default: 50051)
