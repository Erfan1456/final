# Cursor Task 022 — Production Deployment, Release, and Final Audit

## Metadata

- Task ID: 022
- Task title: Production Configuration, Deployment Packaging, CI, Release Security, Scalability Audit, and Final Project Completion Review
- Date: 2026-08-27
- Git branch: main (TASK 022 uncommitted for ChatGPT review)
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Backend root: D:\freelance\erfankhan_cse489\final\backend
- Status: SUCCESS (TASK 022C2 production PORT fail-fast validation applied)

## Objective

Final major implementation/release task: production environment validation, Flutter release HTTPS rules, Android identity/network/signing honesty, Dart Frog production packaging, Docker + CI without secrets, release_check tooling, security/scalability/completeness audits, deployment documentation, ADR-020, and an honest SOFTWARE RELEASE READY vs FULLY PRODUCTION SERVICE READY verdict. No live Atlas mutation. No commit.

## Pre-Task Verification

- Branch: `main`
- Working tree: clean at start
- HEAD: TASK 021 already committed as `93d3c57` `release_candidate_ux_accessibility_and_acceptance` on `main`; clean tree
- `documentation/cursor/021...` Status SUCCESS with 021C/C2/C3 notes
- Backend baseline: `dart analyze` clean; **502 passed**
- Flutter baseline: `flutter analyze` clean; **433 passed**; debug APK success

## Dependencies

- No new Flutter third-party packages required for release packaging
- No new backend packages required for CORS/security-header/request-id middleware
- CI pins Dart **3.13.1** and Flutter **3.47.1**; workflow contains no secrets
- Docker packaging files added; Docker engine unavailable on this machine (build not executed)

## PART A — Production Environment Model

Production/boot validation via `backend/lib/src/config/configuration_validation.dart` + `ServerConfig`: known `APP_ENV`; production requires Mongo URI, access-token secret ≥32 bytes, non-empty `ALLOWED_ORIGINS` (no `*`), valid `PLATFORM_COMMISSION_BPS`. Sandbox payments/payouts and development account delivery are refused outside development|test. Env examples: `backend/.env.example`, `backend/.env.production.example`; reference doc `documentation/deployment/environment-reference.md`.

## PART B — Flutter Release Configuration

`AppConfig` release builds require non-empty absolute `https://` `API_BASE_URL` via `--dart-define`; debug may use empty/http local URLs. Covered by `project/test/core/config/app_config_test.dart`. Android release runbook documents the define. Release APK/AAB built successfully with `API_BASE_URL=https://api.example.invalid`.

## PART C — Backend Production Build

`dart_frog list` shows routes present. `dart_frog build` succeeds (`build/` ignored). Production packaging path documented for container/runtime injection of env (no secrets baked into image/source).

## PART D — Docker Packaging

Created `backend/Dockerfile` (multi-stage Dart Frog + `dart compile exe`, non-root user, `PORT=8080`, no baked secrets) and `backend/.dockerignore` (excludes `.env` / secrets while keeping examples). **`docker build` NOT EXECUTED — Docker unavailable.** Structural audit **PASS**. Local equivalent build-stage (`dart_frog build` + `dart compile exe build/bin/server.dart -o build/bin/server`) **PASS**. Runbook: `documentation/deployment/backend-container-runbook.md`.

## PART E — Continuous Integration

Added `.github/workflows/ci.yml` with Dart **3.13.1** and Flutter **3.47.1**; PR + push `main`; format/analyze/test; Flutter debug APK; **no secrets**, no live Atlas, no release signing, no Docker push/deploy. Doc: `documentation/testing/continuous-integration.md`.

## PART F — Release Verification Tool

Added `tools/release_check.dart`: hygiene (ignored secrets/artifacts, required dirs); default backend analyze+test; `--quick` hygiene only; `--full` includes Flutter. Never prints secrets / mutates Atlas. Verified: `dart tools/release_check.dart` (default) **PASS** (hygiene + backend analyze + backend **511** tests); `--quick` also **PASS**. Doc: `documentation/testing/release-verification.md`.

## PART G — Safe Production-Mode Verification

Provider resolvers return no sandbox in production; tests assert sandbox prohibition for payments/payouts and configuration flags. Optional production live GET skipped (no need to mutate/print secrets). Live Atlas mutation: **none**.

## PART H — Final Security Audit

CORS allow-list only (never `*`); `Idempotency-Key` and `X-Request-Id` in `Access-Control-Allow-Headers`. Security headers: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` (HSTS deferred to reverse proxy). `X-Request-Id` accept/generate + echo. Middleware catch-all returns generic `internal_error` without leaking exception detail; production suppresses stderr dumps. Documented in `documentation/security/final-security-audit.md`.

## PART I — Scalability Audit

Documented staged growth limits/roadmap in `documentation/architecture/scalability-and-growth-review.md` (polling chat/notifications, no distributed rate limit/cache/queue proof, best-effort side effects, no 100k–1M load-test claim).

## PART J — Final Functional Completeness Audit

Portfolio functional system covered (auth, customer/cleaner/admin workflows, ledger/sandbox honesty). Recorded in `documentation/final/functional-completeness.md` and completion summary.

## PART K — Production Readiness Gap Register

Honest blockers registered in `documentation/final/production-readiness-gap-register.md`: real email, payment, payout providers; TLS/domain/hosting; secrets manager/monitoring/backups; release signing credentials for Play; legal/privacy content.

## PART L — Deployment Architecture Documentation

Added `documentation/deployment/`: architecture, environment reference, backend container runbook, Android release runbook, operations runbook, index README. Target-neutral; operator provides TLS/proxy/Atlas.

## PART M — CI / Release Documentation

CI and release-verification docs under `documentation/testing/`; README indexes updated (root, backend, Flutter, documentation).

## PART N — Release Version / Build Metadata

Exact versions (unchanged by TASK 022C):

- Flutter `project/pubspec.yaml`: **`1.0.0+1`**
- Backend `backend/pubspec.yaml`: **`1.0.0+1`**

Android identity stabilized (see Final Verification). No Git tag created.

## PART O — Final Test / Build Matrix

See Final Verification table below (analyze/test/APK/AAB/`dart_frog`/`release_check`).

## PART P — Final Repository Audit

Secrets stay out of git (`.env` ignored; `key.properties`/keystores ignored); no forbidden release artifacts committed; CI without secrets; Docker files present; TASK 022 left **uncommitted** by design.

## Android Identity / Network / Signing

- `applicationId` / `namespace`: `com.homecleaningmarketplace.app`
- Label: Home Cleaning Marketplace
- `INTERNET` in main manifest
- `usesCleartextTraffic=false` in main
- Debug cleartext via debug `networkSecurityConfig` only
- Signing: debug signing when `key.properties` absent — **NOT Play Store ready**

## CORS + Idempotency-Key / Request Hardening (summary)

| Concern | Implementation |
|---------|----------------|
| CORS | Allow-list origins only; never `*` |
| Headers allowed | Includes `Idempotency-Key`, `X-Request-Id` |
| Security headers | `nosniff`, `no-referrer` |
| Request id | Safe inbound or generated opaque id echoed |
| Errors | Generic 500 `internal_error`; no stack/Mongo leaks to clients |

## Provider Sandbox Prohibition

Production `APP_ENV` never allows sandbox payments/payouts or development delivery flags; payment/payout resolvers return null / unavailable in production; covered by configuration and feature tests.

## Documentation / ADR

- `documentation/decisions/ADR-020-production-deployment-and-release-readiness.md`
- `documentation/final/project-completion-summary.md`
- `documentation/final/production-readiness-gap-register.md`
- `documentation/final/functional-completeness.md`
- `documentation/security/final-security-audit.md`
- `documentation/architecture/scalability-and-growth-review.md`
- Deployment + CI/release verification docs as above

## Final Verification

### BACKEND

| Check | Result |
|-------|--------|
| `dart format --output=none --set-exit-if-changed .` | **PASS** (exit 0; 420 source files; run with no local `build/` present — generated `build/bin/server.dart` is not a format gate target; CI builds after format) |
| `dart analyze` | **No issues found!** |
| `dart test` | **522 passed** |
| `dart_frog list` | Routes present |
| `dart_frog build` | Success (`build/` gitignored) |

### FLUTTER

| Check | Result |
|-------|--------|
| `dart format --output=none --set-exit-if-changed lib test` | **PASS** (exit 0; 233 files, 0 changed) |
| `flutter analyze` | **No issues found!** |
| `flutter test` | **434 passed** |
| `flutter build apk --debug` | Success (TASK 022; Flutter/Android production source unchanged in 022C — result stands) |
| `flutter build apk --release --dart-define=API_BASE_URL=https://api.example.invalid` | Success (TASK 022; stands) |
| `flutter build appbundle --release` same define | Success (TASK 022; stands) |
| Signing | Debug signing when `key.properties` absent — **NOT Play Store ready** |
| Android applicationId/namespace | `com.homecleaningmarketplace.app`; label Home Cleaning Marketplace; INTERNET in main; `usesCleartextTraffic=false` in main; debug cleartext via debug `networkSecurityConfig` |

