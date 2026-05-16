#!/bin/sh

TARGET_URL="s3:http://s3:8333/testing"
HOSTNAME="$(docker info --format '{{.Name}}')"

compose() {
  docker compose --file /integration/docker-compose.yml "$@"
}

restic_repo() {
  printf '%s/%s/%s' "$TARGET_URL" "$HOSTNAME" "$1"
}

volume_name() {
  logical_name="$1"

  volume="$(compose config --format json | jq -r ".volumes.${logical_name}.name")"

  if [ -z "$volume" ] || [ "$volume" = "null" ]; then
    echo "failed to resolve compose volume name for $logical_name" >&2
    exit 1
  fi

  printf '%s' "$volume"
}

bivac_backup() {
  compose exec --no-TTY bivac bivac backup "$1"
}

bivac_restore() {
  compose exec --no-TTY bivac bivac restore "$1"
}

create_s3_bucket() {
  compose exec --no-TTY s3 sh -c 'echo "s3.bucket.create -name testing" | weed shell'
}

restic_dump() {
  repo="$1"
  path="$2"
  compose exec --no-TTY bivac sh -c "restic -q -r '$repo' dump latest '$path'"
}

recreate_service_volume() {
  service="$1"
  logical_volume="${service}_data"
  mount_path="/mnt/$logical_volume"

  volume_name "$logical_volume" >/dev/null

  compose stop "$service"
  compose rm --force "$service"
  find "$mount_path" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  compose up -d --wait "$service"
}
