#!/bin/sh
#
# Entrypoint script for app-service container.
# Orchestrates environment checks, asset warnings, gRPC code generation,
# configures nginx, and runs the Ruby backend. All output uses colored logging and
# failure aborts container boot for reliable CI/CD and prod deploys.
#
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

# Checks that all required environment variables for DB, nginx, and backend are present.
#
# Parameters:
# - None (uses shell env)
#
# Returns:
# - None (exits on missing vars)
check_env() {
    : "${PGHOST?PGHOST is required}"
    : "${PGPORT?PGPORT is required}"
    : "${PGUSER?PGUSER is required}"
    : "${PGPASSWORD?PGPASSWORD is required}"
    : "${PGDATABASE?PGDATABASE is required}"
    : "${NGINX_HTTP_PORT?NGINX_HTTP_PORT is required}"
    : "${NGINX_HTTPS_PORT?NGINX_HTTPS_PORT is required}"
    : "${RACKUP_PORT?RACKUP_PORT is required}"
    success "All required environment variables present"
}

# Emits a warning if ./public/assets directory is missing or empty (for safe asset serving)
#
# Parameters:
# - None
#
# Returns:
# - None
asset_warn() {
    if [ ! -d ./public/assets ] || [ -z "$(ls -A ./public/assets 2>/dev/null)" ]; then
        warn "./public/assets is missing or empty"
    fi
}

# Runs gRPC protobuf generator; ensures Ruby plugin and output files exist.
#
# Parameters:
# - None
#
# Returns:
# - None (exits on failure)
protoc_gen() {
    if ! command -v protoc >/dev/null 2>&1; then
        error "protoc not found"
    fi
    info "Generating Ruby gRPC files from proto-context/service.proto..."
    protoc --proto_path=./proto-context --ruby_out=./proto-context --grpc_out=./proto-context --plugin=protoc-gen-grpc=$(which grpc_tools_ruby_protoc_plugin) ./proto-context/service.proto || error "protoc generation failed"
    if [ "${DEBUG:-}" = "true" ]; then
        ls -l ./proto-context
    fi
    if [ ! -s ./proto-context/service_pb.rb ] || [ ! -s ./proto-context/service_services_pb.rb ]; then
        error "gRPC Ruby files not generated"
    fi
    success "Ruby gRPC files generated"
}

