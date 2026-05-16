#!/bin/sh

set -eu

. /integration/tests/api.sh

volume="$(volume_name postgres_data)"

compose exec --no-TTY postgres psql -U postgres bivac <<'SQL'
CREATE TABLE users(
  id    SERIAL PRIMARY KEY,
  email VARCHAR(40) NOT NULL UNIQUE
);

INSERT INTO users(email)
SELECT
  'user_' || seq || '@' || (
    CASE (RANDOM() * 2)::INT
      WHEN 0 THEN 'gmail'
      WHEN 1 THEN 'hotmail'
      WHEN 2 THEN 'yahoo'
    END
  ) || '.com' AS email
FROM GENERATE_SERIES(1, 10) seq;
SQL

bivac_backup "$volume"

recreate_service_volume postgres
bivac_restore "$volume"

count="$(compose exec --no-TTY postgres psql -U postgres -d bivac --no-TTY -A -t -c "select count(*) from users")"
if [ "$count" != "10" ]; then
  echo "expected 10 postgres users, got $count" >&2
  exit 1
fi
