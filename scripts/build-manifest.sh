#!/bin/sh

set -eu

(
    IMAGE_NAME="${1:?"Please provide image name as first argument"}"
    BIVAC_VERSION="${2:?"Please provide bivac version as first argument"}"
    GO_VERSION="${3:?"Please provide Go version as third argument"}"
    RCLONE_VERSION="${4:?"Please provide Rclone version as fourth argument"}"
    RESTIC_VERSION="${5:?"Please provide Restic version as fifth argument"}"
    args=("$IMAGE_NAME" "$BIVAC_VERSION" "$GO_VERSION" "$RCLONE_VERSION" "$RESTIC_VERSION")
    manifest="${IMAGE_NAME}:${BIVAC_VERSION}-alpine"

    cd "$(dirname "$0")"

    # rm .images.list > /dev/null 2>&1 || true
    # ./build-docker.sh "${args[@]}" amd64
    # ./build-docker.sh "${args[@]}" arm 7
    # ./build-docker.sh "${args[@]}" arm64 7
    # ./build-docker.sh "${args[@]}" 386
    mapfile -t images < .images.list

    # docker manifest create "$manifest" "${images[@]}"
    set -x
    for image in "${images[@]}"; do
        os_start=$((${#IMAGE_NAME}+1+${#BIVAC_VERSION}+1))
        os="${image:$os_start}"
        os="${os/-*}"
        arch_start=$((os_start+${#os}+1))
        arch="${image:$arch_start}"
        arch="${arch/-*}"
        cmd=(docker manifest annotate "$merged_name" "$image" --os "$os" --arch "$arch")
        echo "${cmd[@]}"
        # if "${cmd[@]}"; then
        #     echo "$image" >> .local/successfull.log
        #     # docker push "$current_image"
        # else
        #     echo "$image" >> .local/failed.log
        #     errors+=("${cmd[*]}")
        # fi
    done

    echo "successfully build $manifest"
)