### RELEASE TOOL

| Check | Result |
|-------|--------|
| `dart tools/release_check.dart` (default) | **PASS** — hygiene + PORT startup boundary + backend analyze + backend test (**522**); exit success |
| `dart tools/release_check.dart --quick` | **PASS** (hygiene only; recorded separately) |

### DOCKER

| Check | Result |
|-------|--------|
| Docker engine | **NOT AVAILABLE** (`docker build` not executed; not a TASK 022 blocker) |
| Dockerfile structural audit | **PASS** — multi-stage paths valid; `pubspec.*` copied; `.dockerignore` excludes `.env` / `.env.*` while keeping `!.env.example` / `!.env.*.example`; no secret `ARG`; non-root `appuser` (uid 10001); runtime binary `/app/bin/server` matches compile output; `ENV PORT=8080` + `EXPOSE 8080`; custom entrypoint baked into compiled server validates PORT before bind |
| Local equivalent build-stage validation | **PASS** — `dart_frog build` + `dart compile exe build/bin/server.dart -o build/bin/server` produced `build/bin/server` |

### RUNTIME

| Check | Result |
|-------|--------|
| Production bind address | Dart Frog generated `build/bin/server.dart`: **`InternetAddress.anyIPv6`** — all-interface bind (dual-stack on typical Linux containers; **not** localhost-only). Suitable for container publish. Documented as all-interface via `InternetAddress.anyIPv6` (not a literal `0.0.0.0` source bind). |
| PORT source | Environment variable `PORT` |
| PORT absent | **8080** |
| PORT valid explicit | Integer **1–65535** accepted |
| PORT invalid explicit | **Startup fails non-zero** before serving (empty / non-numeric / `0` / negative / `>65535`) via repository-owned `backend/main.dart` + `PortConfig` |
| Supported production deployment | Container image `CMD ["/app/bin/server"]` built with custom entrypoint (validated startup boundary). Generated `tryParse` fallback remains in `build/bin/server.dart` but is overridden by `run` before bind. |
| Graceful shutdown audit | Generated production server has **no** SIGTERM/SIGINT / shutdown hook. `MongoDatabase.close()` exists in library code but is **not** wired to process lifecycle. Container stop → process kill; Mongo cleanup is a **documented non-blocking deployment/runtime limitation**. No invented framework hook; generated files not edited. |

### REPOSITORY

| Check | Result |
|-------|--------|
| `git check-ignore -v backend/.env` | Ignored (`.gitignore:8:.env`) |
| Forbidden tracked artifacts | None (`release_check` + `git ls-files` review) |
| `git diff --check` | Clean (exit 0; CRLF normalization warnings only) |
| Final git state | TASK 022 / 022C changes **unstaged / uncommitted** by design |
| Versions | Flutter **`1.0.0+1`**; backend **`1.0.0+1`** |
| Live Atlas mutation | **none** |
| **SOFTWARE RELEASE READY** | **YES** |
| **FULLY PRODUCTION SERVICE READY** | **NO** — blockers: real email, payment, payout providers; TLS/domain/hosting; secrets manager/monitoring/backups; release signing credentials for Play; legal/privacy content |
| Commit | **NONE** — leave uncommitted |

## TASK 022C Note

TASK 022C was a **final release-gate evidence and backend runtime packaging audit correction**. It did not restart TASK 022. Gaps closed: default (non-`--quick`) `dart tools/release_check.dart`; explicit backend/Flutter `dart format` gates; audited Dart Frog production bind/`PORT` behavior and graceful-shutdown/Mongo lifecycle (document-only where the framework provides no safe repository hook); Docker structural + local compile-stage validation without installing Docker; exact version metadata; expanded Final Verification matrix. Original **Exact Cursor Prompt** below is unchanged. No commit / tag / push / TASK 023.

## TASK 022C2 Note

TASK 022C2 closed the remaining production `PORT` fail-fast gap without restarting TASK 022. Repository-owned Dart Frog custom entrypoint (`backend/main.dart`) + `PortConfig` validate `PORT` **before** `serve`: absent → 8080; valid explicit 1–65535 → accepted; invalid explicit → non-zero exit (no silent 8080 fallback). Generated `build/bin/server.dart` is not hand-edited; its built-in `tryParse` fallback remains but is overridden by the custom `run` hook on the supported container/compiled path. Focused `PortConfig` tests added; deployment docs and runtime matrix updated. Original **Exact Cursor Prompt** below remains unchanged. No commit / tag / push / TASK 023.

## Exact Cursor Prompt

~~~~text
# TASK 022 — Production Configuration, Deployment Packaging, CI, Release Security, Scalability Audit, and Final Project Completion Review

Repository:

D:\freelance\erfankhan_cse489\final

TASK 021 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

TASK 022 is the FINAL major implementation/release task for the current
Home Cleaning Marketplace portfolio project.

The application now includes the major functional system:

AUTH / SECURITY
- signup;
- email verification architecture;
- login/logout;
- JWT access tokens;
- refresh-token rotation/replay protection;
- password reset;
- password change;
- session management;
- persisted-role authorization.

CUSTOMER
- profile;
- addresses;
- cleaner discovery;
- comparison;
- cleaner details;
- availability;
- booking;
- booking lifecycle;
- payment ledger / sandbox provider;
- chat;
- notifications;
- verified reviews;
- disputes.

CLEANER
- onboarding;
- administrator approval;
- service offerings;
- availability;
- booking/job lifecycle;
- chat;
- notifications;
- reviews;
- disputes;
- earnings;
- payout requests / sandbox provider.

ADMIN
- cleaner approvals;
- users;
- booking oversight;
- payments/refunds;
- review moderation;
- disputes;
- payouts;
- finance/reconciliation;
- append-only audit trail.

