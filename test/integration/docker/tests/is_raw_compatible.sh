#!/bin/sh

set -eu

. /integration/tests/api.sh

volume="$(volume_name raw_data)"
repo="$(restic_repo "$volume")"

echo 'foo' > /mnt/raw_data/foo
mkdir -p /mnt/raw_data/subdir
echo 'bar' > /mnt/raw_data/subdir/bar

expected_foo="$(cat /mnt/raw_data/foo)"
expected_bar="$(cat /mnt/raw_data/subdir/bar)"

bivac_backup "$volume"

test_foo="$(restic_dump "$repo" "/var/lib/docker/volumes/$volume/_data/foo")"
test_bar="$(restic_dump "$repo" "/var/lib/docker/volumes/$volume/_data/subdir/bar")"

if [ "$test_foo" != "$expected_foo" ]; then
  echo "$test_foo != \"$expected_foo\"." >&2
  exit 1
fi

if [ "$test_bar" != "$expected_bar" ]; then
  echo "$test_bar != \"$expected_bar\"." >&2
  exit 1
fi
