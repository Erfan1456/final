# Auth Token and Session Security

This document describes the access-token and refresh-session security boundary used by future authentication.

TASK 010 established these primitives. Signup, login, refresh, logout, and protected routes are not implemented.

## Access tokens

Signed JWTs issued by the backend.

* Library: `dart_jsonwebtoken` 3.4.1
* Algorithm: HS256 only
* Lifetime: 15 minutes
* Issuer: `home_cleaning_marketplace_api`
* Audience: `home_cleaning_marketplace`
* Claims: `sub`, `sid`, `role`, `jti`, `iat`, `exp`, `iss`, `aud`
* `jti`: 16 cryptographically secure random bytes, base64url without padding

Verification requires signature, exact HS256, expiration, issuer, audience, required claims, ObjectId syntax for `sub`/`sid`, and a known `UserRole` wire value. Unverified `JWT.decode` payloads are not trusted. The JOSE header is inspected only to reject non-HS256 algorithms before signature verification.

`ACCESS_TOKEN_SECRET` is backend-only. It has no default. The process can start without it because no authentication route is active. Token-service construction rejects missing or short secrets (fewer than 32 UTF-8 bytes). The secret is never logged or included in `ServerConfig.toString`.

Access JWT payloads are signed, not encrypted. They must not contain password hashes, refresh tokens, email, profile, or payment data.

## Refresh tokens

Opaque secrets, not JWTs.

* 32 cryptographically secure random bytes (256 bits)
* Encoded as base64url without padding
* No user ID, email, role, session metadata, JSON, or claims in the token
* Storage hash: SHA-256 of the raw token as lowercase hexadecimal via hashlib
* The raw token is never persisted and never hashed with Argon2

## Rotation

Successful rotation is one atomic MongoDB compare-and-modify on the same `user_sessions` document:

* Match current `refresh_token_hash`, `revoked_at == null`, and `expires_at` still in the future
* Move the old hash into `used_refresh_token_hashes`
* Set the new hash as `refresh_token_hash`
* Update `last_rotated_at`
* Do not extend `expires_at`

Two concurrent requests using the same current refresh token cannot both succeed.

## Replay detection

If a presented token hash is no longer current but appears in `used_refresh_token_hashes`, the token was already consumed. The logical session is revoked and no new refresh token is issued (`RefreshTokenReuseDetectedException`). Unknown, expired, and already-revoked tokens fail generically (`InvalidRefreshTokenException`). Future HTTP routes must not expose this distinction to unauthenticated clients.

## Sessions

* Absolute lifetime: 30 days
* Revoke one session by refresh token or session id
* Revoke all sessions for a user
* TTL cleanup on `expires_at` with `expireAfterSeconds: 0`

## Security tradeoff

Revoking a `UserSession` prevents future refreshes. A previously issued access JWT remains cryptographically valid until its 15-minute `exp` unless a later authorization design adds an immediate status check. This is an intentional short-lived-JWT tradeoff. TASK 010 does not implement an access-token blacklist.

## Current state

Token and session primitives exist. There are no authentication HTTP endpoints.
