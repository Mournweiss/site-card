#!/usr/bin/env bash

set -euo pipefail

# ANSI color codes
COLOR_INFO="\033[0m"       # White (default)
COLOR_WARN="\033[1;33m"    # Yellow
COLOR_ERROR="\033[1;31m"   # Red
COLOR_SUCCESS="\033[1;32m" # Green
COLOR_RESET="\033[0m"

info()    { echo -e "${COLOR_INFO}$1${COLOR_RESET}"; }
warn()    { echo -e "${COLOR_WARN}$1${COLOR_RESET}"; }
error()   { echo -e "${COLOR_ERROR}$1${COLOR_RESET}" >&2; exit 1; }
success() { echo -e "${COLOR_SUCCESS}$1${COLOR_RESET}"; }

compose_file="compose.yml"
env_file=".env"

make_env() {
    if [ -f .env ]; then
        warn ".env already exists, skipping creation"
    else
        if [ -f .env.example ]; then
            cp .env.example .env
            success ".env created from .env.example"
        else
            error ".env.example not found"
        fi
    fi
}

main() {
    make_env
    podman-compose --env-file "$env_file" -f "$compose_file" up --build -d
    success "App started in detached mode"
}

main
