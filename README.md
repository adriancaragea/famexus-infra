# famexus-infra

Local environment for Famexus. It wires the five app repos together with docker-compose; each app keeps its own `Dockerfile` and can build and test on its own. Deployment config will live here later.

## What runs

| Container | Port on your machine | Notes |
|---|---|---|
| `web` | http://localhost:5173 | React app (Vite dev server), proxies `/api` and `/sanctum` to the gateway |
| `gateway` | http://localhost:8000 | Login, users, families, ACL; the only backend the app talks to |
| `todo`, `calendar`, `wallit` | not published | Reachable only from the gateway on the Docker network |
| `mysql` | 3306 | MySQL 8.4, one database + one user per service |
| `redis` | not published | Queues and cache |
| `mailpit` | http://localhost:8025 | Catches outgoing email (password resets) |
| `caddy` | http://localhost | Optional, `--profile proxy`: one origin for app + API |
| `calendar-worker`, `wallit-worker` | | Optional, `--profile workers`: queue workers for sync and CSV import |

## First run

All repos must sit side by side:

```
famexus/
  famexus-infra/
  famexus-web/
  famexus-gateway/
  famexus-todo/
  famexus-calendar/
  wallit/
```

```sh
./scripts/clone-all.sh     # only needed on a fresh machine; clones the others from GitHub
./scripts/setup.sh         # .env files, JWT keys, build + start, app keys, migrations
```

Needs Docker Desktop and `openssl`. You do not need PHP, Composer or Node on your machine; dependencies are installed inside the containers.

## Day to day

```sh
docker compose up -d                       # start
docker compose --profile workers up -d     # start with queue workers
docker compose logs -f gateway             # follow one service
docker compose exec gateway php artisan migrate
docker compose exec wallit composer test
docker compose down                        # stop (data stays in volumes)
docker compose down -v                     # stop and wipe MySQL + vendor volumes
```

## Files

- `docker-compose.yml`: all containers, one internal network
- `mysql/init/01-databases.sh`: creates `famexus_gateway`, `famexus_todo`, `famexus_calendar`, `wallit` and a user for each (runs only on an empty volume)
- `caddy/Caddyfile`: optional reverse proxy; becomes the HTTPS front door on a VPS later
- `.env.example`: host ports and database passwords
- `scripts/clone-all.sh`, `scripts/setup.sh`, `scripts/generate-jwt-keys.sh`

## JWT between gateway and services

The gateway signs a 60-second RS256 JWT for each forwarded request. `scripts/generate-jwt-keys.sh` creates the key pair in `famexus-gateway/storage/keys/` and copies the public key into each service. Keys are git-ignored in every repo.