RELEASE-CANDIDATE QUALITY
- shared UX foundation;
- responsive layouts;
- accessibility hardening;
- safe loading/empty/error states;
- role-router acceptance coverage;
- cross-role acceptance journeys;
- logout state isolation;
- development/sandbox honesty.

TASK 022 must make the repository:

1. deployment-package ready;
2. production-configuration safe;
3. release-build auditable;
4. CI-verifiable;
5. operationally documented;
6. security-reviewed;
7. scalability-reviewed;
8. portfolio/demo ready;
9. honest about remaining production blockers.

TASK 022 must NOT fabricate external integrations.

======================================================================
FINAL PROJECT STATUS TERMINOLOGY
======================================================================

Use these terms precisely:

SOFTWARE RELEASE READY

means:
- code builds;
- tests pass;
- configuration is hardened;
- deployment artifacts exist;
- secrets are not embedded;
- environment requirements are documented;
- operational runbooks exist.

PRODUCTION SERVICE READY

means:
- all required external production providers and infrastructure are actually
  configured.

The current project MAY become:

SOFTWARE RELEASE READY

without being:

FULLY PRODUCTION SERVICE READY

because production email/payment/payout providers are intentionally not
integrated.

The final audit MUST clearly distinguish those states.

======================================================================
KNOWN EXTERNAL-PROVIDER LIMITATIONS
======================================================================

Current implementation intentionally has:

EMAIL:
development/test account-action delivery only.

PAYMENTS:
development/test sandbox provider only.

PAYOUTS:
development/test sandbox provider only.

Therefore production must NOT claim:

- verification email was sent;
- password-reset email was sent;
- customer card payment was processed;
- real refund was transferred;
- cleaner payout was transferred.

Production provider-unavailable behavior must remain safe.

Do NOT weaken those protections merely to make a "production demo" appear
complete.

======================================================================
DO NOT IMPLEMENT
======================================================================

Do NOT add:

- AI;
- MFA;
- OAuth/social login;
- production SMTP;
- SendGrid;
- Mailgun;
- AWS SES;
- Stripe;
- Stripe Connect;
- PayPal;
- bKash;
- bank-account storage;
- card/CVV storage;
- KYC;
- tax;
- push notifications;
- WebSocket;
- Redis;
- Kafka;
- RabbitMQ;
- Elasticsearch;
- Kubernetes;
- Terraform;
- cloud-vendor SDK;
- analytics SDK;
- crash-reporting SDK;
- distributed tracing vendor;
- another backend language;
- another database;
- another state manager;
- another Flutter router.

Do NOT deploy to an external cloud account.

Do NOT request credentials from the user.

Do NOT ask the user to paste:

- MONGODB_URI;
- ACCESS_TOKEN_SECRET;
- webhook secrets;
- passwords;
- API keys;
- signing keys;
- private keystores.

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 021 checkpoint:

Backend:

dart analyze:
clean

dart test:
502 passed

Flutter:

flutter analyze:
clean

flutter test:
433 passed

Android debug APK:
success

Verify these exact baselines first.

Also verify:

documentation/cursor/021_release_candidate_ux_accessibility_and_acceptance.md

Status:
SUCCESS

and confirm TASK 021C/C2/C3 evidence is included.

======================================================================
DEPENDENCY POLICY
======================================================================

BACKEND:

No new direct Dart package expected.

FLUTTER:

No new runtime or dev package expected.

Do NOT add third-party dependency solely for deployment/release work.

GitHub Actions are repository automation and are not Dart/Flutter application
dependencies.

Docker base images are deployment tooling, not application dependencies.

Do NOT run:

dart pub upgrade
flutter pub upgrade

If a new Dart/Flutter package appears genuinely unavoidable:

STOP before adding it.

======================================================================
PART A — PRODUCTION ENVIRONMENT MODEL
======================================================================

Audit current:

ServerConfig
EnvironmentLoader
backend/.env.example
APP_ENV handling
Flutter AppConfig

Standardize supported backend environments.

Required supported values:

development
test
production

If current naming already differs deliberately:

preserve compatibility only where justified and document it.

Unknown APP_ENV:

must fail configuration validation safely.

Do not silently treat unknown value as development.

======================================================================
PRODUCTION BACKEND CONFIGURATION VALIDATION
======================================================================

Create/extend centralized validation.

In production require at minimum:

MONGODB_URI

ACCESS_TOKEN_SECRET

ALLOWED_ORIGINS

PLATFORM_COMMISSION_BPS

plus any existing non-provider setting genuinely needed by the backend.

Requirements:

MONGODB_URI:
non-empty.

ACCESS_TOKEN_SECRET:
preserve existing minimum-strength policy.

ALLOWED_ORIGINS:
explicit allowlist;
must NOT be wildcard `*` in production.

PLATFORM_COMMISSION_BPS:
explicit valid integer 0–10000.

Sandbox provider secrets:

SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET

must NOT be required for production.

Production must not accidentally initialize sandbox providers simply because a
sandbox secret exists.

Development/test behavior remains compatible.

======================================================================
PRODUCTION PROVIDER CAPABILITIES
======================================================================

Production currently has NO real:

account-action delivery provider
payment provider
payout provider.

Keep explicit provider-unavailable behavior.

Do not let:

APP_ENV=production

silently activate:

DevelopmentAccountActionDeliveryProvider
SandboxPaymentProvider
SandboxPayoutProvider.

Add tests proving this.

If existing code already proves it:

retain and consolidate evidence.

======================================================================
ENVIRONMENT EXAMPLE FILE
======================================================================

Audit:

backend/.env.example

Make it complete but secret-free.

Include documented placeholders for all currently supported configuration
names.

Use values such as:

APP_ENV=development
MONGODB_URI=
ACCESS_TOKEN_SECRET=
ALLOWED_ORIGINS=
PLATFORM_COMMISSION_BPS=1500
SANDBOX_PAYMENT_WEBHOOK_SECRET=
SANDBOX_PAYOUT_WEBHOOK_SECRET=

Only include additional real config keys that actually exist.

Never include a real value.

Create if useful:

backend/.env.production.example

with EMPTY placeholders and comments/documentation only.

Do NOT create:

backend/.env.production

with credentials.

Production example should make provider limitations explicit.

======================================================================
ALLOWED ORIGINS / CORS HARDENING
======================================================================

Audit current backend CORS middleware.

Production policy:

- explicit origins only;
- no wildcard origin;
- no reflection of arbitrary Origin;
- allowed methods limited to actual API needs;
- allowed headers limited to required client headers;
- OPTIONS works correctly;
- authorization header supported;
- content-type supported;
- Idempotency-Key supported where required.

Do not enable credentials unless the application actually requires browser
cookie credentials.

Flutter mobile does not require CORS, but API browser safety still matters.

Development may retain localhost allowances if explicit.

Add tests:

allowed production origin
disallowed production origin
wildcard production config rejected
preflight allowed headers
unknown origin not reflected.

======================================================================
SECURITY RESPONSE HEADERS
======================================================================

Audit global API responses.

Add conservative API-safe headers where appropriate, for example:

X-Content-Type-Options: nosniff

Referrer-Policy: no-referrer

Cache-Control rules should continue to be endpoint-specific where required.

Do NOT blindly add browser page CSP rules that are meaningless for JSON API.

