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

    cd "$(dirname "$0")/.."
    cmd=(docker build --no-cache --pull --build-arg RCLONE_VERSION="${RCLONE_VERSION}" --build-arg "RESTIC_VERSION=${RESTIC_VERSION}")
    errors=()
    for baseimage_tag_suffix in "-bookworm" "-alpine"; do
        successfull=()
        cmd_baseimage=("${cmd[@]}" --build-arg "GO_VERSION=$GO_VERSION${baseimage_tag_suffix}")
        for config in "${configurations[@]}"; do
            current_cmd=("${cmd_baseimage[@]}")

            mapfile -t args < <(echo "$config" | tr ':' '\n')
            current_variant=""
            for arg in "${args[@]}"; do
                current_cmd+=(--build-arg "$arg")
                current_variant+="-${arg#*=}"
            done

            current_image="${IMAGE_NAME}:${BIVAC_VERSION}${current_variant}${baseimage_tag_suffix}"
            current_cmd+=(-t "${current_image}" .)

            echo "${current_cmd[@]}"
            if "${current_cmd[@]}"; then
                successfull+=("$current_image")
            else
                errors+=("${current_cmd[*]}")
            fi
        done
        
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
                docker push "$current_image"
            else
                errors+=("${cmd[*]}")
            fi
        done
        docker manifest push "$merged_name"
    done

    if [ "${#errors[@]}" -gt 0 ]; then
        echo "ERROR following commands failed, see logs for details:"
        printf "%s\n" "${errors[@]}"
        exit 1
    fi

    echo "successfull"
)
