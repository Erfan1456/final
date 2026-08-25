# Account Security API

This document describes TASK 020 account recovery, email verification, authenticated password change, and session management HTTP routes for the Home Cleaning Service Marketplace.

These endpoints extend the authentication API documented in [authentication-api.md](authentication-api.md). Production email delivery does **not** exist. Development and test environments may return a `development_action` payload with a raw token for local workflows only.

There is no MFA, OAuth, or production outbound email in TASK 020.

## Conventions

* JSON request and response fields use `snake_case`.
* Success envelope: `{ "success": true, "data": ... }`.
* Error envelope: `{ "success": false, "error": { "code": "...", "message": "..." } }`.
* Passwords are opaque: they are never trimmed, case-folded, or Unicode-normalized.
* Emails are trimmed for HTTP input. Identity lookup still uses repository trim + lowercase.
* Responses never include `password_hash`, `email_normalized`, refresh-token hashes, raw account-action tokens (except development/test `development_action`), MongoDB internals, stack traces, or signing secrets.
* Sensitive routes attach `Cache-Control: no-store` and `Pragma: no-cache`.

## Signup change (TASK 020)

`POST /api/v1/auth/signup` still creates a customer or cleaner account, but **no longer returns access or refresh tokens**.

Signup now:

1. creates the user (`active`, `email_verified = false`)
2. issues an email-verification account-action token
3. passes the raw token to the delivery boundary

The client must verify email before login succeeds.

### Success

HTTP **201**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "role": "customer",
      "email": "person@example.com",
      "account_status": "active",
      "email_verified": false,
      "created_at": "2026-08-25T12:00:00.000Z",
      "updated_at": "2026-08-25T12:00:00.000Z"
    },
    "verification_required": true,
    "development_action": {
      "purpose": "email_verification",
      "token": "AAAAfake-dev-token-not-for-production-use"
    }
  }
}
```

`development_action` is present only when `APP_ENV` is `development` or `test` and delivery succeeded. It is omitted in production.

### Signup errors (additional)

| Status | Code | When |
| --- | --- | --- |
| 503 | `account_action_delivery_unavailable` | User was created but delivery is unavailable in the current environment |

If user persistence succeeds and later token issuance or delivery fails, the account may remain. Signup is not a cross-collection transaction.

## Login change (verification enforcement)

`POST /api/v1/auth/login` now rejects unverified accounts:

HTTP **403**

```json
{
  "success": false,
  "error": {
    "code": "email_not_verified",
    "message": "Verify your email before signing in."
  }
}
```

All other login behavior is unchanged. See [authentication-api.md](authentication-api.md).

## POST /api/v1/auth/email-verification/request

Public, enumeration-resistant re-request of a verification token.

### Request

```json
{
  "email": "person@example.com"
}
```

### Success

HTTP **200** — same generic shape for eligible unverified accounts and non-eligible addresses:

```json
{
  "success": true,
  "data": {
    "message": "If verification is required for that account, instructions are available.",
    "development_action": {
      "purpose": "email_verification",
      "token": "BBBBfake-dev-token-not-for-production-use"
    }
  }
}
```

When no token is issued (unknown email, already verified, or delivery skipped internally), `development_action` is omitted and the message is unchanged.

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_json` / `invalid_email` / `invalid_input` | Malformed request |
| 503 | `account_action_delivery_unavailable` | Delivery provider unavailable |
| 503 | `authentication_unavailable` | MongoDB or auth infrastructure unusable |
| 405 | — | Method is not POST |
| 415 | `unsupported_media_type` | Content-Type is not JSON |

## POST /api/v1/auth/email-verification/verify

Consumes a one-time verification token. Does **not** issue a session.

### Request

```json
{
  "token": "CCCCfake-verify-token-not-for-production-use"
}
```

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "email_verified": true
  }
}
```

The client should redirect to login after success.

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_or_expired_account_action_token` | Unknown, expired, claimed, revoked, or wrong-purpose token |
| 400 | `invalid_json` / `invalid_input` | Malformed request |
| 503 | `authentication_unavailable` | Infrastructure unusable |

## POST /api/v1/auth/password-reset/request

Public, enumeration-resistant password-reset request.

### Request

```json
{
  "email": "person@example.com"
}
```

### Success

HTTP **200** — generic message for all emails:

```json
{
  "success": true,
  "data": {
    "message": "If an eligible account exists, password reset instructions are available.",
    "development_action": {
      "purpose": "password_reset",
      "token": "DDDDfake-reset-token-not-for-production-use"
    }
  }
}
```

No token is issued for unknown emails or deactivated accounts. The response message does not change.

### Errors

Same public-request error set as email-verification request.

## POST /api/v1/auth/password-reset/confirm