Do NOT set HSTS from the application unless deployment architecture guarantees
the backend only receives secure externally terminated traffic.

Instead document HSTS/TLS as reverse-proxy/platform responsibility.

======================================================================
REQUEST IDENTIFICATION
======================================================================

Add a lightweight request correlation mechanism if one does not exist.

Preferred header:

X-Request-Id

Rules:

- accept a safe incoming request id only if it matches a conservative format;
- otherwise generate an opaque random request id;
- include X-Request-Id in response;
- make it available to safe server diagnostics.

Do not include:

JWT
email
password
token
Mongo URI

inside request id/log context.

Do not add logging dependency.

Use Dart SDK only.

======================================================================
SAFE SERVER DIAGNOSTICS
======================================================================

Audit backend logging/print usage.

Production logs must never intentionally print:

- Authorization header;
- JWT;
- refresh token;
- account-action token;
- password;
- webhook signature;
- webhook secret;
- MongoDB URI;
- raw provider payload containing sensitive data.

Replace obvious unsafe debug prints if any exist.

Do NOT build an entire observability framework.

Document current logging limitations.

======================================================================
ERROR RESPONSE HARDENING
======================================================================

Audit uncaught error behavior.

Known application failures:

JSON error envelope.

Unexpected production server error:

generic safe 500 response.

Do not expose:

exception.toString()
stack trace
Mongo internal message
provider internal error
filesystem path.

Development may log a server-side diagnostic.

Production HTTP body must remain generic.

Add regression test if current middleware permits leakage.

======================================================================
HEALTH / READINESS CONTRACT
======================================================================

Preserve distinction:

GET /api/v1/health

LIVENESS:
process alive;
must not require Mongo success.

GET /api/v1/ready

READINESS:
Mongo configured/connected/ping succeeds.

Document expected deployment use:

liveness probe
readiness probe.

Do not introduce application-data mutation.

======================================================================
PART B — FLUTTER RELEASE CONFIGURATION
======================================================================

Audit:

AppConfig
API_BASE_URL
main.dart
Android manifests
Gradle application identity.

======================================================================
RELEASE API BASE URL POLICY
======================================================================

Current API_BASE_URL is supplied through:

--dart-define=API_BASE_URL=...

Maintain compile-time configuration.

Production/release mode must reject:

empty API_BASE_URL.

Production/release mode must reject:

plain HTTP API base URL.

Release API URL must use:

https://

Development/debug may use:

http://

for emulator/local backend.

Implement deterministic AppConfig validation.

Do NOT silently default a release build to localhost.

Do NOT put a production URL into source code.

Do NOT put backend secrets into dart-define.

Tests required:

debug/local HTTP allowed
HTTPS allowed
release empty rejected
release HTTP rejected
trailing slash normalization if current client expects it
invalid URI rejected.

======================================================================
CONFIGURATION FAILURE UX
======================================================================

If production/release Flutter configuration is invalid:

fail clearly and safely.

Preferred:

a simple configuration-error bootstrap screen or deterministic startup failure
with no secret data.

Do not show a blank screen.

Do not expose internal stack traces to user.

Development/test behavior should remain convenient.

======================================================================
ANDROID INTERNET PERMISSION
======================================================================

Audit Android manifests.

Release application must include:

android.permission.INTERNET

in the appropriate main manifest.

Do not rely only on debug/profile manifests.

======================================================================
ANDROID CLEARTEXT NETWORK POLICY
======================================================================

Production/release Android:

must reject cleartext HTTP traffic.

Preferred:

main/release:
usesCleartextTraffic=false

Debug/local development:

may explicitly allow cleartext for emulator/local API access through a
debug-manifest override if required.

Do not break:

10.0.2.2 local backend development.

Document exact behavior.

Do not create an overly broad custom network-security config unless necessary.

======================================================================
ANDROID APPLICATION IDENTITY
======================================================================

The project previously retained placeholder identity:

com.example.project

TASK 022 must remove placeholder Android identity.

Use stable portfolio application identity:

com.homecleaningmarketplace.app

unless repository inspection reveals an already intentionally selected
non-placeholder ID.

Update consistently:

namespace
applicationId
MainActivity package declaration/path if required
tests/references if any.

Application display name:

Home Cleaning Marketplace

Do NOT alter Flutter package name:

home_cleaning_marketplace

Do NOT rename physical:

project/

directory.

Do not invent signing credentials.

======================================================================
ANDROID RELEASE SIGNING
======================================================================

Audit signing configuration.

Do NOT:

- generate a private keystore;
- commit keystore;
- commit signing password;
- commit key.properties containing secrets.

If release build currently uses debug signing:

do not describe it as Play Store ready.

Prefer a documented external signing configuration using ignored:

android/key.properties

and a keystore outside source control.

If a safe optional Gradle signing setup can be added without requiring secrets:

add it so:

- when key.properties exists, release signing can use it;
- when absent, repository verification remains possible according to the
  existing build behavior.

Do not make normal development builds unusable.

Document exact status honestly.

======================================================================
ANDROID RELEASE BUILD
======================================================================

Attempt:

flutter build apk --release --dart-define=API_BASE_URL=https://api.example.invalid

Use:

example.invalid

because it is a reserved non-routable documentation domain.

This artifact is ONLY a build verification artifact.

Do not claim it is deployable against a real API.

If release APK succeeds:

record result.

Also attempt:

flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.invalid

if signing/build configuration permits.

Do not generate credentials merely to force success.

If AAB fails only because real release signing is intentionally absent:

document as a release-distribution blocker rather than weakening security.

Never track generated APK/AAB.

======================================================================
PART C — BACKEND PRODUCTION BUILD
======================================================================

Run:

dart pub global run dart_frog_cli:dart_frog build

Verify generated production backend builds successfully.

Generated build artifacts remain ignored/untracked.

Do not edit generated build output directly.

If production server entrypoint requires changes:

make them in source/project configuration from which build is generated.

======================================================================
PORT / BIND ADDRESS
======================================================================

Audit production server behavior.

Deployment container must be able to:

bind to 0.0.0.0

and use environment-defined:

PORT

where supported by current Dart Frog architecture.

Preferred default:

8080

when PORT is absent.

Validate port:

1–65535.

Do not hardcode localhost as production bind address.

If Dart Frog generated server already handles this correctly:

do not duplicate it.

Document actual behavior.

======================================================================
GRACEFUL SHUTDOWN
======================================================================

Audit production server shutdown handling.

Mongo connection should be closed cleanly where current architecture supports
process signal handling.

Do not implement a complex lifecycle framework.

If Dart Frog generated server architecture makes source-level shutdown handling
unsafe or unsupported:

document the limitation rather than editing generated files.

======================================================================
PART D — DOCKER PACKAGING
======================================================================

Create a production-oriented backend Dockerfile.

Preferred:

backend/Dockerfile

Requirements:

- multi-stage where practical;
- build Dart Frog production server;
- runtime contains only required runtime artifacts;
- no backend/.env copied;
- no secrets baked in;
- expose/document port 8080;
- bind appropriately for containers;
- run as non-root if compatible with chosen Dart runtime image;
- deterministic workdir;
- production command clearly defined.

Do not copy repository-wide unnecessary files.

======================================================================
DOCKERIGNORE
======================================================================

Create:

backend/.dockerignore

Exclude at minimum:

.env
.env.*
.dart_tool
build
coverage
.git
.gitignore
*.log
temporary files
IDE files

