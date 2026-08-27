# Backend Container Runbook

**Image source:** `backend/Dockerfile`  
**Runtime user:** non-root `appuser` (uid 10001)  
**Default port:** `8080` (when `PORT` is absent; Dockerfile also sets `ENV PORT=8080`)  
**Bind:** Dart Frog generated `InternetAddress.anyIPv6` (all-interface; suitable for containers)  
**PORT validation:** repository-owned custom entrypoint (`backend/main.dart`) fails startup for an explicitly invalid `PORT` before serving  
**Never:** bake `backend/.env` or real secrets into the image (see `backend/.dockerignore`)

## Build image

From the repository `backend/` directory (placeholders only):

```bash
docker build -t home-cleaning-api:1.0.0+1 .
```

Multi-stage build: Dart stable compile of Dart Frog server → `debian:bookworm-slim` runtime with `ca-certificates`.

## Run container

```bash
docker run --rm -p 8080:8080 \
  -e APP_ENV=production \
  -e PORT=8080 \
  -e MONGODB_URI='mongodb+srv://USER:PASSWORD@CLUSTER/DB?retryWrites=true&w=majority' \
  -e ACCESS_TOKEN_SECRET='REPLACE_WITH_LONG_RANDOM_SECRET_AT_LEAST_32_BYTES' \
  -e ALLOWED_ORIGINS='https://admin.example.com' \
  -e PLATFORM_COMMISSION_BPS=1500 \
  home-cleaning-api:1.0.0+1
```

Prefer platform secret injection (Docker/Kubernetes/cloud secret stores) over shell history. Do not commit the real URI or secrets.

Sandbox webhook secrets are **not required** in production and do not enable sandbox providers there.

## Runtime environment

See [environment-reference.md](environment-reference.md).

**`PORT`:** optional. Absent → listen on `8080`. Explicit valid integer `1`–`65535` → use that port. Explicit invalid value (empty, non-numeric, `0`, negative, `>65535`) → process exits non-zero **before** accepting connections. Supported production command is this container image (`CMD ["/app/bin/server"]`), which includes the custom entrypoint validation.

Production boot also calls `validateServerConfig` and fails if Mongo URI, access-token secret (≥32 UTF-8 bytes), non-empty `ALLOWED_ORIGINS`, or explicit valid `PLATFORM_COMMISSION_BPS` are missing/invalid.

## Health and readiness

| Probe | Path | Expectation |
| --- | --- | --- |
| Liveness | `GET /api/v1/health` | `200` with service/environment (does not require Mongo) |
| Readiness | `GET /api/v1/ready` | `200` when Mongo ping succeeds; `503 database_unavailable` otherwise |

Example:

```bash
curl -sS https://api.example.com/api/v1/health
curl -sS https://api.example.com/api/v1/ready
```

## TLS termination

Terminate TLS at the reverse proxy / load balancer. The container serves HTTP on `PORT` inside the private network. Configure HSTS and certificates on the proxy, not inside the Dart process.

## Secrets injection

* Pass env vars at runtime
* Rotate by updating the secret store and performing a rolling restart
* Confirm new tasks receive new values; drain old tasks

## Start / stop

* Start: orchestrator `docker run` / service create / deploy revision
* Stop: SIGTERM via orchestrator stop; allow in-flight requests to finish where the platform supports graceful stop

## Rolling deployment considerations

* Keep at least one healthy readiness-passing task when possible
* API is stateless for access JWTs; refresh tokens live in Mongo — rolling restarts are compatible
* Changing `ACCESS_TOKEN_SECRET` invalidates outstanding access JWTs (plan brief re-auth)

## Safe index ensure step

Indexes are **not** created on every HTTP request. After first deploy or restore, from a trusted operator environment with the same `MONGODB_URI`:

```bash
cd backend
dart pub get
# with production URI available in env or ignored local .env — never commit it
dart run tool/ensure_database_indexes.dart
```

The tool prints sanitized status only (no document dumps).

## Rollback

* Redeploy previous image tag
* Keep Atlas data intact unless a bad migration occurred (this project uses index ensure, not destructive schema migrations)
* If config is wrong, fix env and restart; production validation should prevent boot with empty critical secrets

## Logs

* Container stdout/stderr
* Unhandled errors return generic JSON `internal_error` to clients
* Correlate with request id header when present
* Never log Mongo URIs, passwords, JWTs, refresh tokens, or webhook secrets

## Production provider limitations

* Email delivery: unavailable (no SMTP integration)
* Payment sandbox: unavailable
* Payout sandbox: unavailable
* `/api/v1/dev/*` must not be usable (404 in production)

Do not override `APP_ENV` to `development` in a public deployment to “make payments work.”
