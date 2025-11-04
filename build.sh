#!/usr/bin/env bash
#
# Main build and orchestration script for multi-service site-card project.
# Handles .env setup, key generation, proto file distribution, submodule preparation,
# and container orchestration.
#
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

SERVICES_PATHS=(
    "services/app-service"
    "services/notification-bot"
)

# Parses command-line arguments and sets global variables for orchestrator and options.
# Handles container orchestrator selection, keygen, Telegram token, domain injection, foreground mode.
#
# Parameters:
# - $@: array - command-line arguments
#
# Returns:
# - None (sets global shell vars)
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --podman|-p)
                ORCHESTRATOR="podman-compose"
                shift
                ;;
            --docker|-d)
                ORCHESTRATOR="docker-compose"
                shift
                ;;
            --telegram-token|-t)
                TELEGRAM_TOKEN="$2"
                shift 2
                ;;
            --domain|-dmn)
                DOMAIN_ARG="$2"
                shift 2
                ;;
            --no-keygen|-n)
                NO_KEYGEN="true"
                shift
                ;;
            --foreground|-f)
                FOREGROUND_MODE="true"
                shift
                ;;
            *)
                warn "Unknown argument: $1"
                shift
                ;;
        esac
    done
}

# Checks if a given orchestrator command is installed and available.
#
# Parameters:
# - $1: string - orchestrator name ("docker-compose", "podman-compose", "docker compose")
#
# Returns:
# - 0: success, 1: not available
is_orchestrator_available() {
    case "$1" in
        podman-compose)
            command -v podman-compose &>/dev/null && return 0 || return 1
            ;;
        docker-compose)
            command -v docker-compose &>/dev/null && return 0 || return 1
            ;;
        "docker compose")
            command -v docker &>/dev/null && docker compose version &>/dev/null && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Selects and validates best-available container orchestrator, or uses argument if set.
#
# Parameters:
# - None (uses global ORCHESTRATOR)
#
# Returns:
# - string: orchestrator command or exits with error
select_orchestrator() {
    local candidates=("podman-compose" "docker-compose" "docker compose")
    if [ -n "$ORCHESTRATOR" ]; then
        if is_orchestrator_available "$ORCHESTRATOR"; then
            echo "$ORCHESTRATOR"
            return 0
        else
            error "$ORCHESTRATOR not found."
        fi
    else
        for orch in "${candidates[@]}"; do
            if is_orchestrator_available "$orch"; then
                echo "$orch"
                return 0
            fi
        done
        error "No supported container orchestrator found"
    fi
}

# Initializes git submodules if .gitmodules exists.
#
# Parameters:
# - None
#
# Returns:
# - None
init_submodules() {
    if [ -f .gitmodules ]; then
        info "Initializing git submodules..."
        git submodule update --init --recursive && \
            success "Submodules initialized" || warn "Failed to initialize submodules"
    else
        info ".gitmodules not found, skipping submodule init"
    fi
}

# Verifies or creates .env file from example, injects TELEGRAM_TOKEN and DOMAIN if provided.
#
# Parameters:
# - None (uses shell globals)
#
# Returns:
# - None
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
    # Inject bot token if set
    if [ -n "$TELEGRAM_TOKEN" ]; then
        if grep -q '^TELEGRAM_BOT_TOKEN=' .env; then
            sed -i "s|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN|" .env
        else
            if grep -q '^PROJECT_NAME=' .env; then
                awk '/^PROJECT_NAME=/{print;print "TELEGRAM_BOT_TOKEN='$TELEGRAM_TOKEN'";next}1' .env > .env.tmp && mv .env.tmp .env
            else
                echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN" >> .env
            fi
        fi
        success "TELEGRAM_BOT_TOKEN injected from argument"
    fi
    # Inject DOMAIN if set
    if [ -n "$DOMAIN_ARG" ]; then
        if grep -q '^DOMAIN=' .env; then
            sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN_ARG|" .env
        else
            if grep -q '^PROJECT_NAME=' .env; then
                awk '/^PROJECT_NAME=/{print;print "DOMAIN='$DOMAIN_ARG'";next}1' .env > .env.tmp && mv .env.tmp .env
            else
                echo "DOMAIN=$DOMAIN_ARG" >> .env
            fi
        fi
        success "DOMAIN injected from argument"
    fi
}

# Generates an ADMIN_KEY with keygen/generate_key.sh and saves it to .env as base64.
# Skipped if NO_KEYGEN set.
#
# Parameters:
# - None (uses shell globals, keygen script)
#
# Returns:
# - None
generate_admin_key() {
    if [ -n "$NO_KEYGEN" ]; then
        info "Skipping ADMIN_KEY generation"
        return 0
    fi
    der_path=$(./keygen/generate_key.sh | tail -n 1)
    if [ ! -f "$der_path" ]; then
        error "Key DER file missing on host: $der_path"
    fi
    ADMIN_KEY=$(base64 < "$der_path" | tr -d '\n')
    if grep -q '^ADMIN_KEY=' .env; then
        sed -i "s|^ADMIN_KEY=.*|ADMIN_KEY=$ADMIN_KEY|" .env
    else
        echo "ADMIN_KEY=$ADMIN_KEY" >> .env
    fi
    success "ADMIN_KEY set successfully"
}

# Removes previous "proto-context" directories in all services to avoid stale gRPC definitions.
#
# Parameters:
# - None
#
# Returns:
# - None
clean_proto_contexts() {
    for svc in "${SERVICES_PATHS[@]}"; do
        local proto_dir="$svc/proto-context"
        if [ -e "$proto_dir" ]; then
            info "Removing $proto_dir..."
            rm -rf "$proto_dir" || error "Failed to remove $proto_dir"
        fi
    done
    success "Proto contexts cleaned"
}

# Copies all proto files from ./proto into every service's proto-context dir.
#
# Parameters:
# - None
#
# Returns:
# - None
copy_proto_contexts() {
    local src_proto="proto"
    if [ ! -d "$src_proto" ]; then
        error "Source proto directory '$src_proto' does not exist"
    fi
    info "Copying proto/ to proto-context/ in all services..."
    for svc in "${SERVICES_PATHS[@]}"; do
        mkdir -p "$svc/proto-context"
        cp -r "$src_proto"/* "$svc/proto-context/"
    done
    success "Proto contexts copied successfully"
}

# Stops all previous containers, then builds and starts project in either foreground or detached mode according to FOREGROUND_MODE.
#
# Parameters:
# - None
#
# Returns:
# - None
run_project() {
    local orchestrator=$(select_orchestrator)
    info "Stopping and cleaning up any running containers..."
    $orchestrator --env-file "$env_file" -f "$compose_file" down -v || warn "Down failed or nothing to remove"
    success "Previous containers removed"
    info "Building and starting project in $([ "$FOREGROUND_MODE" = "true" ] && echo "foreground" || echo "detached") mode..."
    if [ "$FOREGROUND_MODE" = "true" ]; then
        $orchestrator --env-file "$env_file" -f "$compose_file" up --build
    else
        $orchestrator --env-file "$env_file" -f "$compose_file" up --build -d
    fi
    success "App started in $([ "$FOREGROUND_MODE" = "true" ] && echo "foreground" || echo "detached") mode"
}

# Main orchestration entrypoint
#
# Parameters:
# - $@: array - command-line invocation arguments
#
# Returns:
# - None
main() {
    parse_args "$@"
    init_submodules
    make_env
    generate_admin_key
    clean_proto_contexts
    copy_proto_contexts
    run_project
}

main "$@"
