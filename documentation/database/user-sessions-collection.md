# User Sessions Collection

This document describes the `user_sessions` collection used for refresh-token session state.

TASK 010 established the collection model, repository contract, atomic rotation, replay detection, and indexes. Signup, login, refresh, and logout HTTP routes are not implemented.

## Purpose

One document represents one logical login/device session. Refresh-token rotation updates the same document. MongoDB stores only SHA-256 hashes of opaque refresh tokens, never the raw token.

## Document fields

```text
_id                       ObjectId
user_id                   ObjectId
refresh_token_hash        string   (SHA-256 of the current raw refresh token)
used_refresh_token_hashes [string] (previously consumed hashes)
expires_at                DateTime (UTC, absolute)
revoked_at                DateTime? (UTC, null when active)
created_at                DateTime (UTC)
last_rotated_at           DateTime (UTC)
```

## Storage rules

* Only hashes are stored.
* The raw refresh token is returned only to the future client and is never persisted.
* The same logical session document is rotated in place.
* Used hashes detect refresh-token replay.
* Absolute lifetime is 30 days. Rotation does not extend `expires_at`.
* Revocation sets `revoked_at` and retains the document so used hashes remain available until expiration.
* A TTL index on `expires_at` is cleanup only. Application code still checks `expires_at` because TTL deletion is not instantaneous.

## Indexes

* `user_sessions_refresh_token_hash_unique` — unique `refresh_token_hash` ascending
* `user_sessions_used_refresh_token_hashes` — `used_refresh_token_hashes` ascending
* `user_sessions_user_id` — `user_id` ascending
* `user_sessions_expires_at_ttl` — `expires_at` ascending, `expireAfterSeconds: 0`

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## Deferred

* signup/login/refresh/logout routes
* authentication middleware
* access-token denylist
* device fingerprint, IP, and user-agent fields
