<div align="center">

# DB Service

SiteCard database microservice

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-blue?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![postgres:14-alpine](https://img.shields.io/badge/postgres:14--alpine-565656?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/_/postgres)

</div>

## Overview

DB service provides the fully-initialized PostgreSQL database backend for the SiteCard platform. It is deployed as a container, automatically applies schema and demo seed data, and persists all key application data (profile, skills, portfolio, authorization, etc.). Every microservice in the SiteCard architecture depends on this data storage layer.

### Tech Stack

-   **PostgreSQL 14** (main datastore)
-   **Docker/Podman** (deployment)
-   **Official postgres image** for reliability & maintenance

## Usage

After deployment, db-service runs the PostgreSQL database engine, exposing the data layer to all other services via standard connection parameters. Schemas and initial data are automatically loaded at first container start via the [init_pg.sql](init_pg.sql) script. No manual user interaction is required; database access is managed programmatically by platform microservices, which connect using environment variables.

## Schema Summary

-   **avatars** – User card info and profile photo (one per user)
-   **about** – Personal profile metadata (age, education, languages, etc.)
-   **careers** – Work history, linked to the 'about' section
-   **skill_groups** – Categories of skills for better grouping and display
-   **skills** – Individual skills, with display color and level values
-   **experiences** – Skill matrix for visual experience/radar chart
-   **portfolios** – Key projects and portfolio items
-   **portfolio_languages** – Programming language composition per project (for bar/legend visualization)
-   **portfolio_tech_badges** – Technology badges per project (icons, labels)
-   **contacts** – User or site contact methods (various types, with UI icons)
-   **authorized_bot_users** – List of WebApp users granted notification access

## Environment Variables

-   `PGHOST` - Database service name (default: db-service)
-   `PGPORT` - Database service port (default: 5432)
-   `PGDATABASE` – Default database name (default: postgres)
-   `PGUSER` – Database superuser (default: postgres)
-   `PGPASSWORD` – Superuser password (default: postgres)
