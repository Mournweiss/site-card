#!/bin/sh

set -euo pipefail

COLOR_INFO="\033[0m"
COLOR_WARN="\033[1;33m"
COLOR_ERROR="\033[1;31m"
COLOR_SUCCESS="\033[1;32m"
COLOR_RESET="\033[0m"

info()    { printf "%b\n" "${COLOR_INFO}$1${COLOR_RESET}"; }
warn()    { printf "%b\n" "${COLOR_WARN}$1${COLOR_RESET}"; }
error()   { printf "%b\n" "${COLOR_ERROR}$1${COLOR_RESET}" >&2; exit 1; }
success() { printf "%b\n" "${COLOR_SUCCESS}$1${COLOR_RESET}"; }

check_env() {
    : "${PGHOST?PGHOST is required}"
    : "${PGPORT?PGPORT is required}"
    : "${PGUSER?PGUSER is required}"
    : "${PGPASSWORD?PGPASSWORD is required}"
    : "${PGDATABASE?PGDATABASE is required}"
    : "${NGINX_PORT?NGINX_PORT is required}"
    : "${RACKUP_PORT?RACKUP_PORT is required}"
    success "All required environment variables present"
}

asset_warn() {
    if [ ! -d ./public/assets ] || [ -z "$(ls -A ./public/assets 2>/dev/null)" ]; then
        warn "./public/assets is missing or empty"
    fi
}

setup_nginx() {
    if [ -f /app/config/nginx.conf ]; then
        info "Generating nginx.conf from template with envsubst..."
        envsubst '$NGINX_PORT $RACKUP_PORT' < /app/config/nginx.conf > /etc/nginx/nginx.conf || error "Failed to generate nginx.conf from template"
    else
        error "nginx.conf not found in /app/config"
    fi
}

start_nginx() {
    info "Starting nginx on port $NGINX_PORT..."
    nginx || error "Failed to start nginx"
    success "nginx started"
}

start_app() {
    info "Starting Ruby backend (bundle exec rackup config.ru) on port $RACKUP_PORT..."
    exec bundle exec rackup /app/config.ru -p "$RACKUP_PORT"
}

main() {
    check_env
    asset_warn
    setup_nginx
    start_nginx
    start_app
}

main
