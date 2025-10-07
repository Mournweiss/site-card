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

if [ ! -d /app/public/assets ] || [ -z "$(ls -A /app/public/assets 2>/dev/null)" ]; then
    error "Frontend assets not found, please ensure assets are built via Rake/Vite"
fi

if [ -f /app/config/nginx.conf ]; then
    info "Generating nginx.conf from template with envsubst..."
    envsubst '$NGINX_PORT $RACKUP_PORT' < /app/config/nginx.conf > /etc/nginx/nginx.conf || error "Failed to generate nginx.conf from template"
else
    error "nginx.conf not found in /app/config"
fi

info "Starting nginx on port ${NGINX_PORT:-8080}..."
nginx || error "Failed to start nginx"
success "nginx started"

info "Starting Ruby backend (bundle exec rackup config.ru) on port ${RACKUP_PORT:-9292}..."
exec bundle exec rackup /app/config.ru -p "${RACKUP_PORT:-9292}"
