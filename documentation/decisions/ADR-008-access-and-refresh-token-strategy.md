# ADR-008 — Access and Refresh Token Strategy

## Status

Accepted.

## Context

Password hashing and user persistence exist, but signup and login must not be exposed until access-token issuance and refresh-session tracking are defined.

The application needs short-lived authorization credentials, revocable refresh sessions, atomic rotation, and replay detection without adding authentication HTTP routes yet.

## Decision

* dart_jsonwebtoken 3.4.1
* HS256 access JWT
* backend `ACCESS_TOKEN_SECRET`
* 15-minute access lifetime
* minimal claims (`sub`, `sid`, `role`, `jti`, `iat`, `exp`, `iss`, `aud`)
* opaque 256-bit refresh tokens
* SHA-256 refresh-token storage hashes
* `user_sessions` persistence
* 30-day absolute session lifetime
* atomic same-document rotation
* used-token-hash replay detection
* session revocation
* TTL cleanup

## Alternatives Considered

### Long-lived access JWT

Rejected because compromise impact lasts too long.

### JWT refresh tokens

Rejected because opaque server-tracked tokens provide straightforward revocation and rotation/replay state.

### Store raw refresh token

Rejected because a database leak would expose immediately usable credentials.

### Argon2 refresh-token hashing

Not selected because refresh tokens are high-entropy random machine-generated secrets and require deterministic lookup; SHA-256 is appropriate for this storage lookup boundary.

### New database document for every rotation

Not selected because same-session atomic replacement gives simpler concurrency control and replay detection without a multi-document transaction.

### Access-token blacklist

Deferred because short-lived JWTs limit exposure and a blacklist adds state to every access-token check.

### Asymmetric JWT signing

Viable for multi-service/public-key architectures, but HS256 is appropriate for the current single trusted backend. Reevaluate if architecture becomes multi-service.

## Consequences

* refresh requests require MongoDB session lookup
* access-token validation can remain cryptographic/stateless
* refresh replay can revoke sessions
* logout cannot retroactively erase a JWT already issued
* already-issued JWT lifetime is bounded to 15 minutes
* signing-secret management becomes a deployment responsibility

## Security

* Access tokens are signed HS256 JWTs with issuer, audience, expiry, and exact-algorithm checks
* Refresh tokens are opaque 256-bit secrets; only SHA-256 hashes are stored
* Unique `jti` values use secure randomness
* Atomic compare-and-modify prevents two rotations of the same current token
* Used hashes are retained until session expiration so replay can revoke the session
* `ACCESS_TOKEN_SECRET` has no default, is backend-only, and is never logged

## Deferred Decisions

* signup
* login
* refresh/logout routes
* authentication middleware
* Flutter secure token storage
* immediate access-token revocation
* asymmetric signing
* key rotation
* MFA
* rate limiting
* compromised-password screening
