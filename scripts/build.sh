#!/usr/bin/env bash
# Updates the app after a code change, without rebuilding images: installs
# Composer and npm dependencies, runs migrations, restarts queue workers and
# builds the React app. Stops at the first error. Keeps all data.
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

# Everything runs inside the containers: vendor/ and node_modules live in their
# volumes and the database is only reachable there. This starts a stopped stack
# and does nothing to a running one.
if ! docker compose --progress quiet up -d --wait --wait-timeout 600; then
  echo "Some containers didn't start; check docker compose ps and docker compose logs." >&2
  exit 1
fi

for svc in gateway todo calendar wallit; do
  echo "== $svc"
  docker compose exec -T "$svc" composer install --no-interaction --quiet
  docker compose exec -T "$svc" php artisan migrate --force
done

for svc in calendar wallit; do
  docker compose exec -T "$svc" php artisan queue:restart
done

echo "== web"
docker compose exec -T web sh -c 'npm ls >/dev/null 2>&1 || npm ci --no-audit --no-fund'
docker compose exec -T web npm run build

echo
echo "Famexus is up to date: http://localhost"
