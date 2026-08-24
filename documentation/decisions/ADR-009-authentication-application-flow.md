# ADR-009 — Authentication Application Flow

## Status

Accepted

## Context

TASK 008–010 established user persistence, Argon2id password hashing, HS256 access JWTs, and rotating opaque refresh sessions. The backend still had no signup, login, refresh, or logout HTTP API. TASK 011 needed to compose those primitives into application behavior without putting cryptography in route handlers, without enumerating accounts on login, and without mutating live Atlas application data from tests.

## Decision

* Dedicated `AuthenticationService` owns signup, login, refresh, and logout. It does not depend on Dart Frog request or response types.
* Dart Frog routes stay thin: parse JSON, call the service, map errors through the existing JSON envelope.
* Public signup creates only `customer` and `cleaner`. Admin self-registration is rejected.
* New public accounts are `active` with `email_verified = false`. Email verification is deferred and does not block login yet.
* Login credential failures are generic: unknown email and wrong password both return HTTP 401 `invalid_credentials`.
* Missing-user login still performs `PasswordHasher.verify` against a process-scoped dummy Argon2id hash.
* After a successful login password verify and an active-account check, outdated hashes are replaced through a narrow `UserRepository.updatePasswordHash` operation.
* Refresh uses `AuthSessionService` atomic rotation, then checks current account status before issuing a new access JWT.
* Logout is idempotent: unknown or already-revoked tokens still return success.
* Tests use fakes and in-memory stores. TASK 011 does not create live Atlas users or sessions.
* Production rate limiting is deferred but required before public internet exposure.

## Alternatives Considered

### Business logic directly in route handlers

Rejected. Routes would duplicate hashing, session rotation, and error mapping, and would be hard to test without Atlas.

### Returning "email not found" during login

Rejected because it enables account enumeration.

### Skipping hashing for nonexistent users

Rejected because it creates an obvious timing distinction versus Argon2 verification of a real hash.

### Apply current signup minimum password length during login

Rejected because future policy changes must not lock out legacy valid users. Login still enforces the 128-code-point maximum.

### Allow admin self-registration

Rejected. Admin provisioning will be designed separately.

### Delete a newly created user when session creation fails

Not selected in TASK 011 because implicit compensation can create additional failure modes. The account remains valid and can later log in.

### In-memory rate limiter

Not adopted as production protection because it does not coordinate across multiple backend instances.

## Consequences

* The first real auth HTTP API exists: signup, login, refresh, logout.
* Signup may durably create an account even if later session infrastructure fails.
* Login avoids basic user enumeration and performs dummy-hash verification for missing users.
* Password hashes can migrate transparently after successful login.
* Refresh checks current account status and revokes the session when the user is missing or inactive.
* Routes remain testable through `AuthenticationService` dependency overrides.
* Public deployment still requires multi-instance rate limiting.

## Security

* Passwords are never logged, trimmed, case-folded, or Unicode-normalized.
* Access tokens, refresh tokens, token hashes, and `ACCESS_TOKEN_SECRET` are never logged or returned in error bodies.
* User HTTP JSON omits `password_hash` and `email_normalized`.
* JWT creation stays in `AccessTokenService`. Password hashing stays in `PasswordHasher`. Session token generation stays in `AuthSessionService`.
* There is no default signing secret. Missing or short secrets yield HTTP 503 `authentication_unavailable` without creating a user first.
* Replay remains internally enforced; clients only see generic invalid refresh errors.
* `backend/.env` remains gitignored.

## Deferred Decisions

* email verification delivery and enforcement
* password reset
* authentication middleware
* protected marketplace routes
* logout-all HTTP route
* production rate limiting
* captcha
* MFA
* OAuth
* Flutter secure token storage
* Flutter auth UI
