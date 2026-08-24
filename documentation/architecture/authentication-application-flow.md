# Authentication Application Flow

TASK 011 introduced an HTTP-independent `AuthenticationService` and four thin Dart Frog routes. Cryptography, JWT issuance, and refresh-session rotation remain in the primitives from TASK 009 and TASK 010.

## Composition

Auth-route middleware under `routes/api/v1/auth/_middleware.dart` resolves a process-scoped `AuthenticationService`.

* Shared `ServerConfig` and `MongoDatabase` come from root middleware.
* MongoDB is not opened because `/health` was requested. The first auth request may `connect()` if a URI is configured.
* `PasswordHasher` is shared.
* A dummy Argon2id hash for missing-user login is generated **once** per successful composition, using a fixed fake password that is not a real credential.
* `ACCESS_TOKEN_SECRET` is validated by `JwtAccessTokenService.fromConfig`. There is no default signing key. Missing or short secrets fail at token use, not at process start.
* Route handlers receive `AuthenticationService` through Dart Frog `context.read`. They do not hash passwords, query MongoDB, or sign JWTs themselves.

If MongoDB is unconfigured, routes receive `UnconfiguredAuthenticationService` and return HTTP 503 `authentication_unavailable` without creating users or sessions.

## Signup

```text
HTTP POST /api/v1/auth/signup
  ↓ parse JSON / validate email, password, role
AuthenticationService.signUp
  ↓ ensure access-token configuration
  ↓ PasswordPolicy (15–128 Unicode code points)
  ↓ PasswordHasher.hash
  ↓ UserRepository.create (active, email_verified=false)
  ↓ AuthSessionService.createSession
  ↓ AccessTokenService.issue
```

Public roles are `customer` and `cleaner` only. Admin is rejected before persistence.

Duplicate normalized emails map to HTTP 409 `duplicate_email`.

### Non-transactional consequence

If `UserRepository.create` succeeds and later session creation fails, TASK 011 does **not** delete the new user. The account remains and can log in later. Signup is not atomic across `users` and `user_sessions`.

## Login

```text
HTTP POST /api/v1/auth/login
  ↓ parse JSON / validate and trim email
AuthenticationService.login
  ↓ UserRepository.findByEmail
  ↓ PasswordHasher.verify  (dummy hash if user missing)
  ↓ account-status check after a correct password
  ↓ optional password rehash
  ↓ AuthSessionService.createSession
  ↓ AccessTokenService.issue
```

Login does not apply the signup minimum length before verification. It does reject empty passwords and passwords longer than 128 Unicode code points. Passwords are not transformed.

### Missing-user dummy hash

When `findByEmail` returns null, the service still calls `PasswordHasher.verify` against a process-scoped dummy Argon2id hash, then returns the same `InvalidCredentialsException` used for a wrong password. The dummy hash is not a real credential and is not regenerated on every request. The goal is to avoid the large timing gap of skipping Argon2 entirely. This is not perfect constant-time network authentication.

Unknown email and wrong password both become HTTP 401 `invalid_credentials` with the same message.

### Account status

After a successful password verify:

* `active` → login continues
* `suspended` or `deactivated` → HTTP 403 `account_unavailable` (same external message)

### Transparent password rehash

After a correct password and an active account, if `passwordHasher.needsRehash(user.passwordHash)` is true:

1. hash the supplied password with the current Argon2id parameters
2. persist only `password_hash` and `updated_at` through `UserRepository.updatePasswordHash`
3. continue login

Wrong passwords and missing users never update hashes. Rehash is not exposed in the HTTP response.

## Refresh

```text
HTTP POST /api/v1/auth/refresh
  ↓ parse refresh_token
AuthenticationService.refresh
  ↓ AuthSessionService.rotateRefreshToken (atomic)
  ↓ UserRepository.findById
  ↓ revoke if missing or not active
  ↓ AccessTokenService.issue with current role
```

Rotation does not extend `expires_at`. Replay detection remains inside `AuthSessionService`. Externally, unknown, expired, revoked, replayed, and unavailable-user failures are all HTTP 401 `invalid_refresh_token`.

If rotation already produced a new refresh token and the user is then unavailable, the session is revoked and the new token is not returned.

## Logout

```text
HTTP POST /api/v1/auth/logout
  ↓ parse refresh_token
AuthenticationService.logout
  ↓ AuthSessionService.revokeSession
```

Unknown, expired, and already-revoked tokens still return HTTP 200. Logout does not delete session documents and does not return hashes or replacement tokens.

## What this layer does not do

* Flutter token storage or auth UI
* authentication middleware for marketplace routes
* `/me`, logout-all, password reset, email verification
* OAuth, MFA, captcha, Redis, session cookies
* production rate limiting
* live Atlas user/session fixtures
