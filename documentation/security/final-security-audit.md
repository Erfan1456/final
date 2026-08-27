# Final Security Audit

**Project:** Home Cleaning Service Marketplace  
**Versions:** Flutter `1.0.0+1`, backend `1.0.0+1`, Flutter SDK `3.47.1`, Android `applicationId` `com.homecleaningmarketplace.app`  
**Audit type:** Architecture and code-path review (TASK 022)  
**Not claimed:** Formal certification, penetration testing, or third-party security assessment

This audit describes controls that exist in the current repository, known limitations, and production actions. Development-only email, payment, and payout adapters are treated as intentional gaps, not as production capabilities.

Related documents: [deployment/environment-reference.md](../deployment/environment-reference.md), [deployment/operations-runbook.md](../deployment/operations-runbook.md), [architecture/scalability-and-growth-review.md](../architecture/scalability-and-growth-review.md), [final/production-readiness-gap-register.md](../final/production-readiness-gap-register.md).

---

## AUTHENTICATION

**Implemented controls**

* Customer/cleaner public signup with email normalization, password policy, Argon2id hashing, and persisted role.
* Signup does **not** issue access/refresh tokens; email verification is required before login (`email_verified = false` rejected).
* Login verifies password with constant-time-friendly dummy-hash path for missing users; generic failure messages.
* Access JWTs (HS256, short-lived) plus opaque refresh tokens with atomic rotation and reuse/replay detection.
* Logout and session revoke paths; authenticated password change revokes sessions as designed in TASK 020.
* Dev routes under `/api/v1/dev` return 404 when `APP_ENV=production`.

**Known limitations**

* No MFA, OAuth, or social login.
* Access JWTs remain valid until expiry after session revoke (short TTL tradeoff; no access-token blacklist).
* Email verification delivery is development/test only.

**Production action**

* Configure strong `ACCESS_TOKEN_SECRET` (≥32 UTF-8 bytes) via runtime secrets; rotate with planned JWT invalidation window.
* Integrate a real email provider before treating verification/recovery as production-complete.
* Consider MFA as a later product decision (deferred).

---

## AUTHORIZATION

**Implemented controls**

* Persisted role on the user document; JWT `role` claim must match known roles.
* Role-scoped composition for customer, cleaner, and admin routes; foreign-role access rejected.
* Object access generally scoped by booking membership, ownership, or admin role (profiles, addresses, chat, disputes, earnings).
* Cleaner marketplace participation gated on admin approval lifecycle.

**Known limitations**

* Authorization is application-enforced; no separate policy engine.
* Admin powers are broad by design (user/booking/payment/payout/review/dispute ops).
* No fine-grained admin RBAC subdivisions.

**Production action**

* Review admin account provisioning and least-privilege human access to Atlas/admin API credentials.
* Add admin MFA / break-glass procedures before large-scale production (deferred product + ops).

---

## PASSWORDS

**Implemented controls**

* Argon2id hashing; encoded hash storage only.
* Policy: 15–128 Unicode code points (see password-security architecture).
* Transparent rehash on successful login when parameters change.
* Authenticated password change; recovery confirm consumes one-time hashed tokens.

**Known limitations**

* No breached-password / HaveIBeenPwned check.
* No password history beyond session invalidation semantics.

**Production action**

* Keep Argon2 parameters under periodic review.
* Optional: add breach-list checks without logging candidate passwords.

---

## TOKENS

**Implemented controls**

* Access: HS256 JWT, 15-minute lifetime, `iss`/`aud`/`sub`/`sid`/`role`/`jti` validation; non-HS256 rejected.
* Refresh: 256-bit opaque tokens; only SHA-256 hex hashes stored.
* Account-action tokens: same opaque + hash pattern; one-time claim via atomic update.
* Secrets never included in `ServerConfig.toString()` or success envelopes.

**Known limitations**

* JWT payload is signed, not encrypted (by design — no secrets in claims).
* No asymmetric signing (HS256 shared secret).

**Production action**

* Enforce production boot validation for secret presence/length (already in `validateServerConfig`).
* Plan `ACCESS_TOKEN_SECRET` rotation (invalidates outstanding access JWTs).

