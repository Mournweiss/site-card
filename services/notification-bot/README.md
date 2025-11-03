<div align="center">

# Notification Bot

SiteCard notification microservice

[![Python](https://img.shields.io/badge/Python-3.11-blue?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![python-telegram-bot](https://img.shields.io/badge/python--telegram--bot-22.5-44a8b3?style=for-the-badge&logo=telegram)](https://python-telegram-bot.org/)
[![gRPC](https://img.shields.io/badge/gRPC-1.76.0-blueviolet?style=for-the-badge&logo=grpc)](https://grpc.io/)
[![Protobuf](https://img.shields.io/badge/Protobuf-6.33.0-FFCC00?style=for-the-badge&logo=protocol-buffers&logoColor=black)](https://developers.google.com/protocol-buffers)
[![structlog](https://img.shields.io/badge/structlog-25.5.0-00bfae?style=for-the-badge)](https://www.structlog.org/)
[![psycopg2](https://img.shields.io/badge/psycopg2-2.9.11-0064a5?style=for-the-badge)](https://www.psycopg.org/)
[![Poetry](https://img.shields.io/badge/Poetry-1.x-8c8c8c?style=for-the-badge&logo=poetry)](https://python-poetry.org/)
[![python:3.11-slim](https://img.shields.io/badge/python:3.11--slim-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/_/python)

</div>

## Overview

Notification-bot is a containerized microservice component of the SiteCard project. It delivers contact form notifications and handles user authorization/integration via Telegram (Bot API & WebApp), receiving events and commands over gRPC and through Telegram itself.

### Tech Stack

-   **Python 3.11**
-   **python-telegram-bot 22.5** (async, with job queues)
-   **gRPC / protobuf** (grpcio, grpcio-tools)
-   **PostgreSQL** (psycopg2)
-   **structlog** (human/JSON logging)
-   **Poetry** (dependency management)
-   **Docker/Podman** (deployment)

You can view the full list of Python dependencies in [pyproject.toml](./pyproject.toml).

## Usage

### Bot Commands and Features

-   `/start` — Start the bot and receive a button to authorize via the SiteCard WebApp.
-   `/about` — Show information about the Notification Bot, its version, and supported commands.
-   `/logout` — Deauthorize and stop receiving notifications.
-   `/status` - Display user authorization status.

### Features

-   Automatic notification delivery of contact form messages to all currently authorized Telegram users.
-   Secure WebApp-based authorization via Telegram.
-   Easy opt-out with /logout command.

## Environment Variables

-   `NOTIFICATION_BOT_TOKEN` — Telegram Bot API token (required)
-   `NOTIFICATION_BOT_PORT` — gRPC API listen port (default: 50051)
