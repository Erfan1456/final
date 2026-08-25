# Authentication API

This document describes the authentication HTTP API for the Home Cleaning Service Marketplace.

TASK 011 composed existing user, password, access-token, and refresh-session primitives into:

* `POST /api/v1/auth/signup`
* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `POST /api/v1/auth/logout`

TASK 012 added protected account routes:

* `GET /api/v1/account/me`
* `DELETE /api/v1/account/sessions`

TASK 020 changed signup and login verification behavior and added account recovery routes documented in [account-security-api.md](account-security-api.md):

* email verification request/verify
* password reset request/confirm
* authenticated password change
* session list and per-session revoke

There is still no production email delivery, OAuth, or MFA. Protected marketplace/product routes beyond account security are unchanged.

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

Email verification is required before login. Signup issues a verification action but does not return access or refresh tokens. Development/test responses may include `development_action`; production delivery is not integrated. See [account-security-api.md](account-security-api.md).

## Token object

Successful **login** and **refresh** return:

```json
{
  "access_token": "<jwt>",
  "refresh_token": "<opaque>",
  "token_type": "Bearer",
  "expires_in": 900
}
```

Signup does **not** return a token object. Refresh always returns a **new** refresh token. The previous token is consumed.

## POST /api/v1/auth/signup

Creates a customer or cleaner account and issues email verification. Does **not** issue an access JWT or refresh session.

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
    "verification_required": true,
    "development_action": {
      "purpose": "email_verification",
      "token": "<fake-dev-token-placeholder>"
    }
  }
}
```

`development_action` appears only in development/test when delivery succeeds. The client should not store tokens from signup.

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
| 503 | `account_action_delivery_unavailable` | User may exist but delivery is unavailable |
| 503 | `authentication_unavailable` | Auth infrastructure unusable |

If user persistence succeeds and later token issuance or delivery fails, the account may remain. Signup is not a cross-collection transaction. The user can retry verification request later.

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

HTTP **200** — `user` + `tokens` shape (signup no longer returns tokens):

```json
{
  "success": true,
  "data": {
    "user": { "...": "..." },
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
| 400 | `invalid_json` / `invalid_email` / `invalid_password` / `invalid_input` | Malformed request |
| 401 | `invalid_credentials` | Unknown email or wrong password |
| 403 | `email_not_verified` | Password correct but email not verified |
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

The API does not reveal whether the email exists. Unverified accounts receive HTTP 403 `email_not_verified` after a correct password. Suspended and deactivated accounts share the same 403 `account_unavailable` message after a correct password.

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

## Protected authentication

Protected account routes require:

```http
Authorization: Bearer <access-token>
```

Do not send passwords, refresh tokens, or Mongo credentials on these requests. Example tokens in this document are placeholders, never real credentials.

Missing header, wrong scheme, blank token, and every access-JWT verification failure return the same generic response:

HTTP **401**

```json
{
  "success": false,
  "error": {
    "code": "invalid_access_token",
    "message": "Authentication is required."
  }
}
```

If access-token verification cannot run because backend signing configuration is unavailable:

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

Public auth routes (`/auth/signup`, `/auth/login`, `/auth/refresh`, `/auth/logout`, verification, and password reset) and `/health` / `/ready` are not behind this middleware.

## GET /api/v1/account/me

Returns the currently authenticated user's safe public account.

The access JWT is verified first. The handler then loads the persisted `UserAccount` by the verified `userId`.

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "<user id>",
      "role": "customer",
      "email": "person@example.com",
      "account_status": "active",
      "email_verified": false,
      "created_at": "<iso-8601>",
      "updated_at": "<iso-8601>"
    }
  }
}
```

The persisted role is returned. Responses never include `password_hash`, `email_normalized`, session hashes, JWTs, or refresh tokens.

### Errors

* Missing/invalid access token → HTTP **401** `invalid_access_token`
* Missing user after a verified token → HTTP **401** `invalid_access_token`
* Suspended or deactivated account → HTTP **403** `account_unavailable`
* Auth configuration unavailable → HTTP **503** `authentication_unavailable`
* Wrong method → HTTP **405**

## DELETE /api/v1/account/sessions

Revokes every refresh session belonging to the authenticated user.

The access JWT used for this request may remain cryptographically valid until its normal 15-minute expiration. There is no access-token blacklist. Clients must delete local tokens immediately after logout-all.

### Success

HTTP **200**

```json
{
  "success": true,
  "data": {
    "sessions_revoked": true
  }
}
```

The response does not include token hashes, session documents, session IDs, or Mongo update details.

### Errors

* Missing/invalid access token → HTTP **401** `invalid_access_token`
* Auth configuration unavailable → HTTP **503** `authentication_unavailable`
* Wrong method → HTTP **405**

## Production security prerequisite

Before these endpoints are exposed to the public internet, a **production rate-limiting strategy** is required for:

* signup
* login
* refresh
* email verification request
* password reset request

The limiter must work across multiple backend instances. A single-process in-memory counter is not production protection.

CORS is not rate limiting. Password hashing slows credential stuffing but does not prevent it.

Rate limiting will be a later dedicated architecture task. Captcha, MFA, OAuth, and production email delivery are also deferred.

Account recovery, verification, password change, and session routes beyond logout-all are documented in [account-security-api.md](account-security-api.md).
