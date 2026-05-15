#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${1:?"Please provide image name as first argument"}"
BIVAC_VERSION="${2:?"Please provide Bivac version as second argument"}"
GO_VERSION="${3:?"Please provide Go version as third argument"}"
RCLONE_VERSION="${4:?"Please provide Rclone version as fourth argument"}"
RESTIC_VERSION="${5:?"Please provide Restic version as fifth argument"}"

cd "$(dirname "$0")/.."

scripts/build-docker.sh "$IMAGE_NAME" "$BIVAC_VERSION" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION" amd64
scripts/build-docker.sh "$IMAGE_NAME" "$BIVAC_VERSION" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION" arm64
scripts/build-docker.sh "$IMAGE_NAME" "$BIVAC_VERSION" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION" arm 7