But do NOT accidentally exclude required pubspec/lock/source files.

======================================================================
DOCKER ENVIRONMENT
======================================================================

Docker image must receive secrets ONLY at runtime.

Examples in docs may show variable NAMES but never actual values.

Do not use:

ARG ACCESS_TOKEN_SECRET
ARG MONGODB_URI

for secrets.

======================================================================
DOCKER BUILD VERIFICATION
======================================================================

If Docker is installed:

run a local:

docker build

for backend.

Use a clear image tag such as:

home-cleaning-marketplace-api:task022

Do NOT push image.

Do NOT start production mutation flows.

If Docker is not installed:

do not fail TASK 022 solely for that reason.

Report:

NOT EXECUTED — Docker unavailable

after verifying Dockerfile structurally as far as possible.

Do not install Docker automatically.

======================================================================
PART E — CONTINUOUS INTEGRATION
======================================================================

Audit existing:

.github/workflows/

Create or update a primary CI workflow.

Suggested:

.github/workflows/ci.yml

CI runs on:

pull_request
push to main

Do NOT add automatic deployment.

======================================================================
CI BACKEND JOB
======================================================================

Run:

dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test

Do not require:

backend/.env
Mongo Atlas
live credentials.

Automated backend suite must remain Atlas-free.

Use appropriate stable Dart setup action/version.

Pin/declare version deliberately.

======================================================================
CI FLUTTER JOB
======================================================================

Run:

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

Optionally:

flutter build apk --debug

if CI runtime cost is reasonable.

Prefer testing buildability.

Use project Flutter version:

3.47.1

or the exact project-supported version verified locally.

Do not silently use latest Flutter.

======================================================================
CI SECRET SAFETY
======================================================================

CI must not require application production secrets.

Do not add:

MONGODB_URI
ACCESS_TOKEN_SECRET
payment secret
payout secret

to workflow.

Do not introduce GitHub deployment secrets.

======================================================================
CI CACHE
======================================================================

Caching is optional.

If used:

only standard Dart/Flutter dependency caches.

Do not add complicated cache logic.

======================================================================
PART F — RELEASE VERIFICATION TOOL
======================================================================

Create a small repository-level release verification utility using Dart SDK
only.

Preferred:

tools/release_check.dart

It should be runnable from repository root:

dart tools/release_check.dart

No pub package required.

Responsibilities:

- verify expected repository directories;
- verify backend/.env is ignored using git;
- detect tracked forbidden artifact names;
- run or orchestrate safe static checks where practical;
- report commands/result clearly;
- never print secret values;
- never connect to Atlas;
- never mutate application data.

Optional flags may include:

--quick
--full

but keep implementation simple.

If executing Flutter/Dart subprocesses:

inherit useful output.

Do not auto-run deployment.

======================================================================
FORBIDDEN TRACKED ARTIFACT CHECK
======================================================================

Release check should detect obviously forbidden tracked files such as:

backend/.env
*.jks
*.keystore
key.properties
*.apk
*.aab
known build directories
project/devtools_options.yaml
temporary TASK prompt files

Do NOT falsely block safe example files such as:

.env.example
.env.production.example

Do not scan arbitrary binary files for secret values.

======================================================================
SECRET NAME AUDIT
======================================================================

Perform repository grep/audit for common secret variable assignments.

Allowed:

documentation mentioning variable names
.env.example empty placeholders
tests with explicit fake literals

Not allowed:

real-looking committed secret values.

Do not print any real runtime secret found.

If a potentially real secret is detected:

STOP and report FILE/PATTERN only, never value.

======================================================================
PART G — SAFE PRODUCTION-MODE VERIFICATION
======================================================================

Use existing private backend/.env without printing it.

Do NOT ask user for secrets.

Construct production-mode verification only if existing local configuration
allows it safely.

Verify configuration behavior with tests regardless.

If safe to run production build against current private Atlas connection:

only call read-only public endpoints:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Optionally a newly added safe public runtime/capability endpoint if one exists.

Do NOT call:

signup
login
verification
password reset
booking
payment
webhook
payout
refund
chat
review
dispute
admin mutation

against live Atlas.

No live application-data mutation.

If production-mode local run would require changing or printing secrets:

skip it and document why.

======================================================================
PRODUCTION PROVIDER-UNAVAILABLE TEST
======================================================================

Automated tests must prove under production config:

account-action delivery:
unavailable

sandbox payment:
unavailable

sandbox payout:
unavailable

Do not exercise real external providers.

======================================================================
PART H — FINAL SECURITY AUDIT
======================================================================

Create:

documentation/security/final-security-audit.md

Create directory if needed:

documentation/security/

Audit the architecture under categories:

AUTHENTICATION
AUTHORIZATION
PASSWORDS
TOKENS
SESSIONS
ACCOUNT RECOVERY
INPUT VALIDATION
IDEMPOTENCY
BOOKING CONCURRENCY
PAYMENTS
PAYOUTS
WEBHOOKS
CHAT PRIVACY
REVIEWS
DISPUTES
ADMIN
AUDIT LOGGING
CORS
SECRETS
TRANSPORT
ERROR HANDLING
MONGODB
MOBILE CLIENT
DEPENDENCIES
DEPLOYMENT
LOGGING
BACKUPS
INCIDENT RESPONSE.

For each:

Implemented controls
Known limitations
Production action if any.

Do not claim certification.

Do not claim penetration testing occurred.

======================================================================
OWASP-STYLE REVIEW
======================================================================

Perform a reasoned mapping against relevant API/mobile risks.

Examples:

broken object authorization
broken authentication
excessive data exposure
unrestricted resource consumption
security misconfiguration
injection
unsafe API consumption

Describe how current architecture addresses each and remaining risks.

Do not claim formal OWASP compliance certification.

======================================================================
SECRET ROTATION RUNBOOK
======================================================================

Document safe rotation procedures for:

ACCESS_TOKEN_SECRET
MongoDB Atlas database credentials
sandbox webhook secrets

Important:

ACCESS_TOKEN_SECRET rotation invalidates existing access JWTs.

Mongo credential rotation must update runtime secret storage.

Never include actual values.

Production payment/payout provider secrets are future/deferred.

======================================================================
BACKUP / RESTORE DOCUMENTATION
======================================================================

Create operational guidance for MongoDB Atlas.

Document:

- enable Atlas managed backups for real production;
- retention depends on deployment tier/business policy;
- periodically test restore into non-production environment;
- never restore production data into developer laptops without authorization;
- indexes must be recreated/verified;
- secrets are not part of database backup.

Do NOT execute backup/restore.

======================================================================
PART I — SCALABILITY AUDIT
======================================================================

Create:

documentation/architecture/scalability-and-growth-review.md

Review current architecture from:

0 users
→ 1,000 users
→ 10,000 users
→ 100,000 users
→ 1,000,000 users

This is an architectural assessment, not a benchmark claim.

Discuss:

Flutter clients
Dart Frog stateless HTTP instances
load balancer
MongoDB Atlas indexes
Mongo connection pooling
pagination
idempotency
booking reservation uniqueness
availability overlap limitation
payment/payout webhook idempotency
chat REST polling
notification polling
audit volume
financial ledger growth
admin queries
image/document storage currently absent
rate limiting
caching
queues/outbox
background jobs
observability
backups
multi-region concerns.

======================================================================
SCALABILITY HONESTY
======================================================================

