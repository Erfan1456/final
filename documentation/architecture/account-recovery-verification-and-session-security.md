# Account Recovery, Verification, and Session Security

This document describes TASK 020 backend and client flows for email verification, password recovery, authenticated password change, and per-session management.

Related documents:

* [account-security-api.md](../api/account-security-api.md)
* [account-action-tokens-collection.md](../database/account-action-tokens-collection.md)
* [authentication-application-flow.md](authentication-application-flow.md)
* [auth-token-and-session-security.md](auth-token-and-session-security.md)

Production outbound email is not integrated. MFA and OAuth are not implemented.

## Composition

TASK 020 adds:

* `AccountActionTokenService` — issue, replace, hash, and atomically claim one-time tokens
* `AccountActionDeliveryProvider` — provider-neutral delivery boundary
* `AccountSecurityService` — verification, reset, password change, and session listing/revocation
* `account_action_tokens` MongoDB collection
* HTTP routes under `/api/v1/auth/email-verification/*`, `/api/v1/auth/password-reset/*`, and `/api/v1/account/password/change` plus session list/revoke
* Flutter verification, recovery, account-security, and session-management screens

Signup and login behavior in `AuthenticationService` changed:

* signup no longer creates a refresh session or access JWT
* login rejects `email_verified = false`

## Opaque tokens and no raw storage

Account-action tokens follow the same storage principle as refresh tokens:

* 32 CSPRNG bytes → unpadded base64url raw token (256 bits)
* SHA-256 lowercase hex stored as `token_hash`
* raw token returned only to the delivery boundary
* never logged, never persisted, never included in generic error messages

Verification and reset tokens are one-time. Consumption sets `claimed_at` through a single-document atomic update.

## Signup flow

```text
HTTP POST /api/v1/auth/signup
  ↓ parse JSON / validate email, password, role
AuthenticationService.signUp
  ↓ PasswordPolicy + PasswordHasher.hash
  ↓ UserRepository.create (active, email_verified=false)
  ↓ AccountActionTokenService.issue (email_verification)
  ↓ AccountActionDeliveryProvider.deliverEmailVerification
  ↓ return SignupResult (no tokens)
```

### Signup does not authenticate

TASK 020 signup intentionally does **not** issue access or refresh tokens. The user must verify email, then log in through the normal login route.

This avoids creating an authenticated session for an unverified identity and keeps verification as an explicit step.

### Signup HTTP response

The client receives `user`, `verification_required: true`, and optionally `development_action` in development/test. It should navigate to a verification-pending screen, not store tokens.

### Signup non-transactional consequence

User creation and token issuance/delivery are separate persistence steps. If the user is stored and delivery later fails, the account exists without a delivered action. The user may retry verification request later. The backend does not delete the new user as compensation.

## Email verification flow

### Request (public)

```text
HTTP POST /api/v1/auth/email-verification/request
  ↓ EmailActionRequest
AccountSecurityService.requestEmailVerification
  ↓ find user by email
  ↓ if missing or already verified → generic success, no token
  ↓ else issue + deliver
```

The response message is always generic. Unknown emails and already-verified accounts receive the same HTTP 200 envelope.

### Consume (public)

```text
HTTP POST /api/v1/auth/email-verification/verify
  ↓ VerifyEmailRequest
AccountSecurityService.verifyEmail
  ↓ AccountActionTokenService.claim (email_verification)
  ↓ UserRepository.markEmailVerified
```

Verification does not log the user in. After success the client should route to login.

### Cross-document limitation

Token claim is atomic on `account_action_tokens`. Marking `users.email_verified` is a separate update. A failure after claim could leave a consumed token without a verified flag, or the reverse ordering risk on partial failures — callers see generic errors and may retry request when appropriate.

## Login after verification

```text
HTTP POST /api/v1/auth/login
  ↓ existing credential checks
  ↓ if !email_verified → EmailNotVerifiedException (403)
  ↓ else create session + issue access JWT
```

Unverified accounts cannot obtain tokens even with a correct password.

## Password reset flow

### Request (public, generic recovery)

