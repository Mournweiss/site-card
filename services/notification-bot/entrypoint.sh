#!/bin/bash
#
# Entrypoint script for notification-bot container.
# Performs gRPC Python code generation, sets up environment, and launches notification-bot.
# All errors are surfaced with colored output for container systems/CI logs.
#
set -euo pipefail

# ANSI color codes
COLOR_INFO="\033[0m"       # White (default)
COLOR_WARN="\033[1;33m"    # Yellow
COLOR_ERROR="\033[1;31m"   # Red
COLOR_SUCCESS="\033[1;32m" # Green
COLOR_RESET="\033[0m"

# Info/warn/error/messages with color for CI/container logs
info()    { echo -e "${COLOR_INFO}$1${COLOR_RESET}"; }
warn()    { echo -e "${COLOR_WARN}$1${COLOR_RESET}"; }
error()   { echo -e "${COLOR_ERROR}$1${COLOR_RESET}" >&2; exit 1; }
success() { echo -e "${COLOR_SUCCESS}$1${COLOR_RESET}"; }

# Ensure generated gRPC modules are prioritized in PYTHONPATH for runtime imports
export PYTHONPATH="/app/src/api:${PYTHONPATH:-}"

# Generate Python gRPC classes from proto files. Exits on failure.
#
# Parameters:
# - None
#
# Returns:
# - None (generates Python files)
run_codegen() {
    info "Generating Python gRPC code from proto..."
    if poetry run python -m grpc_tools.protoc -I./proto_context/ --python_out=./src/api/ --grpc_python_out=./src/api/ ./proto_context/service.proto; then
        success "gRPC Python code generated successfully"
    else
        error "Failed to generate gRPC code"
        exit 1
    fi
}

# Launch the Telegram notification-bot service using Poetry.
#
# Parameters:
# - None
#
# Returns:
# - None (exec replaces shell with Python process)
run_service() {
    info "Starting notification-bot service..."
    exec poetry run python src/main.py
}

# Main orchestration entrypoint.
#
# Parameters:
# - $@: array - command-line arguments (will be ignored)
#
# Returns:
# - None
main() {
    run_codegen
    run_service
}

main "$@"
