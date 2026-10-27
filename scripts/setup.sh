#!/usr/bin/env bash
# First-time setup: env files, JWT keys, containers, app keys, migrations.
set -euo pipefail

infra="$(cd "$(dirname "$0")/.." && pwd)"
cd "$infra/.."

[ -f famexus-infra/.env ] || cp famexus-infra/.env.example famexus-infra/.env
[ -f famexus-web/.env.local ] || cp famexus-web/.env.example famexus-web/.env.local
for repo in famexus-gateway famexus-todo famexus-calendar wallit; do
  [ -f "$repo/.env" ] || cp "$repo/.env.example" "$repo/.env"
done

"$infra/scripts/generate-jwt-keys.sh"

cd "$infra"
docker compose up -d --build

echo "Waiting for the PHP services to finish composer install..."
for svc in gateway todo calendar wallit; do
  until docker compose exec -T "$svc" test -f vendor/autoload.php 2>/dev/null; do sleep 3; done
  if ! docker compose exec -T "$svc" grep -q '^APP_KEY=base64' .env; then
    docker compose exec -T "$svc" php artisan key:generate
  fi
  docker compose exec -T "$svc" php artisan migrate --force
done

echo
echo "Famexus is up:"
echo "  App      http://localhost:5173"
echo "  Gateway  http://localhost:8000/api/v1/ping"
echo "  Mailpit  http://localhost:8025"
