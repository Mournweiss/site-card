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

SERVICES_PATHS=(
    "services/card"
    "services/notification-bot"
)

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
            --no-keygen|-n)
                NO_KEYGEN="true"
                shift
                ;;
            *)
                warn "Unknown argument: $1"
                shift
                ;;
        esac
    done
}

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

init_submodules() {
    if [ -f .gitmodules ]; then
        info "Initializing git submodules..."
        git submodule update --init --recursive && \
            success "Submodules initialized" || warn "Failed to initialize submodules"
    else
        info ".gitmodules not found, skipping submodule init"
    fi
}

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
}

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

clean_proto_contexts() {
    for svc in "${SERVICES_PATHS[@]}"; do
        local proto_dir="$svc/proto-context"
        if [ -e "$proto_dir" ]; then
            info "Removing $proto_dir..."
            rm -rf "$proto_dir" || error "Failed to remove $proto_dir"
        fi
    done
    success "Proto contexts cleaned."
}

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

run_project() {
    local orchestrator=$(select_orchestrator)
    info "Stopping and cleaning up any running containers..."
    $orchestrator --env-file "$env_file" -f "$compose_file" down -v || warn "Down failed or nothing to remove"
    success "Previous containers removed"
    info "Building and starting project in detached mode..."
    $orchestrator --env-file "$env_file" -f "$compose_file" up --build -d
    success "App started in detached mode"
}

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
