# Operations Runbook

Operational procedures for the Home Cleaning Service Marketplace API and related release artifacts. This is manual guidance — the repository does not ship fake automation for cloud incidents.

Placeholders only. No real secrets.

---

## Health and readiness

```bash
curl -sS https://api.example.com/api/v1/health
curl -sS https://api.example.com/api/v1/ready
```

* **Health** — process up; reports `environment` from process env (prefer aligning probe env with runtime).
* **Ready** — Mongo configured and pingable; otherwise `503` / `database_unavailable`.

Wire orchestrator liveness → health, readiness → ready.

---

## Deployment

1. Build and push image per [backend-container-runbook.md](backend-container-runbook.md).
2. Inject production env (`APP_ENV=production`, Mongo URI, access-token secret, origins, commission). Set `PORT` only to a valid integer `1`–`65535`, or omit it to use `8080`. An invalid explicit `PORT` fails container startup before the API serves.
3. Ensure indexes (controlled operator job) if first deploy or after restore.
4. Roll out containers behind TLS proxy.
5. Verify health/ready and a non-destructive authenticated smoke call in a staging project first when possible.
6. Build Android release against the HTTPS API per [android-release-runbook.md](android-release-runbook.md).

---

## Rollback

* Redeploy previous known-good image tag with previous env revision if needed.
* Access-token secret rollbacks re-validate JWTs signed with that secret — coordinate user sessions.
* Prefer forward fixes for application bugs; use image rollback for bad releases.
* Do not “fix” production by setting `APP_ENV=development` on a public cluster.

---

## Index ensure

```bash
cd backend
dart pub get
dart run tool/ensure_database_indexes.dart
```

Requires `MONGODB_URI`. Prints sanitized index status. Does not dump user documents. Re-run after Atlas restore.

---

## Secret rotation

### `ACCESS_TOKEN_SECRET`

1. Generate a new high-entropy secret (≥32 UTF-8 bytes).
2. Deploy API tasks with the new secret (rolling or brief maintenance).
3. Existing access JWTs fail until clients refresh/login.
4. Retire the old secret from the secret store after drain.
5. Never log either value.

### MongoDB Atlas credentials

1. Create new DB user or rotate password in Atlas.
2. Update `MONGODB_URI` in the secret store.
3. Restart/redeploy API so all tasks pick up the URI.
4. Revoke old credentials after confirming readiness green.
5. Update any operator laptops’ ignored local `.env` separately — do not email URIs.

### Sandbox webhook secrets

Development/test only. Rotate in non-prod env files/secret stores. Production payment/payout provider secrets are future work — document them the same way when integrated.

---

## Atlas availability incident

Symptoms: ready `503`, elevated API errors, timeouts.

1. Check Atlas status and cluster metrics.
2. Confirm URI/network access (IP allow list / private endpoint) without printing URI to tickets.
3. If cluster paused/restoring, communicate read-only/outage to stakeholders.
4. Avoid destructive maintenance on production without backup snapshot.
5. After recovery: ready probe green → smoke auth → watch error rates.

---

## Provider outage behavior (current production)

| Capability | Production behavior |
| --- | --- |
| Email verification / reset delivery | Unavailable — no SMTP; do not claim mail sent |
| Sandbox payment | Unavailable — no silent fallback |
| Sandbox payout | Unavailable — no silent fallback |
| Dev simulate routes | 404 |

If a future real provider outage occurs: keep webhooks idempotent, do not dual-write shortcuts, use reconciliation for financial drift.

---

## Financial reconciliation

Admin read-only:

`GET /api/v1/admin/finance/reconciliation`

Detects certain missing earnings / refund adjustment mismatches. It does **not** auto-heal Atlas documents. Investigate with booking/payment ids; repair via controlled future tooling or careful manual ops with dual control.

---

## Suspicious session response

Indicators: refresh replay detection, user reports account takeover, leaked password.

1. Force password reset flow (requires email provider in real prod) or admin-assisted credential reset process.
2. Revoke sessions via account session APIs / revoke-all paths.
3. Rotate `ACCESS_TOKEN_SECRET` if the signing secret itself leaked (global impact).
4. Review audit logs for admin actions around the incident window.
5. Document timeline; do not store recovered tokens in tickets.

---

## Log review

* Collect container stdout/stderr in your platform.
* Filter by request id when clients supply/receive it.
* Search for spikes of `internal_error` / `401` / `403` / webhook signature failures.
* Scrub any accidentally captured secrets before sharing logs externally.

---

## Backup / restore reference

* Enable Atlas managed backups for real user data environments.
* Retention: per Atlas tier and business policy.
* Test restore into an isolated non-production project periodically.
* After restore: run index ensure; verify login and a booking read path in that non-prod environment.
* Never restore production data onto developer laptops without authorization.
* Secrets are **not** inside DB backups — restore from the secrets manager.

---

## Related

* [deployment-architecture.md](deployment-architecture.md)
* [environment-reference.md](environment-reference.md)
* [../security/final-security-audit.md](../security/final-security-audit.md)
* [../final/production-readiness-gap-register.md](../final/production-readiness-gap-register.md)
