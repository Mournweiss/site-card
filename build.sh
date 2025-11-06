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
                NOTIFICATION_BOT_TOKEN="$2"
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
        git submodule update --init --recursive --remote && \
            success "Submodules updated to latest remote version" || warn "Failed to update submodules to latest remote version"
    else
        info ".gitmodules not found, skipping submodule init"
    fi
}

# Ensures all variables from the template are present in the actual env file.
#
# Parameters:
# - template_file: string - path to the template .env file (e.g., .env.example)
# - env_file: string - path to the target .env file
#
# Returns:
# - None
ensure_env_vars() {
    local template_file="$1"
    local env_file="$2"
    local updated=0
    info "Syncing .env with template: $template_file"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        # Parse and trim var name
        var_name="${line%%=*}"
        var_name="$(echo "$var_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        info "Checking if $var_name is present in $env_file ..."
        if ! grep -Eq "^[[:space:]]*#?[[:space:]]*$var_name[[:space:]]*=" "$env_file"; then
            last_char=$(tail -c1 "$env_file" 2>/dev/null || echo '')
            if [[ "$last_char" != "" && "$last_char" != $'\n' ]]; then
                echo >> "$env_file"
            fi
            echo "$line" >> "$env_file"
            info "Added $var_name to $env_file"
            updated=1
        fi
    done < "$template_file"
    if [[ $updated -eq 1 ]]; then
        info "Completed variable sync: $env_file updated"
    else
        info "No missing variables detected in $env_file"
    fi
}

# Verifies or creates .env file from example, injects NOTIFICATION_BOT_TOKEN and DOMAIN if provided.
#
# Parameters:
# - None (uses shell globals)
#
# Returns:
# - None
make_env() {
    if [ -f .env ]; then
        warn ".env already exists, skipping creation"
        ensure_env_vars .env.example .env
    else
        if [ -f .env.example ]; then
            cp .env.example .env
            success ".env created from .env.example"
        else
            error ".env.example not found"
        fi
    fi
    # Inject bot token if set
    if [ -n "$NOTIFICATION_BOT_TOKEN" ]; then
        if grep -q '^NOTIFICATION_BOT_TOKEN=' .env; then
            sed -i "s|^NOTIFICATION_BOT_TOKEN=.*|NOTIFICATION_BOT_TOKEN=$NOTIFICATION_BOT_TOKEN|" .env
        else
            if grep -q '^PROJECT_NAME=' .env; then
                awk '/^PROJECT_NAME=/{print;print "NOTIFICATION_BOT_TOKEN='$NOTIFICATION_BOT_TOKEN'";next}1' .env > .env.tmp && mv .env.tmp .env
            else
                echo "NOTIFICATION_BOT_TOKEN=$NOTIFICATION_BOT_TOKEN" >> .env
            fi
        fi
        success "NOTIFICATION_BOT_TOKEN injected from argument"
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
    PRIVATE_KEY_PATH=$(grep '^PRIVATE_KEY_PATH=' .env | cut -d'=' -f2- | cut -d'#' -f1 | xargs)
    PUBLIC_KEY_PATH=$(grep '^PUBLIC_KEY_PATH=' .env | cut -d'=' -f2- | cut -d'#' -f1 | xargs)
    KEYS_ENCRYPTION=$(grep '^KEYS_ENCRYPTION=' .env | cut -d'=' -f2- | cut -d'#' -f1 | xargs)
    if [ -z "$PRIVATE_KEY_PATH" ] || [ -z "$PUBLIC_KEY_PATH" ] || [ -z "$KEYS_ENCRYPTION" ]; then
        error "Missing required key-related env variables. Aborting."
    fi
    LOCAL_PRIVATE_PATH="$PRIVATE_KEY_PATH"
    LOCAL_PUBLIC_PATH="$PUBLIC_KEY_PATH"
    if [[ "$PRIVATE_KEY_PATH" = /* ]]; then LOCAL_PRIVATE_PATH="${PRIVATE_KEY_PATH#/}"; fi
    if [[ "$PUBLIC_KEY_PATH" = /* ]]; then LOCAL_PUBLIC_PATH="${PUBLIC_KEY_PATH#/}"; fi
    mkdir -p "$(dirname "$LOCAL_PRIVATE_PATH")" "$(dirname "$LOCAL_PUBLIC_PATH")"
    set +e
    KEYGEN_OUTPUT=$(./keygen/generate_key.sh -p -k "$KEYS_ENCRYPTION" 2>&1)
    KEYGEN_EXIT_CODE=$?
    set -e
    if [ $KEYGEN_EXIT_CODE -ne 0 ]; then
        error "Key generation failed (generate_key.sh returned code $KEYGEN_EXIT_CODE). Output: $KEYGEN_OUTPUT"
    fi
    DER_PATH=$(echo "$KEYGEN_OUTPUT" | grep '.der' | head -1 | xargs)
    PEM_PATH=$(echo "$KEYGEN_OUTPUT" | grep '.pem' | head -1 | xargs)
    if [ ! -f "$DER_PATH" ] || [ ! -f "$PEM_PATH" ]; then
        error "Key generation failed: .der or .pem file not produced. Check logs: $KEYGEN_OUTPUT"
    fi
    mv "$DER_PATH" "$LOCAL_PRIVATE_PATH"
    mv "$PEM_PATH" "$LOCAL_PUBLIC_PATH"
    success "Admin key pair generated and placed at $LOCAL_PRIVATE_PATH and $LOCAL_PUBLIC_PATH"
}


# Generates a WEBAPP_TOKEN_SECRET for JWT/WebApp tokens using keygen/generate_key.sh and saves it to .env as base64.
# Skipped if NO_KEYGEN set.
#
# Parameters:
# - None
#
# Returns:
# - None
generate_webapp_token_secret() {
    if [ -n "$NO_KEYGEN" ]; then
        info "NO_KEYGEN set; JWT/WebApp token secret generation skipped, using existing value"
        return 0
    fi
    info "Generating secure WEBAPP_TOKEN_SECRET (JWT/WebApp)..."
    DER_SECRET_PATH=$(./keygen/generate_key.sh -f DER -k "$KEYS_ENCRYPTION" 2>/dev/null | grep '.der' | head -1 | xargs)
    if [ ! -f "$DER_SECRET_PATH" ]; then
        error "Could not generate DER-secret for WEBAPP_TOKEN_SECRET, $DER_SECRET_PATH not found"
    fi
    WEBAPP_TOKEN_SECRET_BASE64=$(base64 < "$DER_SECRET_PATH" | tr -d '\n')
    if [ -z "$WEBAPP_TOKEN_SECRET_BASE64" ]; then
        error "WEBAPP_TOKEN_SECRET could not be created, DER file empty or conversion failed"
    fi
    if grep -q '^WEBAPP_TOKEN_SECRET=' .env; then
        sed -i "s|^WEBAPP_TOKEN_SECRET=.*|WEBAPP_TOKEN_SECRET=$WEBAPP_TOKEN_SECRET_BASE64|" .env
    else
        echo "WEBAPP_TOKEN_SECRET=$WEBAPP_TOKEN_SECRET_BASE64" >> .env
    fi
    success "WEBAPP_TOKEN_SECRET generated"
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
    generate_webapp_token_secret
    clean_proto_contexts
    copy_proto_contexts
    run_project
}

main "$@"
