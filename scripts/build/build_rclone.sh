#!/bin/sh

set -eux

RCLONE_VERSION="$1"
BUILD_DATE="$2"
TARGET="${3:-"/go/src/github.com/rclone/rclone"}"


(
    script_dir=$(realpath "$(dirname "$0")")
    if [ -d "$TARGET" ]; then
        find "${TARGET:?}" -mindepth 1 -maxdepth 1 -exec rm -rf "{}" \;
    fi
    git clone --branch "$RCLONE_VERSION" --depth 1 "https://github.com/rclone/rclone" "$TARGET"
    cd "$TARGET"

    BUILD_OPTS="-s -w -X 'main.version=$RCLONE_VERSION' -X 'main.buildDate=$BUILD_DATE' -X 'main.commitSha1=$(git log -1 --format=%H)'"
    CGO_ENABLED=0 go build -ldflags="$BUILD_OPTS"
)