Consumes a reset token, updates the password, and revokes all refresh sessions for the user.

### Request

```json
{
  "token": "EEEEfake-reset-confirm-token-not-for-production-use",
  "new_password": "<opaque new password>"
}
```

New passwords must be 15–128 Unicode code points.

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "reauthentication_required": true
  }
}
```

The client must log in again. Previously issued access JWTs may remain valid until their normal 15-minute expiry.

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_or_expired_account_action_token` | Invalid reset token |
| 400 | `invalid_password` | New password fails policy |
| 400 | `invalid_json` / `invalid_input` | Malformed request |
| 403 | `account_unavailable` | Account is deactivated |
| 409 | `password_reuse_not_allowed` | New password matches current password |
| 503 | `authentication_unavailable` | Infrastructure unusable |

Password update, token claim, and session revocation are not one atomic cross-collection transaction.

## POST /api/v1/account/password/change

Authenticated password change. Requires a valid access JWT.

Revokes **all** refresh sessions for the user, including the current session.

### Request

```http
Authorization: Bearer <access-jwt-placeholder>
Content-Type: application/json
```

```json
{
  "current_password": "<opaque current password>",
  "new_password": "<opaque new password>"
}
```

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "reauthentication_required": true
  }
}
```

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_current_password` | Current password incorrect |
| 400 | `invalid_password` | New password fails policy |
| 401 | `invalid_access_token` | Missing or invalid Bearer token |
| 403 | `account_unavailable` | Account suspended or deactivated |
| 409 | `password_reuse_not_allowed` | New password matches current password |
| 503 | `authentication_unavailable` | Infrastructure unusable |

## GET /api/v1/account/sessions

Lists active owned sessions, newest first, capped at 50. Requires access JWT.

Never returns refresh-token hashes or raw refresh tokens.

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": "507f1f77bcf86cd799439012",
        "created_at": "2026-08-20T10:00:00.000Z",
        "expires_at": "2026-09-19T10:00:00.000Z",
        "last_rotated_at": "2026-08-25T08:00:00.000Z",
        "is_current": true
      },
      {
        "id": "507f1f77bcf86cd799439013",
        "created_at": "2026-08-10T09:00:00.000Z",
        "expires_at": "2026-09-09T09:00:00.000Z",
        "last_rotated_at": "2026-08-10T09:00:00.000Z",
        "is_current": false
      }
    ]
  }
}
```

### Errors

* Missing/invalid access token → HTTP **401** `invalid_access_token`
* Suspended/deactivated account → HTTP **403** `account_unavailable`

## DELETE /api/v1/account/sessions/{sessionId}

Revokes one owned session. Requires access JWT.

Foreign or unknown session IDs return HTTP **404** `session_not_found`. The API does not reveal whether a session existed for another user.

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "current_session_revoked": false
  }
}
```

When the revoked session matches the caller's access-token session, `current_session_revoked` is `true`. The client should clear local tokens and return to login.

### Errors

| Status | Code | When |
| --- | --- | --- |
| 404 | `session_not_found` | Session missing or not owned |
| 401 | `invalid_access_token` | Missing or invalid Bearer token |
| 403 | `account_unavailable` | Account unavailable |

## DELETE /api/v1/account/sessions

Revokes every refresh session for the authenticated user. Unchanged from TASK 012. See [authentication-api.md](authentication-api.md).

## Cache headers

All routes in this document that accept passwords, issue or consume account-action tokens, or may include `development_action` attach:

```http
Cache-Control: no-store
Pragma: no-cache
```

This includes signup, verification, reset, password change, and session listing/revocation responses.

## Development action

When `APP_ENV` is `development` or `test`, successful signup, verification request, and password-reset request responses may include:

```json
{
  "purpose": "email_verification",
  "token": "FFFFfake-dev-only-token"
}
```

or

```json
{
  "purpose": "password_reset",
  "token": "GGGGfake-dev-only-token"
}
```

The Flutter client uses this only for local testing. It must not be treated as a production delivery mechanism.

## Production delivery limitation

Production uses `UnavailableAccountActionDeliveryProvider`. Its `isAvailable` flag is `false`.

That means:

* signup after user creation fails with HTTP 503 `account_action_delivery_unavailable` when delivery cannot run
* verification and reset **request** routes fail with HTTP 503 before issuing tokens
* no raw token is ever returned in production HTTP responses
* integrating a real email or SMS provider is deferred

TASK 020 defines the provider-neutral `AccountActionDeliveryProvider` boundary so a future provider can be wired without changing token persistence or claim logic.

## Production security prerequisite

Public account-action and auth routes remain unsuitable for unrestricted internet exposure until production rate limiting exists. See [authentication-api.md](authentication-api.md).
