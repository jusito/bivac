#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${1:?"Please provide image name as first argument"}"
GO_VERSION="${2:?"Please provide Go version as second argument"}"
RCLONE_VERSION="${3:?"Please provide Rclone version as third argument"}"
RESTIC_VERSION="${4:?"Please provide Restic version as fourth argument"}"
shift 4

if [ "$#" -eq 0 ]; then
    echo "Please provide at least one image tag." >&2
    exit 1
fi

primary_tag="$1"
platforms="linux/amd64,linux/arm64,linux/arm/v7"
tags=()

for tag in "$@"; do
    tags+=("-t" "${IMAGE_NAME}:${tag}")
done

cd "$(dirname "$0")/.."

docker buildx build \
    --push \
    --pull \
    --platform "$platforms" \
    --build-arg "VERSION=${primary_tag}" \
    --build-arg "RCLONE_VERSION=${RCLONE_VERSION}" \
    --build-arg "RESTIC_VERSION=${RESTIC_VERSION}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    "${tags[@]}" \
    .

echo "successfully pushed ${IMAGE_NAME} tags: $*"
