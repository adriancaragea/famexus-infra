# famexus-infra

Local environment for Famexus. It wires the five app repos together with docker-compose; each app keeps its own `Dockerfile` and can build and test on its own. Deployment config will live here later.

## What runs

Open the app at **http://localhost**. Caddy is the front door: `/` goes to the React app, `/api` and `/sanctum` to the gateway.

| Container | Port on your machine | Notes |
|---|---|---|
| `caddy` | http://localhost | Front door: one origin for app + API; HTTPS on a VPS later |
| `web` | 5173 (debug) | React app (Vite dev server) |
| `gateway` | 8000 (debug) | Login, users, families, ACL; the only backend the app talks to |
| `todo`, `calendar`, `wallit` | not published | Reachable only from the gateway on the Docker network |
| `calendar-worker`, `wallit-worker` | | Queue workers (Google sync, CSV import) |
| `calendar-scheduler`, `wallit-scheduler` | | Run scheduled jobs (calendar sync, daily net worth snapshot) |
| `mysql` | 3306 (debug) | MySQL 8.4, one database + one user per service |
| `redis` | not published | Queues and cache |
| `mailpit` | http://localhost:8025 | Catches outgoing email (password resets) |

The PHP apps run on FrankenPHP (each app's own `Dockerfile`). Workers and schedulers use the same image and start once their service is healthy. The "debug" ports let you hit the Vite server, the gateway or MySQL directly with your own tools.

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
docker compose up -d                       # start everything
docker compose logs -f gateway             # follow one service
docker compose exec gateway php artisan migrate
docker compose exec wallit composer test
./scripts/stop.sh                          # stop everything (data stays in volumes)
./scripts/stop.sh --wipe-data              # stop and delete MySQL + vendor volumes (asks to confirm)
```

## Files

- `docker-compose.yml`: all containers, one internal network
- `mysql/init/01-databases.sh`: creates `famexus_gateway`, `famexus_todo`, `famexus_calendar`, `wallit` and a user for each (runs only on an empty volume)
- `caddy/Caddyfile`: the front door; becomes the HTTPS front door on a VPS later
- `.env.example`: host ports and database passwords
- `scripts/clone-all.sh`, `scripts/setup.sh`, `scripts/stop.sh`, `scripts/generate-jwt-keys.sh`

## JWT between gateway and services

The gateway signs a 60-second RS256 JWT for each forwarded request. `scripts/generate-jwt-keys.sh` creates the key pair in `famexus-gateway/storage/keys/` and copies the public key into each service. Keys are git-ignored in every repo.
