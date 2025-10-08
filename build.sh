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

# Build container image
build() {
    local container_name="${CONTAINER_NAME:-site-card}"
    info "Building $container_name container image with Podman..."
    podman build -t "$container_name" . || error "Build failed"
    success "Image built successfully"
}

# Run container
run() {
    local nginx_port="${NGINX_PORT:-8080}"
    local container_name="${CONTAINER_NAME:-site-card}"
    info "Running $container_name container with Podman on port $nginx_port..."
    podman run --rm -d -p "$nginx_port:$nginx_port" \
        -e NGINX_PORT="$nginx_port" -e RACKUP_PORT="${RACKUP_PORT:-9292}" \
        --name "$container_name" "$container_name" || error "Container run failed"
    success "Container started in detached mode"
}

# Create .env from .env.example
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

# Main entrypoint
main() {
    make_env
    build
    run
}

main "$@"
