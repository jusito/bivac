#!/bin/sh

set -eux

RESTIC_VERSION="$1"
# BUILD_OPTS="$2" # unused?

git clone --branch "${RESTIC_VERSION}" --depth 1 "https://github.com/restic/restic" /go/src/github.com/restic/restic
go mod download
RETRACTED=$(go list -mod=mod -m -retracted -f '{{if .Retracted}}{{.Path}}@{{.Version}}{{end}}' all)
if [ -n "${RETRACTED:-}" ]; then
    echo "FAILED: Retracted modules found: $RETRACTED"
    # exit 1
fi
if ! GOOS= GOARCH= GOARM= go run -mod=vendor build.go; then
    go run build.go
fi