# Checks all required conditions for TLS: domain validity and certificate presence.
#
# Parameters:
# - None (uses DOMAIN, /certs/ paths from environment/filesystem)
#
# Returns:
# - 0 if HTTPS prerequisites are met and flags are set (enables HTTPS)
# - 1 for HTTP-only mode; aborts process if domain is invalid
check_tls() {
    if [ -n "${DOMAIN:-}" ]; then
        validate_domain
    fi
    if ls /certs/*.crt 1> /dev/null 2>&1 && ls /certs/*.key 1> /dev/null 2>&1; then
        if [ -n "${DOMAIN:-}" ]; then
            export NGINX_ENABLE=1
            info "Valid domain and at least one certificate/key found, running PROD_MODE"
            info "DOMAIN=$DOMAIN"
            return 0
        else
            export NGINX_ENABLE=""
            warn "Certs found but DOMAIN unset, running DEV_MODE"
            return 1
        fi
    else
        export NGINX_ENABLE=""
        warn "No certificate (.crt) or key (.key) found in /certs, running DEV_MODE"
        return 1
    fi
}

# Validates DOMAIN environment variable using simple regex for FQDN.
#
# Parameters:
# - None (uses DOMAIN from environment)
#
# Returns:
# - None (exits the process if DOMAIN is invalid)
validate_domain() {
    if [ -n "${DOMAIN:-}" ]; then
        if ! echo "$DOMAIN" | grep -Eq '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
            error "DOMAIN $DOMAIN is invalid. Example: site.com or sub.domain.org"
        fi
    fi
}

# Aggregates certificates and private key into Nginx internal location for TLS usage.
#
# - Concatenates all .crt files in /certs into /etc/nginx/certs/fullchain.pem (if any .crt present)
# - Copies *.key in /certs to /etc/nginx/certs/privkey.pem (uses first found)
#
# Returns:
# - None (prepares files for Nginx)
prepare_nginx_certs() {
    mkdir -p /etc/nginx/certs
    info "Searching for .crt certificate files in /certs..."
    crt_files=$(ls /certs/*.crt 2>/dev/null || true)
    if [ -n "$crt_files" ]; then
        info "Found certificate files: $crt_files"
        cat $crt_files > /etc/nginx/certs/fullchain.pem
        success "Created /etc/nginx/certs/fullchain.pem from found .crt files"
    else
        warn "No .crt certificate files found in /certs"
    fi
    info "Searching for .key files in /certs..."
    keys_found=$(find /certs -maxdepth 1 -type f -name "*.key")
    key_count=$(echo "$keys_found" | grep -c ".key" || true)
    if [ "$key_count" -gt 1 ]; then
        warn "More than one .key file found! Using the first: $(echo "$keys_found" | head -n1)"
    fi
    first_key=$(echo "$keys_found" | head -n1)
    if [ -n "$first_key" ]; then
        cp "$first_key" /etc/nginx/certs/privkey.pem
        success "Copied private key to /etc/nginx/certs/privkey.pem"
    else
        warn "No .key file found in /certs"
    fi
    if [ ! -s /etc/nginx/certs/fullchain.pem ]; then
        error "Nginx fullchain.pem was not created, no crt files or empty result"
    fi
    if [ ! -s /etc/nginx/certs/privkey.pem ]; then
        error "Nginx privkey.pem was not created, no key file copied or empty result"
    fi
}


# Generates nginx.conf from template using substituted environment variables.
#
# Parameters:
# - None (operates on environment, config paths)
#
# Returns:
# - None (exits on error or writes new config to /etc/nginx/nginx.conf)
setup_nginx() {
    if [ "$NGINX_ENABLE" = "1" ]; then
        info "Starting in PROD_MODE..."
        prepare_nginx_certs
        if [ -f /app/config/nginx.prod.conf ]; then
            envsubst '$NGINX_HTTPS_PORT $RACKUP_PORT $DOMAIN' < /app/config/nginx.prod.conf > /etc/nginx/nginx.conf
        else
            error "nginx.prod.conf not found in /app/config"
        fi
    else
        warn "Starting in DEV_MODE (HTTP only)..."
        if [ -f /app/config/nginx.dev.conf ]; then
            envsubst '$NGINX_HTTP_PORT $RACKUP_PORT' < /app/config/nginx.dev.conf > /etc/nginx/nginx.conf
        else
            error "nginx.dev.conf not found in /app/config"
        fi
    fi
}

# Starts nginx using the generated config, aborting if startup fails.
#
# Parameters:
# - None
#
# Returns:
# - None
start_nginx() {
    if [ "$NGINX_ENABLE" = "1" ]; then
        info "Starting nginx on port $NGINX_HTTPS_PORT..."
    else
        info "Starting nginx on port $NGINX_HTTP_PORT..."
    fi
    nginx || error "Failed to start nginx"
    success "nginx started"
}

# Launches the application in the appropriate mode: 
# - PROD_MODE: nginx + rackup if NGINX_ENABLE=1, else DEV_MODE (rackup only)
#
# Parameters:
# - None
#
# Returns:
# - None (never returns)
start_app() {
    setup_nginx
    start_nginx
    exec bundle exec rackup /app/config.ru -p "$RACKUP_PORT"
}

# Orchestrates full startup: env check, asset warn, gRPC gen, nginx setup/start, Ruby app.
#
# Parameters:
# - None
#
# Returns:
# - None
main() {
    check_env
    check_tls || true
    asset_warn
    protoc_gen
    start_app
}

main
