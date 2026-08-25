# Account Action Tokens Collection

This document describes the `account_action_tokens` collection used for one-time email verification and password-reset actions.

TASK 020 established hashed opaque tokens, atomic claim, replacement, TTL cleanup, and a provider-neutral delivery boundary. Production email delivery is not integrated.

## Purpose

One document represents one issued one-time account-action token. Tokens confirm email ownership or authorize a password reset. MongoDB stores only SHA-256 hashes of opaque raw tokens, never the raw token.

Each token is scoped to:

* one user (`user_id`)
* one purpose (`email_verification` or `password_reset`)

A user may have many historical token documents, but only live unclaimed tokens for the same purpose matter for consumption.

## Document fields

```text
_id          ObjectId
user_id      ObjectId
purpose      string     (email_verification | password_reset)
token_hash   string     (SHA-256 lowercase hex of the raw token)
expires_at   DateTime   (UTC, absolute)
claimed_at   DateTime?  (UTC, set when consumed)
revoked_at   DateTime?  (UTC, set when superseded by a newer issue)
created_at   DateTime   (UTC)
```

## Hashed token storage

* Raw tokens are 32 CSPRNG bytes encoded as unpadded base64url (256 bits of entropy).
* Only `token_hash` is persisted. The hash is SHA-256 lowercase hex via hashlib.
* The raw token is returned only to the delivery boundary and is never logged.
* Argon2 is not used here. Tokens are high-entropy random secrets requiring deterministic lookup, similar to refresh-token hashing.

## Expiry

Application lifetimes are centralized in `AccountActionPolicy`:

| Purpose | Lifetime |
| --- | --- |
| `email_verification` | 24 hours |
| `password_reset` | 30 minutes |

Application code always checks `expires_at` because MongoDB TTL deletion is asynchronous.

## Live token definition

A token is **live** when all of the following are true:

* `claimed_at == null`
* `revoked_at == null`
* `expires_at` is still in the future (UTC)

Repository queries for claim and lookup use this live selector.

## Atomic claim

Consumption uses a single-document atomic `findAndModify`:

1. Match a live document by `token_hash` and `purpose`.
2. Set `claimed_at` to the current UTC time.
3. Return the updated document, or `null` when no live match exists.

Two concurrent requests using the same raw token cannot both claim successfully. The second request sees a non-live document and fails with a generic invalid-token error.

Claim happens on:

* email verification (`verifyEmail`)
* password-reset confirmation after pre-checks (`confirmPasswordReset`)

## Replacement on re-issue

When a new token is issued for the same `user_id` and `purpose`, the service first sets `revoked_at` on all other live unclaimed tokens for that user and purpose, then inserts the new hashed token document.

This means:

* only the newest live token for a purpose can be consumed
* older unclaimed tokens become unusable without being claimed

Re-issue happens on signup, verification re-request, and password-reset request.

## Indexes

* `account_action_tokens_token_hash_unique` — unique `token_hash` ascending
* `account_action_tokens_user_purpose_created` — `user_id`, `purpose`, `created_at` descending
* `account_action_tokens_expires_ttl` — `expires_at` ascending, `expireAfterSeconds: 0`

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## TTL cleanup

The TTL index on `expires_at` removes expired documents eventually. It is cleanup only. Handlers and services must still enforce expiry in application code.

## Cross-document limitation

Account-action flows are **not** MongoDB multi-document transactions.

Examples:

* Signup creates a `users` document, then issues a verification token. If delivery is unavailable after the user is stored, the account remains without a delivered action.
* Email verification atomically claims the token, then updates `users.email_verified` in a separate step.
* Password reset validates the token, updates `users.password_hash`, then revokes all `user_sessions` in separate steps.

A failure after one step can leave durable state that a later retry or support action must reconcile. The system does not silently roll back prior writes across collections.

## Privacy

* Raw tokens, token hashes, and recipient email must not appear in logs, error bodies, or audit metadata.
* Public request endpoints return generic messages that do not reveal whether an email exists or is already verified.
* Invalid, expired, claimed, revoked, and wrong-purpose tokens share one generic client error.
* HTTP responses that may contain tokens or development delivery payloads use `Cache-Control: no-store` and `Pragma: no-cache`.

## Deferred

* production email/SMS delivery integration
* MFA or OAuth account recovery
* storing delivery attempt history
* cross-document transactional claim plus user update
