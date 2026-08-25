# ADR-010 — Flutter Authentication and Secure Session Storage

## Status

Accepted

## Context

TASK 011 delivered public backend authentication HTTP routes. The Flutter client still had no session storage, no auth API client, and no login/signup UI. Refresh tokens rotate, so concurrent 401 handling must not send the same refresh token more than once. Android API 28+ blocks cleartext HTTP by default while local Dart Frog development uses HTTP.

## Decision

* Use `flutter_secure_storage` 11.0.0 as the only new Flutter dependency for this slice.
* Store the access/refresh token pair in platform secure storage as **one JSON value** under one stable key.
* Do not store passwords, password hashes, MongoDB URIs, `ACCESS_TOKEN_SECRET`, or user profile JSON.
* Use two Dio clients that share `API_BASE_URL` / `BaseOptions`:
  * **plain Dio** for signup, login, refresh, and logout
  * **authenticated Dio** for protected calls
* Attach `Authorization: Bearer <access-token>` only on authenticated Dio.
* Implement single-flight rotating-token refresh with a cached in-flight `Future`.
* Retry the original protected request **once** after a successful refresh. Mark retried requests so a second 401 cannot start another refresh loop.
* Emit a session-expiry event from the network layer; `AuthController` becomes unauthenticated.
* Restore sessions with `GET /api/v1/account/me`. Do not decode JWTs in Flutter for identity.
* Hold authentication state in Riverpod (`AuthController`).
* Enforce splash/login/signup/home redirects with `go_router` guards and a stable router `refreshListenable`.
* Allow debug-only local HTTP from the Android emulator (`10.0.2.2`, localhost, 127.0.0.1). Do not weaken release/`src/main` cleartext policy.
* Production API traffic must use HTTPS.
* Set Android `compileSdk` to 37 because `flutter_secure_storage` 11.0.0 compiles against API 37. Do not lower `minSdk`.

## Alternatives Considered

### SharedPreferences for tokens

Rejected. Tokens are credentials. SharedPreferences is not appropriate secure storage for this application.

### Decode JWT client-side and treat it as current user

Rejected. `/account/me` is authoritative. Client-side JWT decoding would drift from persisted role and account status and would require an extra decoder package.

### Refresh independently for every 401

Rejected because rotating refresh tokens make concurrent refresh unsafe. Independent refresh would consume the same token twice and lock the session.

### One Dio instance including refresh endpoint

Rejected because it increases recursion/interceptor complexity. Refresh must use plain Dio.

### Hard-coded localhost API

Rejected. `API_BASE_URL` is compile-time configuration. Android emulator localhost is the emulator, not the host.

### Release cleartext HTTP

Rejected. Cleartext is debug-only for local development.

### Store password for silent login

Rejected. Only the token pair is stored.

## Consequences

* Flutter can restore a session at startup and keep using short-lived access JWTs.
* Logout and logout-all always clear local tokens, including when the network is down.
* An access JWT may remain valid for up to 15 minutes after refresh sessions are revoked. There is no access-token blacklist.
* Debug Android builds can reach `http://10.0.2.2:8080`. Release builds must not rely on that exception.
* Local Android SDK 37 may install as platform folder `android-37.0`; Gradle still looks for `android-37`. That is an environment packaging issue, not an application-id or minSdk change.

## Security

* Passwords are never persisted on the device.
* Tokens are never logged or printed.
* Authorization headers are never logged.
* Flutter contains no `MONGODB_URI` and no `ACCESS_TOKEN_SECRET`.
* Backend protected principals are created only after `AccessTokenService.verify`.
* Protected account JSON never includes password hashes or token hashes.
* Invalid access tokens return generic 401 `invalid_access_token`.
* Auth configuration failures return generic 503 `authentication_unavailable`.

## Deferred Decisions

* biometrics
* device binding
* certificate pinning
* push notifications
* offline account cache
* final UI design
* email verification
* password reset
* MFA
* production rate limiting
* marketplace/service/booking features
