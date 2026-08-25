# ADR-018 — Account Recovery, Verification, and Session Security

## Status

Accepted

## Context

TASK 008–012 established user persistence, Argon2id passwords, HS256 access JWTs, rotating refresh sessions, public signup/login/refresh/logout, and protected account routes. Signup returned tokens immediately, `email_verified` was stored but not enforced, and there was no password reset, verification delivery, authenticated password change, or per-session listing/revocation.

TASK 020 needed account recovery and verification without claiming production email, MFA, or OAuth; without storing raw one-time tokens; without enabling login for unverified accounts; and without putting business logic in route handlers.

## Decision

- **Dedicated `account_action_tokens` collection.** Hashed one-time tokens for `email_verification` (24 hours) and `password_reset` (30 minutes). Raw tokens are 256-bit opaque secrets; only SHA-256 lowercase hex is stored.
- **Atomic single-document claim.** Consumption uses `findAndModify` on a live token match (`claimed_at` / `revoked_at` null, `expires_at` future). Concurrent duplicate claims fail generically.
- **Replace on re-issue.** New issue revokes other live tokens for the same user and purpose before insert.
- **TTL index on `expires_at`.** Cleanup only; application code still enforces expiry.
- **Provider-neutral `AccountActionDeliveryProvider`.** Token persistence and HTTP handlers do not depend on a specific email/SMS vendor.
- **Development/test delivery only.** `DevelopmentAccountActionDeliveryProvider` may return raw tokens as `development_action` in HTTP JSON when `APP_ENV` is `development` or `test`. Production uses `UnavailableAccountActionDeliveryProvider` (`isAvailable == false`).
- **Signup no auth.** `POST /auth/signup` creates the user and issues verification delivery but does **not** create a refresh session or access JWT. Response includes `verification_required: true`.
- **Login enforcement.** Unverified accounts receive HTTP 403 `email_not_verified`.
- **`AccountSecurityService`.** Owns verification request/consume, reset request/confirm, authenticated password change, session list, and single-session revoke. HTTP-independent of Dart Frog.
- **Generic public recovery.** Verification and reset request endpoints return the same success message whether or not a token was issued. No account enumeration.
- **Password change and reset revoke all sessions.** Reset confirm and authenticated change update the password hash then call `revokeAllForUser`. Responses include `reauthentication_required: true`.
- **Session list cap.** At most 50 active sessions returned, newest first, with `is_current` derived from the access JWT `sid`.
- **Sensitive cache headers.** Routes that handle passwords or may expose `development_action` attach `Cache-Control: no-store` and `Pragma: no-cache`.
- **Thin Dart Frog routes.** Parse JSON, call services, map errors through the existing envelope.
- **Tests use fakes and in-memory stores.** TASK 020 does not require live Atlas mutation for account-action token tests.

## Alternatives Considered

### Keep issuing tokens on signup

Rejected because it authenticated unverified identities and skipped an explicit verification step.

### Store raw account-action tokens in MongoDB

Rejected because a database leak would expose immediately usable verification/reset links.

### JWT or signed URL as the one-time action token

Rejected in favor of opaque server-tracked tokens with atomic claim state, consistent with refresh-token design.

### Argon2 hash account-action tokens

Not selected because tokens are high-entropy random secrets requiring deterministic lookup; SHA-256 is appropriate at this storage boundary.

### Send different HTTP responses when email is unknown

Rejected because it enables account enumeration on public recovery routes.

### Log the user in automatically after email verification

Rejected to keep verification separate from session creation and to preserve explicit login auditing.

### Production stub that silently drops delivery while returning success

Rejected because production must not pretend delivery succeeded when no provider exists. Unavailable delivery returns HTTP 503 on routes that require it.

### Multi-document MongoDB transaction for claim + user update

Not selected in TASK 020. Same-document atomic claim is sufficient for token replay; cross-collection steps remain explicit separate operations with documented reconciliation limits.

### Delete newly created user when verification delivery fails

Not selected because implicit compensation adds failure modes. The account remains; the user can retry verification request.

### Per-session metadata (device, IP, user-agent) on list

Deferred; not required for revoke-by-id correctness.

### Access-token blacklist after password change

Deferred; short-lived JWT tradeoff remains. Clients must clear local tokens when `reauthentication_required` is true.

## Consequences

- Signup UX requires a verification step before login.
- Production signup and public verification/reset **request** routes fail with HTTP 503 until a real delivery provider is integrated.
- Development and test environments can complete flows locally via `development_action`.
- Password reset and change invalidate all refresh sessions; clients must re-login.
- Listed sessions expose safe metadata only; refresh hashes never appear in API JSON.
- Account-action flows are testable through service fakes without Atlas writes.
- Cross-collection steps (user update, token claim, session revoke) can leave partial state on failure; operators may need retry or manual reconciliation.

## Security

- Raw account-action tokens, token hashes, and delivery recipient email are never logged or placed in error bodies.
- Public request endpoints use enumeration-resistant generic messages.
- Invalid, expired, claimed, revoked, and wrong-purpose tokens map to one generic client error.
- Production never returns raw action tokens in HTTP responses.
- `development_action` is gated by environment, not by client request headers.
- Password reuse on reset/change is rejected.
- Deactivated accounts cannot complete reset confirm.
- Session revoke-by-id returns `session_not_found` for foreign sessions without revealing existence to other users.
- Sensitive responses use `no-store` cache headers.
- `backend/.env` remains gitignored. No production email credentials in TASK 020.

## Deferred Decisions

- production email or SMS provider integration
- MFA
- OAuth social login/recovery
- access-token denylist after credential or session events
- cross-document transactional verify/reset/password change
- delivery attempt audit trail
- session list device/IP/user-agent metadata
- production rate limiting for verification and reset routes (still required before public internet exposure, same as login/signup)
