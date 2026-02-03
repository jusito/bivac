#!/bin/sh

set -eux

RESTIC_VERSION="$1"
BUILD_DATE="$2"
TARGET="${3:-"/go/src/github.com/restic/restic"}"


(
    script_dir=$(realpath "$(dirname "$0")")
    if [ -d "$TARGET" ]; then
        find "${TARGET:?}" -mindepth 1 -maxdepth 1 -exec rm -rf "{}" \;
    fi
    git clone --branch "${RESTIC_VERSION}" --depth 1 "https://github.com/restic/restic" "$TARGET"
    cd "$TARGET"
    
    BUILD_OPTS="-s -w -X 'main.version=$RESTIC_VERSION' -X 'main.buildDate=$BUILD_DATE' -X 'main.commitSha1=$(git rev-parse HEAD)'"
    go run build.go
)