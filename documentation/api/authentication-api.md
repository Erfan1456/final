# Authentication API

This document describes the first authentication HTTP API for the Home Cleaning Service Marketplace.

TASK 011 composed existing user, password, access-token, and refresh-session primitives into:

* `POST /api/v1/auth/signup`
* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `POST /api/v1/auth/logout`

There is still no `/me` endpoint, logout-all, password reset, email-verification delivery, OAuth, MFA, authentication middleware, or protected marketplace route.

These endpoints are **not** ready for unrestricted public internet exposure until production rate limiting exists. Argon2id hashing and CORS are not substitutes for request throttling.

## Conventions

* JSON request and response fields use `snake_case`.
* Success envelope: `{ "success": true, "data": ... }`.
* Error envelope: `{ "success": false, "error": { "code": "...", "message": "..." } }`.
* Access tokens last **15 minutes** (`expires_in`: `900`).
* Refresh sessions last **30 days** absolutely. Rotation does not extend `expires_at`.
* Unknown JSON fields on these four requests are ignored.
* Passwords are opaque: they are never trimmed, case-folded, or Unicode-normalized.
* Emails are trimmed for HTTP input. Identity lookup still uses repository trim + lowercase. Display email is not lowercased merely because a normalized form exists.
* Responses never include `password_hash`, `email_normalized`, refresh-token hashes, used-hash lists, MongoDB internals, stack traces, or signing secrets.

## Public signup roles

Public signup may create only:

* `customer`
* `cleaner`

`admin`, unknown, and missing roles fail validation with HTTP 400. Administrators are not self-registered.

A cleaner account may be created with `role = cleaner`. Cleaner onboarding, verification, and approval are later features.

## New account defaults

Public signup creates:

* `account_status = active`
* `email_verified = false`

Email-verification delivery does not exist yet. Login is not blocked solely because `email_verified` is false. That enforcement is deferred.

## Token object

Successful signup, login, and refresh return:

```json
{
  "access_token": "<jwt>",
  "refresh_token": "<opaque>",
  "token_type": "Bearer",
  "expires_in": 900
}
```

Refresh always returns a **new** refresh token. The previous token is consumed.

## POST /api/v1/auth/signup

Creates a customer or cleaner account, then issues an access JWT and a refresh session.

### Request

`Content-Type: application/json`

```json
{
  "email": "person@example.com",
  "password": "<opaque password>",
  "role": "customer"
}
```

Signup passwords must be 15–128 Unicode code points.

### Success

HTTP **201**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "<object id hex>",
      "role": "customer",
      "email": "person@example.com",
      "account_status": "active",
      "email_verified": false,
      "created_at": "<iso-8601 utc>",
      "updated_at": "<iso-8601 utc>"
    },
    "tokens": {
      "access_token": "<jwt>",
      "refresh_token": "<opaque>",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}
```

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_json` | Body is not a JSON object |
| 400 | `invalid_email` | Email missing, empty after trim, too long, or malformed |
| 400 | `invalid_password` | Password fails signup policy |
| 400 | `invalid_role` | Role is admin, unknown, or invalid |
| 400 | `invalid_input` | Required field missing or wrong type |
| 409 | `duplicate_email` | Normalized email already exists |
| 405 | — | Method is not POST |
| 415 | `unsupported_media_type` | Content-Type is not JSON |
| 503 | `authentication_unavailable` | Signing secret missing/invalid or auth infrastructure unusable |

If user persistence succeeds and later session creation fails, the account remains. The user can log in later. Signup is not a cross-collection transaction.

## POST /api/v1/auth/login

Authenticates an existing account and issues new tokens.

### Request

```json
{
  "email": "person@example.com",
  "password": "<opaque password>"
}
```

Login does **not** reject passwords merely because they are shorter than the current signup minimum. It does reject empty passwords and passwords longer than 128 Unicode code points.

### Success

HTTP **200** — same `user` + `tokens` shape as signup.

### Errors

| Status | Code | When |
| --- | --- | --- |
| 400 | `invalid_json` / `invalid_email` / `invalid_password` / `invalid_input` | Malformed request |
| 401 | `invalid_credentials` | Unknown email or wrong password |
| 403 | `account_unavailable` | Password was correct but the account is suspended or deactivated |
| 405 | — | Method is not POST |
| 415 | `unsupported_media_type` | Content-Type is not JSON |
| 503 | `authentication_unavailable` | Auth configuration/infrastructure unusable |

Unknown email and wrong password both return:

```json
{
  "success": false,
  "error": {
    "code": "invalid_credentials",
    "message": "Invalid email or password."
  }
}
```

The API does not reveal whether the email exists. Suspended and deactivated accounts share the same 403 `account_unavailable` message after a correct password.

## POST /api/v1/auth/refresh

Rotates the refresh token and issues a new access JWT. Does not return a user object.

### Request

```json
{
  "refresh_token": "<opaque>"
}
```

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "tokens": {
      "access_token": "<jwt>",
      "refresh_token": "<new opaque>",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}
```

After rotation, the current account must still be active. Missing, suspended, or deactivated users cause the session to be revoked. The newly generated refresh token is not returned.

### Errors

Unknown, expired, revoked, replayed, and unavailable-user cases all return HTTP **401**:

```json
{
  "success": false,
  "error": {
    "code": "invalid_refresh_token",
    "message": "Refresh token is invalid or expired."
  }
}
```

The client is never told that replay was detected, that a user was deleted, or that a session was revoked.

## POST /api/v1/auth/logout

Revokes the session identified by the presented refresh token. Idempotent: unknown, expired, already-revoked, and valid tokens all return success. Session documents are not deleted.

### Request

```json
{
  "refresh_token": "<opaque>"
}
```

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "logged_out": true
  }
}
```

Logout does not reveal whether the token or session existed. It does not issue replacement tokens.

## Production security prerequisite

Before these endpoints are exposed to the public internet, a **production rate-limiting strategy** is required for:

* signup
* login
* refresh

The limiter must work across multiple backend instances. A single-process in-memory counter is not production protection.

CORS is not rate limiting. Password hashing slows credential stuffing but does not prevent it.

Rate limiting will be a later dedicated architecture task. Captcha, MFA, and OAuth are also deferred.