---

## SESSIONS

**Implemented controls**

* `user_sessions` with absolute lifetime, rotation metadata, used-hash replay list, revoke-one / revoke-all.
* Flutter secure session storage for tokens (platform keystore/keychain oriented packages).
* Account security UI for listing/revoking sessions.
* Logout clears client auth state; user-scoped Riverpod controllers re-isolate on auth identity change.

**Known limitations**

* No device attestation or risk-based session scoring.
* Concurrent device limit not enforced beyond operational session list.

**Production action**

* Monitor for refresh replay events as suspicious activity.
* Document support playbook for mass session revoke after credential compromise.

---

## ACCOUNT RECOVERY

**Implemented controls**

* Public email-verification request/verify and password-reset request/confirm with generic responses for unknown emails.
* Development/test delivery may expose `development_action` payloads; production composition uses unavailable delivery (no raw token fallback).
* Token TTL and one-time claim.

**Known limitations**

* **No production SMTP / SendGrid / SES / Mailgun.**
* Without a real mailer, verification and reset cannot complete for real users.

**Production action**

* Implement `AccountActionDeliveryProvider` against a production email service.
* Keep generic responses; rate-limit request endpoints (see rate limiting gap).

---

## INPUT VALIDATION

**Implemented controls**

* JSON body parsing with typed DTOs / validators on auth, booking, payment, payout, chat, review, dispute routes.
* Email normalization; ObjectId syntax checks for path IDs.
* Money amounts as integer minor units from server-side booking quotes (client cannot set payment amount).
* Commission BPS validated as integer 0–10000.

**Known limitations**

* Validation depth varies by endpoint; not a formal schema gateway.
* No WAF in-application.

**Production action**

* Terminate TLS at reverse proxy; consider edge WAF/rate limits.
* Keep rejecting oversized or malformed JSON at the API edge.

---

## IDEMPOTENCY

**Implemented controls**

* Booking create: customer + `Idempotency-Key` unique index with fingerprint compare.
* Payment/payout initiation paths use idempotency keys where designed.
* Webhook event uniqueness on `(provider, provider_event_id)` for payments and payouts.
* Earnings `source_event_key` uniqueness for settlement and refund adjustments.

**Known limitations**

* Not every mutating admin action is idempotent.
* Client must send keys correctly; missing keys may create duplicates where not otherwise constrained.

**Production action**

* Preserve idempotency indexes in Atlas; verify after restore.
* Document client retry guidance for mobile networks.

---

## BOOKING CONCURRENCY

**Implemented controls**

* Complete-slot booking with immutable quote snapshot.
* Partial unique index on active reservation for the same availability slot.
* Application pre-checks for UX; DB uniqueness for same-slot races.
* Reserved slots filtered from discovery.

**Known limitations**

* **Different-slot time overlap** is application-enforced only — not a single Mongo uniqueness constraint over arbitrary intervals.
* No distributed lock service.

**Production action**

* Accept limitation for early production or add stronger scheduling constraints / exclusive windows.
* Load-test concurrent booking on hot cleaners before marketing peak campaigns.

---

## PAYMENTS

**Implemented controls**

* Provider-neutral `PaymentProvider` interface and ledger collections.
* Sandbox adapter only when `APP_ENV` is `development` or `test`; production returns provider unavailable (no silent sandbox fallback).
* Amount authority is booking quote; Flutter never supplies charge amount.
* Refund orchestration for confirmed-booking cancel; failure leaves booking confirmed.
* No card/CVV storage.

**Known limitations**

* **Sandbox only — no Stripe / PayPal / bKash / bank rails.**
* No real money movement; refunds are ledger/sandbox semantics.

**Production action**

* Implement a real `PaymentProvider` and webhook verification before charging customers.
* Keep production refusal behavior until that adapter exists and is tested.

---

## PAYOUTS

**Implemented controls**

* Append-only earnings ledger with commission snapshot.
* Payout request reservation (partial unique active payout), admin process/reject, sandbox provider + signed webhooks.
* Production never constructs sandbox payout provider.
* Read-only admin reconciliation detects certain drift.

