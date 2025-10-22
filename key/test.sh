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

IMAGE_NAME=site-card-keygen-test
TMP=test_tmp

build() {
    info "Building keygen container..."
    podman build -t $IMAGE_NAME .
}

validate() {
    local container_path="$1"
    local rel_name="${container_path#/mnt/key/}"
    local host_path="$TMP/$rel_name"
    if [ ! -f "$host_path" ]; then
        error "DER file does not exist: $host_path"
    fi
    size=$(stat -c%s "$host_path")
    if [ "$size" -lt 256 ]; then
        error "DER file too small: $size bytes (want >= 256)"
    fi
    success "Key file generated: $host_path ($size bytes)"
    rm -rf $TMP stderr.log
}

run() {
    info "Preparing test volume..."
    rm -rf $TMP && mkdir -p $TMP && chmod 777 $TMP
    info "Running container..."
    set +e
    output=""
    output=$(podman run --rm -v "$(pwd)/$TMP:/mnt/key" $IMAGE_NAME 2>stderr.log)
    status=$?
    set -e
    info "Container exited with status: $status"
    if [ $status -ne 0 ]; then
        error "Container failed. See stderr.log:\n$(cat stderr.log)"
    fi
    if [ -z "$output" ]; then
        error "No file path output from container"
    fi
    validate "$output"
}

main() {
    build
    run
}

main
