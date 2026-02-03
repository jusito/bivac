#!/bin/bash

set -euo pipefail

name="$1"
version="$2"

(
    go mod download
    RETRACTED=$(go list -mod=mod -m -retracted -f '{{if .Retracted}}{{.Path}}@{{.Version}}{{end}}' all)
    if [ -n "${RETRACTED:-}" ]; then
        echo "FAILED: $name $version has retracted modules: $RETRACTED"
        exit 1
    else
        echo "Info: $name $version has NO retracted modules."
    fi
)