**Known limitations**

* **Sandbox only — no bank/wallet transfer, KYC, or tax.**
* Earnings projection is not distributed exactly-once; primary booking/payment writes remain authoritative if ledger append fails.

**Production action**

* Real payout provider + destination verification before offering cleaner payouts at launch.
* Or disable cleaner payout UX until provider is ready.

---

## WEBHOOKS

**Implemented controls**

* HMAC-SHA256 over raw body; dedicated signature headers; constant-time-ish compare helpers.
* Event idempotency and payload hash conflict detection.
* Amount/currency integrity checks before mutation.
* Dev simulate endpoints gated out of production.

**Known limitations**

* Secrets and algorithms are sandbox-oriented today.
* No multi-provider signature matrix yet.

**Production action**

* Replace with production provider signature schemes; store secrets in a secrets manager.
* Retain idempotent event store pattern.

---

## CHAT PRIVACY

**Implemented controls**

* Booking-scoped conversations and membership checks.
* REST message APIs; participants limited to booking parties (+ admin ops where implemented).
* Privacy-conscious booking DTOs elsewhere in the product.

**Known limitations**

* REST polling only — no E2E encryption.
* Message content stored in MongoDB in plaintext at rest (Atlas encryption-at-rest depends on Atlas config).
* No attachment/malware scanning (attachments largely absent).

**Production action**

* Confirm Atlas encryption-at-rest and access controls.
* Add retention/moderation policy for chat content.

---

## REVIEWS

**Implemented controls**

* Verified reviews tied to completed booking eligibility rules.
* Admin moderation paths.
* Discovery ratings computed from approved data (not arbitrary client scores).

**Known limitations**

* No advanced fraud/review-bomb detection.
* Moderation is manual admin workflow.

**Production action**

* Define abuse response SLAs; optional automated heuristics later (P2).

---

## DISPUTES

**Implemented controls**

* One dispute per booking model.
* Role-scoped open/respond/resolve flows with admin oversight.
* Payment-aware cancellation interactions where designed.

**Known limitations**

* No external arbitration/legal workflow.
* Evidence is text/API fields — no secure evidence vault.

**Production action**

* Legal/ops playbook for dispute resolution before real money launches.

---

## ADMIN

**Implemented controls**

* Cleaner approvals, user ops, booking oversight, payments/refunds, reviews, disputes, payouts, finance reconciliation.
* Persisted admin role required.
* Flutter admin surfaces with role routing guards.

**Known limitations**

* Powerful single admin role.
* No impersonation audit beyond existing audit log coverage.
* No step-up authentication.

**Production action**

* Protect admin accounts strongly; restrict who receives admin role in Atlas/user seed process.
* Prefer separate production admin network controls at the edge.

---

## AUDIT LOGGING

**Implemented controls**

* Append-only `audit_logs` collection for selected admin/security-sensitive actions.
* Best-effort side effects (primary mutation can succeed if audit append fails).

**Known limitations**

* Not a complete forensic pipeline for every mutation.
* No automated retention/export to WORM storage.
* Best-effort — gaps possible under failure.

**Production action**

* Define retention and export; alert on audit write failures if made observable.
* Do not treat audit as a distributed transaction substitute.

---

## CORS

**Implemented controls**

* Explicit `ALLOWED_ORIGINS` allow-list; never echoes `*`.
* Development empty list → localhost/127.0.0.1 only.
* Production validation requires non-empty allow-list; wildcard `*` rejected at boot.
* OPTIONS handled with security + CORS headers.

**Known limitations**

* Mobile apps are not browser CORS clients; CORS mainly protects browser-based callers if any.
* Misconfigured origins fail closed for CORS headers (may break a future web admin).

**Production action**

* Set exact production web origins if a browser client is introduced; keep list minimal.

---

## SECRETS

**Implemented controls**

* Backend `.env` gitignored; `.env.example` placeholders only.
* Runtime injection for containers; Docker build excludes `.env`.
* Flutter `API_BASE_URL` via `--dart-define` (public, not a secret store).
* Android release signing via external `key.properties` / keystore (not committed).
* Production boot validation for Mongo URI, access-token secret length, origins, commission.