Do NOT claim:

"supports one million users"

unless load testing actually proves it.

Instead state:

architecture elements already suitable for horizontal scaling

and:

components that would need redesign/validation before that scale.

======================================================================
SCALE STAGES
======================================================================

Suggested documentation structure:

STAGE 1 — Portfolio / Early Deployment
0–1,000 users

Current architecture largely sufficient.

STAGE 2 — Growing Marketplace
1,000–10,000 users

Likely needs:
managed deployment
monitoring
backup policy
production providers
rate limiting
query monitoring.

STAGE 3 — Regional Scale
10,000–100,000 users

Likely needs:
multiple stateless API instances
load balancer
distributed rate limiting
cache
queue/outbox
background worker
WebSocket/SSE/chat infrastructure
Mongo tuning.

STAGE 4 — Large Scale
100,000–1,000,000+

Likely needs:
partitioning/sharding evaluation
multi-region strategy
event infrastructure
data warehousing
advanced observability
disaster-recovery testing
capacity/load testing.

Treat these as engineering planning guidance, not promises.

======================================================================
KNOWN CONSISTENCY LIMITATIONS
======================================================================

Include current deliberate limitations:

- different-slot availability overlap is not fully protected by a single DB
  uniqueness constraint;
- cross-document notification side effects are best-effort;
- audit side effects are best-effort;
- earnings projection is not distributed exactly-once;
- external-provider + Mongo state is not a distributed transaction;
- reconciliation detects certain financial drift;
- chat uses REST polling;
- no distributed task queue/outbox;
- no distributed rate limiter.

Document mitigation path for each.

======================================================================
PART J — FINAL FUNCTIONAL COMPLETENESS AUDIT
======================================================================

Create:

documentation/final/functional-completeness.md

Create directory if needed:

documentation/final/

Audit original functional requirements:

FR-01 Sign Up
FR-02 Login
FR-03 Profile/Address
FR-04 Cleaner Onboarding
FR-05 Cleaner Approval
FR-06 Discovery/Search
FR-07 Cleaner Details/Comparison
FR-08 Availability
FR-09 Booking
FR-10 Booking Management
FR-11 Payment
FR-12 Booking Status
FR-13 Chat/Notifications
FR-14 Ratings/Reviews
FR-15 Admin Dashboard

For each state:

IMPLEMENTED
PARTIAL / DEVELOPMENT-ONLY
DEFERRED
BLOCKED

with evidence/path.

Important examples:

Payment:
IMPLEMENTED architecture / DEVELOPMENT-ONLY provider.

Password recovery:
implemented beyond initial FR baseline.

Payout:
implemented architecture / DEVELOPMENT-ONLY provider.

Email verification:
implemented architecture / DEVELOPMENT-ONLY delivery.

Do not call provider-dependent flows production-complete.

======================================================================
ROLE FEATURE MATRIX
======================================================================

Include a customer/cleaner/admin matrix of screens/APIs.

Document:

implemented
development-only
deferred.

No marketing exaggeration.

======================================================================
PART K — PRODUCTION READINESS GAP REGISTER
======================================================================

Create:

documentation/final/production-readiness-gap-register.md

Use priorities:

P0 — required before real production users
P1 — strongly recommended shortly after
P2 — scale/operational improvement

At minimum evaluate:

P0 candidates:

- real email delivery;
- real payment provider;
- real payout provider if payouts offered at launch;
- legal/privacy/terms content;
- production domain/TLS;
- production secrets manager;
- release signing key;
- Atlas backup policy;
- monitoring/alerting;
- privacy/security review;
- production environment validation.

P1:

- distributed rate limiting;
- background jobs/outbox;
- WebSocket/SSE chat;
- crash reporting;
- audit retention;
- support tooling;
- automated database migration/index process;
- load testing.

P2:

- cache;
- multi-region;
- warehouse/BI;
- advanced fraud tooling;
- localization;
- accessibility device lab;
- disaster-recovery automation.

Priorities may be adjusted based on reasoned audit.

======================================================================
PART L — DEPLOYMENT ARCHITECTURE DOCUMENTATION
======================================================================

Create:

documentation/deployment/deployment-architecture.md

Create directory if needed.

Document target-neutral architecture:

Flutter Android App
        |
      HTTPS
        |
TLS / Reverse Proxy / Managed Load Balancer
        |
Dart Frog API Containers
        |
MongoDB Atlas

External future providers:

Email provider
Payment provider
Payout provider

Do not tie architecture to AWS/GCP/Azure unless as examples.

======================================================================
CONTAINER DEPLOYMENT RUNBOOK
======================================================================

Create:

documentation/deployment/backend-container-runbook.md

Document:

build image
runtime env variables
port
health/readiness
TLS termination
secrets injection
start/stop
rolling deployment considerations
safe index ensure step
rollback
logs
production provider limitations.

Example commands must use:

placeholders

not secrets.

======================================================================
ANDROID RELEASE RUNBOOK
======================================================================

Create:

documentation/deployment/android-release-runbook.md

Document:

application ID
API_BASE_URL
HTTPS requirement
release signing outside repo
keystore handling
APK/AAB commands
versioning
Play Console high-level steps
secret boundaries.

Do not create Play Store credentials.

======================================================================
ENVIRONMENT REFERENCE
======================================================================

Create:

documentation/deployment/environment-reference.md

For every backend env var document:

name
required environment
secret?
validation
purpose
example format WITHOUT real secret.

For Flutter:

API_BASE_URL

Explain dart-define is NOT a secret store.

Anything included in Flutter can be extracted from the app.

======================================================================
OPERATIONAL RUNBOOK
======================================================================

Create:

documentation/deployment/operations-runbook.md

Include:

health/readiness
deployment
rollback
index ensure
secret rotation
Atlas availability incident
provider outage behavior
financial reconciliation
suspicious session response
log review
backup/restore reference.

No fake operational automation.

======================================================================
PART M — CI / RELEASE DOCUMENTATION
======================================================================

Create:

documentation/testing/continuous-integration.md

Document:

workflow triggers
backend job
Flutter job
no live Atlas
no production secrets
build artifact behavior.

Create:

documentation/testing/release-verification.md

Document:

local release_check.dart
manual commands
expected results
artifact cleanup
known warnings.

======================================================================
ADR-020
======================================================================

Create:

documentation/decisions/ADR-020-production-deployment-and-release-readiness.md

Required:

# ADR-020 — Production Deployment and Release Readiness

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deployment
## Scalability
## Production Blockers
## Deferred Decisions

Decision covers:

- explicit production config validation;
- no sandbox fallback in production;
- HTTPS-only Flutter release API;
- Android cleartext disabled in release;
- stable Android application ID;
- runtime secret injection;
- backend Docker packaging;
- CI without production secrets;
- release verification tooling;
- target-neutral deployment architecture;
- production-provider gap honesty;
- scalability roadmap.

Alternatives:

### Hard-code production API URL
Rejected.

### Bundle backend secrets in Flutter
Rejected.

### Keep com.example.project
Rejected.

### Allow cleartext API in release
Rejected.

### Automatically use sandbox providers in production/demo
Rejected.

### Commit release signing key
Rejected.

### Auto-deploy from current CI
Deferred/rejected for now because no cloud target/credentials selected.

### Claim one-million-user scalability without load testing
Rejected.

### Integrate multiple infrastructure platforms
Deferred.

Deferred:

