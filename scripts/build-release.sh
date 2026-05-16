#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${1:?"Please provide image name as first argument"}"
GO_VERSION="${2:?"Please provide Go version as second argument"}"
RCLONE_VERSION="${3:?"Please provide Rclone version as third argument"}"
RESTIC_VERSION="${4:?"Please provide Restic version as fourth argument"}"
BIVAC_VERSION="${5:?"Please provide Bivac version as fifth argument"}"

tags=("$BIVAC_VERSION" "latest")

if [[ "$BIVAC_VERSION" =~ ^v?([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
    tags+=("v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}")
    tags+=("v${BASH_REMATCH[1]}")
fi

cd "$(dirname "$0")/.."

scripts/push-docker.sh "$IMAGE_NAME" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION" "${tags[@]}"
