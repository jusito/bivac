#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
script_dir="$(pwd)"
repo_root="$(realpath "$script_dir/../../..")"
image_name="localhost/bivac-testing"

build_test_image() {
    built_image="$("$repo_root/scripts/build-docker.sh" "$image_name" "$BIVAC_VERSION" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION" "$GOARCH" "$GOARM" | tee /dev/stderr | tail -n 1)"

    docker tag "$built_image" "$image_name:latest"
}

dump_logs() {
    log_dir="logs"

    cd "$script_dir"

    rm -rf "$log_dir" &> /dev/null 2>&1 || true
    mkdir -p "$log_dir"

    echo "Docker integration test failed. Container status:"
    docker compose ps || true

    echo
    echo "Writing Docker integration test logs to $PWD/$log_dir"

    while IFS= read -r service; do
        [ -n "$service" ] || continue

        log_file="$log_dir/$service.log"
        echo "  $log_file"
        docker compose logs --no-color "$service" >"$log_file" 2>&1 || true
    done < <(docker compose config --services)
}

cleanup() {
    status="${1:-$?}"

    trap - EXIT INT TERM HUP QUIT

    cd "$script_dir"

    if [ "$status" -ne 0 ]; then
        dump_logs
    fi

    docker compose down -v -t 0 || true
    exit "$status"
}



set -a
source <(make -s -C "$repo_root" print-version-env)
set +a

build_test_image

cd "$script_dir"
docker compose down -v -t 0
trap 'cleanup $?' EXIT INT TERM HUP QUIT
docker compose up --build --abort-on-container-exit --exit-code-from integration-test integration-test
