#!/bin/sh

set -eux

RCLONE_VERSION="$1"
BUILD_OPTS="$2"

git clone --branch "${RCLONE_VERSION}" --depth 1 "https://github.com/rclone/rclone" /go/src/github.com/rclone/rclone
go mod download
RETRACTED=$(go list -mod=mod -m -retracted -f '{{if .Retracted}}{{.Path}}@{{.Version}}{{end}}' all)
if [ -n "${RETRACTED:-}" ]; then
    echo "FAILED: Retracted modules found: $RETRACTED"
    # exit 1
fi

env ${BUILD_OPTS:-} go build