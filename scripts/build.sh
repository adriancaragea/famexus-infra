#!/usr/bin/env bash
# Brings the running stack up to date after a code change: rebuilds images,
# installs new dependencies, recreates what changed, runs migrations, restarts
# queue workers and reloads Caddy. Keeps all data. Safe to run at any time.
#
# Usage: ./scripts/build.sh
set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

cd "$(dirname "$0")/.."

if [ ! -f .env ] || [ ! -f ../famexus-gateway/.env ]; then
  echo "Famexus isn't set up yet; run ./scripts/setup.sh first." >&2
  exit 1
fi

docker compose build

# node_modules lives in a named volume, so a rebuilt image alone doesn't update it.
docker compose run --rm --no-deps -T web sh -c 'npm ls >/dev/null 2>&1 || npm ci --no-audit --no-fund'

# The PHP containers run composer install as they start; --wait holds until they're healthy.
if ! docker compose up -d --wait --wait-timeout 600; then
  echo "Some containers didn't start; check docker compose ps and docker compose logs." >&2
  exit 1
fi

for svc in gateway todo calendar wallit; do
  echo "Migrating $svc..."
  docker compose exec -T "$svc" php artisan migrate --force
done

# Workers keep the old .env in memory until restarted, and Caddy's config is a bind mount.
docker compose restart calendar-worker wallit-worker
docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile

echo
echo "Famexus is up to date: http://localhost"
