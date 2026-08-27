# ADR-020 — Production Deployment and Release Readiness

## Status

Accepted

## Context

Through TASK 021 the Home Cleaning Marketplace implements the major functional system (auth/account security, customer/cleaner/admin workflows, sandbox payment and payout ledgers, release-candidate UX, and fake-only acceptance coverage). The remaining gap for a portfolio “final” release was not more marketplace features, but **production-configuration safety**, **deployment packaging**, **CI**, **release verification**, and **honest audits** of security, scalability, and production blockers.

The project intentionally does **not** integrate production SMTP, card networks, or real payout rails. Therefore the release must be able to become **SOFTWARE RELEASE READY** without falsely claiming **FULLY PRODUCTION SERVICE READY**.

## Decision

- **Explicit production config validation** via `validateServerConfig` at API middleware boot (`APP_ENV` known; production requires Mongo URI, access-token secret ≥32 UTF-8 bytes, non-empty `ALLOWED_ORIGINS`, explicit valid `PLATFORM_COMMISSION_BPS`; reject CORS `*`).
- **No sandbox fallback in production** for payments, payouts, or development account-action delivery; `/api/v1/dev` remains unavailable in production.
- **HTTPS-only Flutter release API** enforced by `AppConfig` validation on `API_BASE_URL`.
- **Android cleartext disabled in release** (`usesCleartextTraffic="false"` on the main manifest); debug-only cleartext exceptions for local emulator hosts.
- **Stable Android application ID** `com.homecleaningmarketplace.app` (namespace aligned).
- **Runtime secret injection** for containers; `.dockerignore` excludes `.env`; secrets never embedded in Flutter.
- **Backend Docker packaging** with multi-stage `backend/Dockerfile`, non-root runtime user, port `8080`.
- **CI without production secrets** (`.github/workflows/ci.yml`: format/analyze/test; Flutter debug APK; no Atlas).
- **Release verification tooling** (`tools/release_check.dart`) for hygiene and optional test gates.
- **Target-neutral deployment architecture** documented under `documentation/deployment/`.
- **Production-provider gap honesty** in final/security docs and UI sandbox labeling.
- **Scalability roadmap** as staged planning guidance without unverified million-user claims.

## Alternatives Considered

### Hard-code production API URL

Rejected. Prevents environment promotion and forces rebuilds/forks per environment; `--dart-define=API_BASE_URL` remains explicit and public.

### Bundle backend secrets in Flutter

Rejected. Mobile binaries are extractable; Mongo URI and signing secrets must stay server-side / operator-side.

### Keep `com.example.project`

Rejected. Placeholder identity is unsuitable for release auditing and store packaging; stable id `com.homecleaningmarketplace.app` adopted.

### Allow cleartext API in release

Rejected. Release traffic must use HTTPS; cleartext remains debug-only for local backends.

### Automatically use sandbox providers in production/demo

Rejected. Would falsify financial and email behavior; production must surface provider unavailable instead.

### Commit release signing key

Rejected. Keystores and `key.properties` remain outside git; local debug signing fallback is explicitly non-Play-ready.

### Auto-deploy from current CI

Deferred/rejected for now because no cloud target/credentials are selected. CI verifies; humans deploy.

### Claim one-million-user scalability without load testing

Rejected. Document horizontal-friendly elements and redesign needs instead.

### Integrate multiple infrastructure platforms

Deferred. Keep Docker + Atlas + operator TLS proxy as the portable baseline.

## Consequences

* Production misconfiguration fails at boot rather than running half-secure.
* Portfolio demos must use development/test for sandbox simulate flows, or accept unavailable providers in production builds.
* Operators must supply TLS, secrets, Atlas, and (later) real providers — the repo supplies packaging and docs, not cloud accounts.
* Android store release still requires an external keystore and legal/store listing work (P0 gaps).
* Documentation set under `security/`, `deployment/`, and `final/` becomes the audit trail for readiness claims.

## Security

* Argon2id passwords; JWT + refresh rotation/replay; hashed account-action tokens; role authorization unchanged in intent.
* Generic client errors for unhandled exceptions; security headers (`nosniff`, `referrer-policy`); CORS allow-list.
* Final security audit recorded in `documentation/security/final-security-audit.md` without claiming pentest/certification.
* Secret rotation and backup guidance live in deployment operations docs.

## Deployment

* Container runbook, Android release runbook, environment reference, and operations runbook under `documentation/deployment/`.
* Index ensure remains a deliberate operator step (`dart run tool/ensure_database_indexes.dart`).
* CI and `release_check.dart` gate software quality without needing production credentials.

## Scalability

* Stateless API replicas + Atlas indexes are the growth baseline.
* Staged roadmap 0–1k → 1k–10k → 10k–100k → 100k–1M in `documentation/architecture/scalability-and-growth-review.md`.
* Known consistency limits (overlap, best-effort side effects, polling, no queue) remain explicit.

## Production Blockers

* Real email delivery
* Real payment provider
* Real payout provider (if payouts offered at launch)
* Legal/privacy/terms
* Production domain/TLS hosting
* Secrets manager + release signing process
* Atlas backup policy, monitoring/alerting, incident response staffing
* Privacy/security review beyond internal audit

See `documentation/final/production-readiness-gap-register.md`.

## Deferred Decisions

* Real email / payment / payout provider selection and implementation
* MFA
* Distributed rate limiting
* Queue/outbox and background workers
* WebSocket/SSE chat
* Advanced monitoring vendor / crash reporting SDK
* Cloud deployment target and automated infrastructure provisioning
* Load testing program
* Multi-region deployment