real email/payment/payout providers
MFA
distributed rate limiting
queue/outbox
WebSocket chat
advanced monitoring vendor
cloud deployment target
automated infrastructure provisioning
load testing
multi-region deployment.

======================================================================
ROOT README — PORTFOLIO QUALITY
======================================================================

Upgrade root:

README.md

without making it enormous.

It should clearly explain:

- project purpose;
- architecture;
- roles;
- major features;
- security highlights;
- financial architecture;
- development provider limitations;
- technology stack;
- repository layout;
- local setup;
- test commands;
- backend run;
- Flutter run;
- release verification;
- documentation location;
- production-readiness status.

Include a concise architecture diagram using Markdown text/Mermaid only if
current README/docs conventions support it.

Do not embed private URLs/secrets.

Do not claim real payment/email/payout production integration.

======================================================================
BACKEND README
======================================================================

Update:

backend/README.md

for:

development run
production build
env validation
health/readiness
Docker
indexes
tests
provider limitations.

======================================================================
FLUTTER README
======================================================================

Update:

project/README.md

for:

API_BASE_URL
debug local HTTP
release HTTPS
Android ID
build commands
tests
sandbox/development UI honesty.

======================================================================
DOCUMENTATION INDEXES
======================================================================

Update:

documentation/README.md
documentation/architecture/README.md
documentation/api/README.md if relevant
documentation/database/README.md if relevant
documentation/decisions/README.md
documentation/testing/README.md

Create/update:

documentation/security/README.md
documentation/deployment/README.md
documentation/final/README.md

All new final docs must be discoverable.

======================================================================
PART N — RELEASE VERSION / BUILD METADATA
======================================================================

Audit current:

project/pubspec.yaml version

backend/pubspec.yaml version if present.

Do not arbitrarily change version merely for appearance.

If version is still default/template and clearly unsuitable:

choose a documented release-candidate version.

Preferred:

Flutter:
1.0.0+1

Backend package:
1.0.0

ONLY if doing so does not contradict current repository version history.

Otherwise preserve and document current version.

Do not create Git tag.

======================================================================
PART O — FINAL TEST / BUILD MATRIX
======================================================================

Final matrix must include:

BACKEND

dart format check
dart analyze
dart test
dart_frog list
dart_frog build

FLUTTER

dart format check
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release with reserved HTTPS URL

and if possible:

flutter build appbundle --release with reserved HTTPS URL.

RELEASE TOOL

dart tools/release_check.dart

DOCKER

docker build if Docker available.

CI

workflow syntax/review
and local commands corresponding to CI.

======================================================================
NO AUTOMATED LIVE DATA MUTATIONS
======================================================================

TASK 022 must not create live:

users
sessions
tokens
addresses
cleaner profiles
services
availability
bookings
payments
refunds
messages
notifications
reviews
disputes
audit logs
earnings
payouts

in Atlas.

Index ensure:

Do NOT rerun automatically unless TASK 022 changes index definitions.

TASK 022 should not need new database indexes.

If no index changes:

do not mutate Atlas at all.

======================================================================
PART P — FINAL REPOSITORY AUDIT
======================================================================

Inspect tracked repository for:

secrets
generated artifacts
placeholder identifiers
stale docs
temporary prompt files
debug-only configuration accidentally in production
real user/sample data
TODO/FIXME relevant to security/release.

Do not remove legitimate TODOs blindly.

Classify important remaining TODOs into final gap register.

======================================================================
PLACEHOLDER IDENTITY SEARCH
======================================================================

Search repository for:

com.example
example.project
"project" as Android display identity where inappropriate

Fix Android native identity consistently.

Do not rename legitimate filesystem:

project/

or generic documentation references.

======================================================================
DEBUG / DEVELOPMENT LEAK AUDIT
======================================================================

Search production Flutter/backend paths for:

Development Sandbox
development_action
simulate
localhost
10.0.2.2
127.0.0.1

These strings may legitimately exist in debug/development code.

Ensure none creates an unintended production fallback.

Do not remove legitimate development capabilities.

======================================================================
RELEASE ARTIFACT HYGIENE
======================================================================

After builds:

APK
AAB
backend build
Docker generated files

must remain untracked.

Do not copy release binaries into documentation.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN TASK 021 CHECKPOINT

From root:

git rev-parse --show-toplevel
git branch --show-current
git status
git status --short
git log -10 --oneline

Expected:

root:
D:\freelance\erfankhan_cse489\final

branch:
main

clean tree.

Verify TASK 021 report status SUCCESS.

Verify backend/.env ignored.

If dirty:

STOP.

======================================================================
STEP 2 — BASELINE BACKEND

From backend:

dart pub get
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Expected:

502 passed
analyze clean.

If not:

STOP.

======================================================================
STEP 3 — BASELINE FLUTTER

From project:

flutter pub get
flutter analyze
flutter test
flutter build apk --debug

Expected:

433 passed
analyze clean
APK success.

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new Dart/Flutter packages needed.

======================================================================
STEP 5 — PRODUCTION CONFIG AUDIT

Implement/verify:

APP_ENV
required production config
sandbox prohibition
CORS validation
safe environment examples
tests.

======================================================================
STEP 6 — REQUEST / ERROR HARDENING

Implement/verify:

request IDs
safe response headers
safe production unexpected errors
diagnostic redaction.

Tests.

======================================================================
STEP 7 — FLUTTER RELEASE CONFIG

Implement:

release API URL validation
configuration failure UX
tests.

======================================================================
STEP 8 — ANDROID RELEASE IDENTITY / NETWORK

Implement/audit:

INTERNET
cleartext policy
debug local HTTP
stable applicationId/namespace
display name
MainActivity package.

Build/test.

======================================================================
STEP 9 — RELEASE SIGNING AUDIT

Implement only safe optional configuration if justified.

No signing credentials.

Document status.

======================================================================
STEP 10 — BACKEND PRODUCTION BUILD

Run:

dart pub global run dart_frog_cli:dart_frog build

Verify.

======================================================================
STEP 11 — DOCKER

Create:

backend/Dockerfile
backend/.dockerignore

Build if Docker available.

Do not push.

======================================================================
STEP 12 — CI

Create/update GitHub Actions CI.

No live secrets.

======================================================================
STEP 13 — RELEASE CHECK TOOL

Create:

tools/release_check.dart

Test it.

======================================================================
STEP 14 — ANDROID RELEASE BUILDS

Run reserved-domain release verification.

APK release.

Attempt AAB release.

No real endpoint.

No generated credential.

======================================================================
STEP 15 — PRODUCTION-MODE SAFETY TESTS

Verify:

config validation
HTTPS rules
sandbox unavailable
safe errors
CORS
request id/security headers.

======================================================================
STEP 16 — OPTIONAL SAFE PRODUCTION SERVER VERIFY

Only if possible without exposing/changing secrets.

Read-only GETs only.

Otherwise skip honestly.

======================================================================
STEP 17 — FINAL SECURITY AUDIT DOC

Create final-security-audit.md.

======================================================================
STEP 18 — SCALABILITY REVIEW

Create scalability-and-growth-review.md.

======================================================================
STEP 19 — FUNCTIONAL COMPLETENESS

Create functional-completeness.md.

======================================================================
STEP 20 — PRODUCTION GAP REGISTER

Create production-readiness-gap-register.md.

======================================================================
STEP 21 — DEPLOYMENT / OPERATIONS DOCS