```text
HTTP POST /api/v1/auth/password-reset/request
  ↓ EmailActionRequest
AccountSecurityService.requestPasswordReset
  ↓ find user by email
  ↓ if missing or deactivated → generic success, no token
  ↓ else issue + deliver (password_reset, 30-minute lifetime)
```

Same enumeration-resistant pattern as verification request.

### Confirm (public)

```text
HTTP POST /api/v1/auth/password-reset/confirm
  ↓ ConfirmPasswordResetRequest
AccountSecurityService.confirmPasswordReset
  ↓ findLive reset token
  ↓ load user, reject deactivated
  ↓ reject password reuse
  ↓ claim token
  ↓ update password hash
  ↓ AuthSessionService.revokeAllForUser
```

Response: `reauthentication_required: true`. All refresh sessions are revoked. Existing access JWTs may remain valid until expiry.

### Cross-document limitation

Password hash update, token claim, and session revocation are separate operations. Partial failure can require manual reconciliation. There is no multi-document transaction.

## Authenticated password change flow

```text
HTTP POST /api/v1/account/password/change
  ↓ Bearer access JWT verified by account middleware
AccountSecurityService.changePassword
  ↓ verify current password
  ↓ validate new password + reject reuse
  ↓ update password hash
  ↓ AuthSessionService.revokeAllForUser
```

Same post-change semantics as reset confirm: all sessions revoked, client must log in again.

Password change and session revocation are not one atomic cross-collection transaction.

## Session management flow

### List

```text
HTTP GET /api/v1/account/sessions
  ↓ verified principal (userId + sessionId from access JWT)
AccountSecurityService.listSessions
  ↓ list active sessions for user (max 50)
  ↓ mark is_current from principal.sessionId
```

Listed metadata never includes refresh-token hashes.

### Revoke one

```text
HTTP DELETE /api/v1/account/sessions/{sessionId}
  ↓ verified principal
AccountSecurityService.revokeSession
  ↓ revoke owned session only
  ↓ return current_session_revoked flag
```

Unknown or foreign session IDs → `session_not_found` without leaking ownership.

### Revoke all

`DELETE /api/v1/account/sessions` (TASK 012) revokes every session for the user. The access JWT used for the request may remain valid until its 15-minute expiry.

## Provider-neutral delivery

`AccountActionDeliveryProvider` is the only place raw account-action tokens leave the token service toward an external channel.

Implementations:

* `DevelopmentAccountActionDeliveryProvider` — development/test only; returns the raw token to the HTTP layer as `development_action`
* `UnavailableAccountActionDeliveryProvider` — production default; `isAvailable == false`

The token service and MongoDB layer do not know whether email, SMS, or another channel will carry the token. A future provider plugs in behind this interface.

## Dev-only delivery

When `ServerConfig.allowsDevelopmentAccountActions` is true (`APP_ENV` is `development` or `test`):

* delivery succeeds
* HTTP responses may include `development_action` with `purpose` and `token`
* Flutter screens can surface the token for manual copy/paste during local testing

Production never returns raw tokens, even if a secret or provider configuration is present elsewhere.

## Flutter client flows (TASK 020)

The Flutter client adds routes and controllers for:

* `/signup` → verification-pending after signup (no token storage)
* `/forgot-password` → generic success messaging
* `/reset-password?token=...` → confirm reset
* `/account/security` → hub for password change and sessions
* `/account/security/change-password`
* `/account/security/sessions`

Public auth calls use plain Dio. Authenticated account-security calls use Bearer tokens. After password change, reset confirm, or revoking the current session, controllers clear secure storage and require re-login.

Router guards improve UX but backend authorization remains authoritative.

## Privacy summary

* Public recovery/verification requests never confirm account existence.
* Invalid action tokens always share one generic error code and message.
* Sensitive responses use `no-store` cache headers.
* No MFA, OAuth, or production email in TASK 020.

## Deferred

* production email/SMS provider
* MFA and OAuth
* device/IP/user-agent on session list
* access-token denylist after password change or session revoke
* cross-document transactional verify/reset/password change
