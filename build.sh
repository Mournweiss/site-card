#!/usr/bin/env bash

set -e

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
TMP=keygen_tmp

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

generate_admin_key() {
    info "Generating ADMIN_KEY using key-gen container..."
    rm -rf "$TMP" && mkdir -p "$TMP"
    local der_path
    der_path=$(podman build -t site-card-keygen key/ >/dev/null 2>&1 && \
      podman run --rm -v "$(pwd)/$TMP:/mnt/key" site-card-keygen)
    if [ -z "$der_path" ]; then
        error "Failed to generate ADMIN_KEY DER file via key-gen container"
    fi
    rel_name="${der_path#/mnt/key/}"
    der_host_path="$(pwd)/$TMP/$rel_name"
    if [ ! -f "$der_host_path" ]; then
        error "Key DER file missing on host: $der_host_path (container output: $der_path)"
    fi
    ADMIN_KEY=$(base64 < "$der_host_path" | tr -d '\n')
    if grep -q '^ADMIN_KEY=' .env; then
        sed -i "s|^ADMIN_KEY=.*|ADMIN_KEY=$ADMIN_KEY|" .env
    fi
    rm -f "$der_host_path"
    success "ADMIN_KEY set successfully"
}

main() {
    make_env
    generate_admin_key
    podman-compose --env-file "$env_file" -f "$compose_file" up --build -d
    success "App started in detached mode"
}

main
