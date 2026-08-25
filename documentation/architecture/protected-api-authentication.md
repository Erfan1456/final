# Protected API Authentication

This document describes Bearer access-JWT authentication for protected Dart Frog routes.

Public authentication remains:

* `POST /api/v1/auth/signup`
* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `POST /api/v1/auth/logout`

Those routes are **not** authenticated with an access token. Protected account routes live under `/api/v1/account/` and require a verified Bearer JWT.

See [authentication-application-flow.md](authentication-application-flow.md), [auth-token-and-session-security.md](auth-token-and-session-security.md), [flutter-authentication.md](flutter-authentication.md), [../api/authentication-api.md](../api/authentication-api.md), and [../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md](../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md).

## Bearer access JWT boundary

Protected requests send:

```http
Authorization: Bearer <access-token>
```

`AccessAuthenticator` reads the header, requires the Bearer scheme, extracts a non-empty token, and verifies it through `AccessTokenService`. It does not call JWT decode APIs and does not reimplement HS256.

Verification rejects:

* missing Authorization
* wrong scheme
* blank token
* malformed JWT
* bad signature
* expired JWT
* wrong issuer
* wrong audience
* non-HS256 JWT
* malformed user/session IDs
* invalid role

External failures use one generic authentication response:

```json
{
  "success": false,
  "error": {
    "code": "invalid_access_token",
    "message": "Authentication is required."
  }
}
```

HTTP status is **401**. JWT parser details are not exposed.

If token verification infrastructure is unavailable because `ACCESS_TOKEN_SECRET` is missing or otherwise unusable:

HTTP **503**

```json
{
  "success": false,
  "error": {
    "code": "authentication_unavailable",
    "message": "Authentication is temporarily unavailable."
  }
}
```

`ACCESS_TOKEN_SECRET` is backend-only configuration. Its value is never logged, never returned, and never placed in Flutter.

## AuthenticatedPrincipal

After successful access-token verification, routes receive an `AuthenticatedPrincipal`:

* `userId` — account ObjectId
* `sessionId` — refresh-session ObjectId from the `sid` claim
* `role` — role encoded in the verified JWT
* `jwtId` — JWT `jti`

The principal is created **only** after `AccessTokenService.verify` succeeds. It does not include password, email, refresh token, token hash, or Mongo credentials.

## Protected account middleware

`backend/routes/api/v1/account/_middleware.dart` authenticates every route under `/api/v1/account/`.

It:

1. resolves `AccessTokenService` from `ServerConfig`
2. authenticates the request
3. provides `AuthenticatedPrincipal` on `RequestContext`
4. then resolves `CurrentAccountService` for Mongo-backed account use cases

It does **not** wrap:

* `GET /`
* `GET /api/v1/health`
* `GET /api/v1/ready`
* `POST /api/v1/auth/login`
* `POST /api/v1/auth/signup`
* `POST /api/v1/auth/refresh`
* `POST /api/v1/auth/logout`

`/api/v1/health` remains independent of MongoDB even though account routes exist.

## GET /api/v1/account/me

Returns the currently authenticated user's safe public account representation.

After JWT verification:

1. load `UserAccount` by `principal.userId`
2. missing user → generic 401 `invalid_access_token`
3. active → HTTP 200 with the safe user object
4. suspended or deactivated → HTTP 403 `account_unavailable`

The persisted role from `UserAccount` is returned, not a client-supplied role. Responses never include `password_hash`, `email_normalized`, session hashes, JWTs, or refresh tokens.

Wrong method: HTTP **405**.

## DELETE /api/v1/account/sessions

Revokes **all** refresh sessions belonging to `principal.userId`.

Success:

```json
{
  "success": true,
  "data": {
    "sessions_revoked": true
  }
}
```

The response does not include token hashes, session documents, session IDs, or Mongo update details.

Wrong method: HTTP **405**.

## Account-status behavior

`GET /api/v1/account/me` uses the persisted `UserAccount`:

* missing user → generic 401 `invalid_access_token`
* active → 200 safe user
* suspended or deactivated → 403 `account_unavailable`

`DELETE /api/v1/account/sessions` authenticates the access JWT, then revokes every refresh session for `principal.userId`. It does not re-check account status after verification. `getCurrentUser` is the account-status gate for the current-user endpoint.

## Access-token revocation tradeoff

Access JWTs last **15 minutes**. There is **no access-token blacklist**.

`DELETE /api/v1/account/sessions` (and logout-all from Flutter) immediately revokes refresh sessions. The access JWT used to make that request may remain cryptographically valid until its normal expiration.

Clients must delete local tokens immediately after successful or locally forced logout-all. Protected APIs should treat a revoked refresh session as unrecoverable once the short-lived access token expires.

## Refresh-session revocation

Refresh sessions are opaque rotating tokens stored hashed in `user_sessions`. Revoking all sessions for a user marks those sessions revoked so later `POST /api/v1/auth/refresh` calls fail with generic `invalid_refresh_token`.

Replay detection and rotation rules from TASK 010/011 still apply to remaining live sessions.

## No access-token blacklist

TASK 012 does not introduce an access-token denylist, Redis invalidation set, or JWT `jti` blocklist. Short expiry plus refresh-session revocation is the current logout-all model.
