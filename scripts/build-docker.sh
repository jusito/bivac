#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${1:?"Please provide image name as first argument"}"
BIVAC_VERSION="${2:?"Please provide Bivac version as second argument"}"
GO_VERSION="${3:?"Please provide Go version as third argument"}"
RCLONE_VERSION="${4:?"Please provide Rclone version as fourth argument"}"
RESTIC_VERSION="${5:?"Please provide Restic version as fifth argument"}"
GOARCH="${6:?"Please set the target architecture."}"
GOARM="${7:-}"

GOOS="linux"
platform="${GOOS}/${GOARCH}"
tag_suffix="${GOOS}-${GOARCH}"

if [ -n "$GOARM" ]; then
    platform="${platform}/v${GOARM}"
    tag_suffix="${tag_suffix}-${GOARM}"
fi

image="${IMAGE_NAME}:${BIVAC_VERSION}-${tag_suffix}-alpine"

cd "$(dirname "$0")/.."

docker buildx build \
    --load \
    --pull \
    --platform "$platform" \
    --build-arg "VERSION=${BIVAC_VERSION}" \
    --build-arg "RCLONE_VERSION=${RCLONE_VERSION}" \
    --build-arg "RESTIC_VERSION=${RESTIC_VERSION}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --build-arg "GOOS=${GOOS}" \
    --build-arg "GOARCH=${GOARCH}" \
    --build-arg "GOARM=${GOARM}" \
    -t "$image" \
    .

echo "successfully built $image"