Create deployment architecture, container, Android, environment, operations
runbooks.

======================================================================
STEP 22 — CI / RELEASE DOCS

Create continuous-integration.md and release-verification.md.

======================================================================
STEP 23 — ADR-020

Create production deployment/readiness ADR.

======================================================================
STEP 24 — README / INDEX UPDATES

Update root/backend/project/docs indexes.

======================================================================
STEP 25 — FULL BACKEND VERIFICATION

Run:

dart format .
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list
dart pub global run dart_frog_cli:dart_frog build

All green.

Record exact test count.

======================================================================
STEP 26 — FULL FLUTTER VERIFICATION

Run:

dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.invalid

Attempt:

flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.invalid

Record exact results.

======================================================================
STEP 27 — RELEASE CHECK

From root:

dart tools/release_check.dart

Must pass all checks that are applicable to a source checkout.

If tool supports --full:

run it only if it does not duplicate destructive/live operations.

======================================================================
STEP 28 — DOCKER VERIFY

If Docker available:

docker build -t home-cleaning-marketplace-api:task022 backend

Record result.

Do not push.

If unavailable:

record clearly.

======================================================================
STEP 29 — FINAL SECURITY / SECRET REVIEW

From root:

git ls-files

Review tracked sensitive patterns without outputting secret values.

Run:

git check-ignore -v backend/.env
git diff --check
git status --short

Inspect all diffs.

======================================================================
STEP 30 — FINAL PRODUCT STATUS ASSESSMENT
======================================================================

Explicitly determine:

A. SOFTWARE RELEASE READY?
YES / NO

B. FULLY PRODUCTION SERVICE READY?
YES / NO

Expected likely outcome if all code/deployment work succeeds but providers
remain intentionally absent:

SOFTWARE RELEASE READY:
YES

FULLY PRODUCTION SERVICE READY:
NO

Primary blockers:

production email
production payment
production payout
real release signing/distribution credentials if absent
deployment target/domain/TLS/secrets/monitoring/backup operational setup.

Do not force the expected answer if audit finds additional blockers.

======================================================================
STEP 31 — TASK REPORT
======================================================================

Create:

documentation/cursor/022_production_deployment_release_and_final_audit.md

Use existing task-report style.

The report MUST contain the COMPLETE EXACT TASK 022 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 021 checkpoint;
- backend baseline;
- Flutter baseline;
- dependency audit;
- environment model;
- production validation;
- provider prohibition;
- CORS;
- response security headers;
- request IDs;
- error hardening;
- logging audit;
- Flutter release API validation;
- Android INTERNET permission;
- Android cleartext policy;
- Android application identity;
- signing status;
- backend production build;
- Dockerfile;
- Docker build result;
- CI;
- release_check;
- release APK;
- AAB attempt/result;
- production-mode tests;
- safe live verification decision;
- security audit;
- scalability review;
- functional completeness;
- production gap register;
- deployment docs;
- operations docs;
- exact test counts;
- Git hygiene;
- SOFTWARE RELEASE READY result;
- FULLY PRODUCTION SERVICE READY result;
- remaining blockers;
- warnings.

Never include:

backend/.env contents
MONGODB_URI
ACCESS_TOKEN_SECRET
sandbox webhook secret
real account-action token
password
JWT
refresh token
keystore password
private signing key
private Atlas records.

======================================================================
STEP 32 — FINAL PROJECT COMPLETION SUMMARY
======================================================================

Create:

documentation/final/project-completion-summary.md

This is a concise executive summary.

Include:

Project:
Home Cleaning Marketplace

Architecture:
Flutter → HTTPS REST → Dart Frog → MongoDB Atlas

Roles:
Customer
Cleaner
Administrator

Major capability groups:
list concise groups.

Engineering strengths:
- layered architecture;
- secure auth;
- idempotency;
- concurrency safeguards;
- provider boundaries;
- financial ledger/reconciliation;
- admin/audit controls;
- tests;
- CI;
- deployment packaging;
- release UX.

Known non-production integrations:
- email;
- payment;
- payout.

Known scale limitations:
concise.

Final automated verification:
exact final backend tests
exact final Flutter tests
release builds
Docker result
CI definition.

Do not make unsupported claims.

======================================================================
STEP 33 — DO NOT COMMIT
======================================================================

Do NOT:

git add
git commit
git tag
git push

Leave TASK 022 completely:

UNSTAGED
UNCOMMITTED

for ChatGPT final review.

Do NOT create another task.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 022 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## Production Environment Model

## Production Configuration Validation

## Production Provider Safety

## CORS Hardening

## Security Response Headers

## Request Identification

## Error and Logging Hardening

## Health and Readiness

## Flutter Release Configuration

## Android Application Identity

## Android Network Security

## Android Release Signing

## Backend Production Build

## Docker Packaging

## Docker Build Verification

## Continuous Integration

## Release Verification Tool

## Android Debug Build

## Android Release APK

## Android Release AAB

## Production-Mode Safety Tests

## Live Backend Verification

## Live Data Safety

## Final Security Audit

## Scalability and Growth Review

## Functional Completeness

## Production Readiness Gap Register

## Deployment Documentation

## Operations Documentation

## CI and Release Documentation

## ADR-020

## Root README / Portfolio Documentation

## Backend Tests

## Backend Routes

## Flutter Tests

## Flutter Static Analysis

## Release Artifact Hygiene

## Secret / Repository Audit

## Software Release Ready

YES
NO

Explain.

## Fully Production Service Ready

YES
NO

Explain exact blockers.

## Files Created

## Files Modified

## Files Deleted

## Documentation

## Git Status

## Issues / Warnings

## Final Project Statement

State whether TASK 022 is complete and whether the repository is ready for
ChatGPT's FINAL project review.

Do NOT commit.

Do NOT tag.

Do NOT push.

Do NOT create TASK 023.

Start TASK 022 now.
~~~~

## Git Status

TASK 022 changes remain **uncommitted** by design. No `git add` / `git commit` / `git push`.

## Issues / Warnings

- Docker **engine** unavailable locally — image build not executed; structural audit and local `dart_frog build` + `dart compile exe` equivalent **PASS**.
- Graceful Mongo close on SIGTERM is **not** framework-wired; process termination remains the operational path (non-blocking limitation).
- Invalid explicit `PORT` fails startup via repository-owned `backend/main.dart` + `PortConfig` (1–65535); absent → 8080. Generated Dart Frog `tryParse` fallback remains in generated sources but does not govern the supported production path.
- Backend `dart format .` must be evaluated without a stale generated `build/` tree (generated `server.dart` is not format-stable); CI formats before build.
- Release APK/AAB use debug signing when `key.properties` is absent — not Play Store ready.
- Optional production live GET was skipped; no Atlas mutation and no secrets printed.
- SOFTWARE RELEASE READY is YES for the portfolio codebase packaging/verification posture; FULLY PRODUCTION SERVICE READY remains NO pending real providers, hosting/TLS, ops, Play signing, and legal/privacy content.

## Final Statement

TASK 022 implementation plus TASK 022C release-gate evidence and TASK 022C2 production PORT fail-fast validation (custom entrypoint + `PortConfig`, focused tests, docs/matrix honesty) are complete. SOFTWARE RELEASE READY: YES. FULLY PRODUCTION SERVICE READY: NO. Changes left uncommitted for ChatGPT’s FINAL checkpoint review.
