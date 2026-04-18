#!/bin/sh

set -eu

(
    IMAGE_NAME="${1:?"Please provide image name as first argument"}"
    BIVAC_VERSION="${2:?"Please provide bivac version as first argument"}"
    GO_VERSION="${3:?"Please provide Go version as third argument"}"
    RCLONE_VERSION="${4:?"Please provide Rclone version as fourth argument"}"
    RESTIC_VERSION="${5:?"Please provide Restic version as fifth argument"}"
    GOOS="linux"
    GOARCH="${6:?"Please set the target architecture."}"
    GOARM="${7:-""}"

    cd "$(dirname "$0")"
    if [ -n "${GOARM:-""}" ]; then
        IMAGE="${IMAGE_NAME}:${BIVAC_VERSION}-$GOOS-$GOARCH-$GOARM-alpine"
    else    
        IMAGE="${IMAGE_NAME}:${BIVAC_VERSION}-$GOOS-$GOARCH-alpine"
    fi

    if docker build --no-cache --pull \
        --build-arg "RCLONE_VERSION=${RCLONE_VERSION}" \
        --build-arg "RESTIC_VERSION=${RESTIC_VERSION}" \
        --build-arg "GO_VERSION=$GO_VERSION" \
        --build-arg "GOOS=$GOOS" \
        --build-arg "GOARCH=$GOARCH" \
        --build-arg "GOARM=${GOARM:-""}" \
        -t "$IMAGE" \
        ..; then
        echo "$IMAGE" >> .images.list
        echo "successfully build $IMAGE"
    else
        echo "failed to build $IMAGE"
        exit 1
    fi
)