**Known limitations**

* No cloud secrets-manager integration in-repo.
* Local developers may keep `.env` on disk.

**Production action**

* Use a secrets manager / platform secret store in real hosting.
* Never bake secrets into images or Flutter assets.

---

## TRANSPORT

**Implemented controls**

* Flutter release builds require `https://` `API_BASE_URL` (validated in `AppConfig`).
* Android main manifest: `INTERNET` permission; `usesCleartextTraffic="false"`.
* Debug-only cleartext exceptions for emulator localhost/`10.0.2.2`.
* API security headers: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` (HSTS left to reverse proxy).

**Known limitations**

* TLS termination is not implemented inside Dart Frog; operators must terminate TLS at proxy/load balancer.
* Certificate pinning not implemented.

**Production action**

* Deploy behind HTTPS reverse proxy with modern TLS and HSTS.
* Issue Play-ready signing keys outside the repository.

---

## ERROR HANDLING

**Implemented controls**

* JSON error envelope helpers (`jsonError`) with stable codes/messages.
* Root middleware catch-all returns generic `internal_error` without leaking stacks/Mongo details.
* Domain mappers for auth/role/payment errors.
* Request ID header correlation (`X-Request-Id` style resolver).

**Known limitations**

* Non-production may log unhandled errors to stderr without structured log shipping.
* Not all routes share identical mapping depth.

**Production action**

* Ship stderr/stdout to centralized logging; alert on 5xx rates.
* Avoid enabling verbose diagnostics in production.

---

## MONGODB

**Implemented controls**

* Backend-only `MONGODB_URI`; Flutter never embeds Atlas credentials.
* Indexed collections for users, sessions, bookings, payments, webhooks, earnings, payouts, etc.
* Deliberate index ensure via `dart run tool/ensure_database_indexes.dart` (not per request).
* Readiness endpoint pings Mongo.

**Known limitations**

* No automated migration framework beyond index ensure + application assumptions.
* Cross-document updates are not multi-document ACID transactions in all flows.

**Production action**

* Enable Atlas backups; test restore into non-production.
* Run index ensure as a controlled release step; verify indexes after restore.

---

## MOBILE CLIENT

**Implemented controls**

* Feature-oriented Flutter client; Dio API layer; Riverpod; go_router role guards.
* Secure storage for session tokens.
* Release HTTPS enforcement; stable `applicationId` `com.homecleaningmarketplace.app`.
* Development/sandbox UI labeling for fake payment/payout simulation.
* Logout / auth-identity isolation for user-scoped controllers.

**Known limitations**

* No crash-reporting or mobile attestation SDK (intentionally deferred).
* `dart-define` values are extractable from the binary.
* Release builds without `key.properties` fall back to debug signing (not Play-distributable).

**Production action**

* Always pass production HTTPS API URL at build time.
* Use real release keystore for store builds; keep keystore offline/secret.

---

## DEPENDENCIES

**Implemented controls**

* Pinned/known versions in `pubspec.yaml` / lockfiles for backend and Flutter.
* CI runs analyze + test on backend and Flutter.

**Known limitations**

* No automated SCA/CVE gate beyond what maintainers run manually.
* Dependency upgrades need regression testing.

**Production action**

* Periodically `dart pub outdated` / Flutter equivalent; patch high-severity issues.
* Prefer minimal new dependencies (TASK 022 constraint style).

---

## DEPLOYMENT

**Implemented controls**

* Multi-stage `backend/Dockerfile`; non-root runtime user; port 8080; secrets at runtime.
* `.dockerignore` excludes `.env`.
* GitHub Actions CI without production secrets or live Atlas.
* `tools/release_check.dart` hygiene + optional analyze/test gates.
* Production config validation at middleware boot.

**Known limitations**

* No in-repo Kubernetes/Terraform/cloud auto-deploy.
* Operators must supply TLS proxy, secrets, and Atlas themselves.

**Production action**

* Follow [deployment-architecture.md](../deployment/deployment-architecture.md) and container/Android runbooks.
* Do not auto-deploy from CI until a cloud target and approvals exist (deferred).

---

## LOGGING

**Implemented controls**

* Request IDs on responses.
* Avoid logging secrets, raw tokens, passwords, Mongo URIs.
* Unhandled errors: generic client message; limited stderr in non-production.

**Known limitations**

* No structured JSON logging standard or log sampling policy in-app.
* No PII redaction middleware beyond careful coding practice.

**Production action**

* Centralize container logs; define retention; redact emails/tokens in any custom log lines.

---

## BACKUPS

**Implemented controls**

* Documentation guidance for Atlas managed backups (this audit + operations runbook).
* Index ensure tooling to recreate operational indexes after restore.

**Known limitations**

* Backup/restore is **not** automated by this repository.
* Secrets are not in DB backups — must be restored separately.

**Production action**

* Enable Atlas backups with business-appropriate retention.
* Periodically test restore into an isolated non-production project.
* Never copy production data to developer laptops without authorization.

---

## INCIDENT RESPONSE

**Implemented controls**

* Session revoke APIs for credential theft response.
* Refresh replay detection can surface suspicious reuse.
* Financial reconciliation read API for certain ledger drift.
* Provider-unavailable safe failure modes in production for email/payment/payout sandbox absence.
* Operational runbook references for Atlas outage and secret rotation.

**Known limitations**

* No on-call roster, PagerDuty, or formal IR playbooks in-repo.
* No automated compromise detection pipeline.

**Production action**

* Before real users: define severity levels, contacts, revoke-all-sessions procedure, Atlas credential rotation, and customer communication templates.
* Practice tabletop: leaked `ACCESS_TOKEN_SECRET`, leaked webhook secret, Atlas unavailable.

---

## OWASP-style API / mobile risk mapping

This is a reasoned mapping, **not** OWASP certification.

| Risk theme | How addressed today | Remaining risk |
| --- | --- | --- |
| Broken object authorization | Role + ownership/membership checks on bookings, chat, earnings, admin gates | Gaps possible on new endpoints; needs review each feature |
| Broken authentication | Argon2id, JWT+refresh rotation/replay, verification gate, generic errors | No MFA; email delivery not production |
| Excessive data exposure | Privacy DTOs; secrets excluded from envelopes/`toString` | Admin APIs intentionally broad; review field sets |
| Unrestricted resource consumption | Some uniqueness/idempotency; no distributed rate limiter | Enumeration/DoS risk on public auth endpoints |
| Security misconfiguration | Production boot validation; CORS allow-list; cleartext off in release; `/dev` 404 in prod | Operator must configure TLS/proxy/secrets correctly |
| Injection | mongo_dart parameterized usage patterns; typed inputs | Always validate new query builders |
| Unsafe API consumption (mobile) | HTTPS required in release; no embedded DB secrets; sandbox honesty banners | API base URL extractable; debug cleartext only in debug |

---

## Secret rotation (summary)

| Secret | Effect of rotation | Notes |
| --- | --- | --- |
| `ACCESS_TOKEN_SECRET` | Existing access JWTs fail verification immediately | Users refresh or re-login; coordinate brief disruption |
| MongoDB Atlas credentials / URI | App cannot reach DB until updated everywhere | Update secrets manager + redeploy; keep old creds until drain |
| Sandbox webhook secrets | Dev/test only | Rotate in non-prod; production payment/payout secrets are future |

Never paste real values into tickets, git, or chat. Full steps: [operations-runbook.md](../deployment/operations-runbook.md).

---

## Backup / restore (summary)

* Enable Atlas managed backups for any environment with real user data.
* Retention follows Atlas tier and business policy (not fixed by this repo).
* Test restore into **non-production**; verify indexes via `dart run tool/ensure_database_indexes.dart`.
* Do not restore production data onto developer machines without authorization.
* Secrets live outside DB backups — restore them from the secrets manager separately.

---

## Verdict

| State | Assessment |
| --- | --- |
| Security architecture for a portfolio / software-release | Controls are coherent and documented |
| Production service with real money/email | **Not ready** until real providers, legal, monitoring, and IR basics land |

See [production-readiness-gap-register.md](../final/production-readiness-gap-register.md).
