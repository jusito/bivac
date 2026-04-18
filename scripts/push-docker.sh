#!/bin/bash

set -euo pipefail

(
    IMAGE_NAME="${1:?"Please provide image name as first argument"}"
    BIVAC_VERSION="${2:?"Please provide bivac version as first argument"}"
    GO_VERSION="${3:?"Please provide Go version as third argument"}"
    RCLONE_VERSION="${4:?"Please provide Rclone version as fourth argument"}"
    RESTIC_VERSION="${5:?"Please provide Restic version as fifth argument"}"

    configurations=(
        "GOOS=linux:GOARCH=amd64"
        "GOOS=linux:GOARCH=386"
        "GOOS=linux:GOARCH=arm:GOARM=7"
        "GOOS=linux:GOARCH=arm64:GOARM=7"
    )
    baseimage_configs=(
        # "debian:bookworm-slim|-bookworm-slim"
        "alpine:3.23|-alpine"
    )

    cd "$(dirname "$0")/.."
    merged_name="${IMAGE_NAME}:${BIVAC_VERSION}${baseimage_tag_suffix}"
    echo docker manifest create "$merged_name" "${successfull[@]}"

    for image in "${successfull[@]}"; do
        os_start=$((${#IMAGE_NAME}+1+${#BIVAC_VERSION}+1))
        os="${image:$os_start}"
        os="${os/-*}"
        arch_start=$((os_start+${#os}+1))
        arch="${image:$arch_start}"
        arch="${arch/-*}"
        cmd=(docker manifest annotate "$merged_name" "$image" --os "$os" --arch "$arch")
        echo "${cmd[@]}"
        if "${cmd[@]}"; then
            echo "$image" >> .local/successfull.log
            # docker push "$current_image"
        else
            echo "$image" >> .local/failed.log
            # errors+=("${cmd[*]}")
        fi
    done
    docker manifest push "$merged_name"
)