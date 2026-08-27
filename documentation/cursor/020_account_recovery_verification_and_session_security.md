# Cursor Task 020 — Account Recovery, Verification, and Session Security

## Metadata

- Task ID: 020
- Task title: Email Verification, Password Recovery, Password Change, Session Management, and Authentication Hardening
- Date: 2026-08-26
- Git branch: main (TASK 020 work remains uncommitted for ChatGPT review)
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Recovery Note

The first TASK 020 Cursor run ended unexpectedly during backend implementation. Existing uncommitted work was preserved; no `git reset`, `git restore`, `git clean`, or `git stash` was performed. Repository state was inspected for incomplete writes; backend and Flutter verification was rerun from the preserved changes. TASK 020 was completed from that state.

TASK 020R was a recovery continuation prompt used after the interrupted first run. It is **not** the authoritative original TASK 020 prompt. The authoritative original prompt is embedded verbatim below under **Exact Cursor Prompt**. TASK 020C later corrected report completeness and analyzer cleanliness without redesigning features.

## Objective

Complete account security lifecycle: email verification before session issuance, password recovery, authenticated password change, shared account-action tokens, session management, authentication hardening, development-only delivery boundary, Flutter UX, tests, documentation. No MFA, OAuth, or production email provider.

## Pre-Task Verification

- Branch: `main`
- Baseline HEAD at TASK 020 start: `9a5b7a3` (TASK 019 checkpoint)
- Backend baseline: `dart analyze` clean; `dart test` **483 passed**
- Flutter baseline: `flutter analyze` clean; `flutter test` **349 passed**
- `backend/.env` gitignored (`.gitignore:8:.env`)
- No new direct dependencies added

## Final Verification

| Check | Result |
|-------|--------|
| Backend `dart analyze` | **No issues found!** (completely clean after TASK 020C) |
| Backend `dart test` | **502 passed** |
| Dart Frog routes | Present: email-verification request/verify, password-reset request/confirm, account/password/change, account/sessions (+ sessionId) |
| Live index ensure | `account_action_tokens_*` indexes verified (prior TASK 020 run) |
| Flutter `flutter analyze` | **No issues found!** (0 issues) |
| Flutter `flutter test` | **370 passed** |
| Flutter `flutter build apk --debug` | **Success** (`build/app/outputs/flutter-apk/app-debug.apk`) |
| Live GET `/`, `/health`, `/ready`, `/services` | Prior TASK 020: **200** each (port 8100). Not re-run in TASK 020C (corrections were report + analyzer/style only; no account-security mutation live calls) |
| Commit | **None** — TASK 020 / 020C remain uncommitted |

## Implementation Summary

### Backend

- Shared `account_action_tokens` collection with `AccountActionPurpose`, SHA-256 hashed opaque tokens, atomic claim, replacement, TTL indexes
- `AccountActionDeliveryProvider` with development/test provider only; production returns `503 account_action_delivery_unavailable`
- Signup creates unverified user, issues verification token, **no session/tokens**
- Login enforces `email_verified` after password check → `403 email_not_verified`
- Email verification request/consume, password reset request/confirm, authenticated password change
- Session list (cap 50), revoke one, revoke all; `is_current` from JWT principal
- `Cache-Control: no-store` on sensitive auth/account-action responses
- `AccountSecurityService` HTTP-independent layer

### Flutter

- `SignupResult` / pending verification flow; no token storage on signup
- Verification, forgot/reset password, account security, change password, session management screens
- Focused controllers; Security entry on customer/cleaner/admin homes
- Public/authenticated Dio split preserved

### Documentation

- `documentation/database/account-action-tokens-collection.md`
- `documentation/api/account-security-api.md`
- `documentation/architecture/account-recovery-verification-and-session-security.md`
- `documentation/decisions/ADR-018-account-recovery-verification-and-session-security.md`
- README/index and auth doc updates

## Exact Cursor Prompt

~~~~text
# TASK 020 — Email Verification, Password Recovery, Password Change, Session Management, and Authentication Hardening

Repository:

D:\freelance\erfankhan_cse489\final

TASK 019 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

The marketplace currently supports:

- signup/login;
- secure password hashing;
- access JWTs;
- rotating refresh sessions;
- refresh-token replay protection;
- persisted-role authorization;
- protected Flutter authentication;
- account/session revocation;
- customer/cleaner/admin marketplace workflows;
- booking/payment/chat/reviews/disputes;
- cleaner earnings/payout accounting.

TASK 020 must complete the major ACCOUNT SECURITY lifecycle.

Implement:

EMAIL VERIFICATION
- new accounts remain unverified until verified;
- signup does NOT create an authenticated session before verification;
- secure one-time verification tokens;
- resend verification;
- token expiry;
- token revocation/replacement;
- atomic token claiming;
- login blocked until email verified;
- development/test account-action delivery only;
- no fake production email claim.

PASSWORD RECOVERY
- generic forgot-password request;
- account-enumeration resistance;
- secure one-time reset tokens;
- password reset;
- password-policy reuse;
- token expiry;
- one-time consumption;
- session revocation after reset.

PASSWORD CHANGE
- authenticated change-password flow;
- current-password verification;
- reject reuse of current password;
- revoke sessions after successful change;
- Flutter reauthentication flow.

SESSION MANAGEMENT
- list own active sessions;
- identify current session;
- revoke another session;
- revoke current session;
- retain existing revoke-all behavior;
- never expose refresh-token hashes.

AUTH HARDENING
- central account-action token domain;
- hashed tokens at rest;
- secure randomness;
- no raw token logging;
- consistent authentication errors;
- generic recovery request responses;
- sensitive-response cache prevention where appropriate;
- regression of refresh/session security.

FLUTTER
- verification-pending screen;
- resend verification;
- development verification helper when backend explicitly provides it;
- forgot password;
- reset password;
- change password;
- session management screen;
- login handling for unverified account;
- auth/router/controller updates;
- comprehensive tests.

Do NOT implement:

- MFA;
- TOTP;
- SMS OTP;
- passkeys;
- OAuth/social login;
- Google login;
- Apple login;
- Facebook login;
- real email provider;
- SendGrid;
- Mailgun;
- AWS SES;
- SMTP credentials;
- email templates from an external service;
- push notifications;
- CAPTCHA;
- distributed rate limiting;
- deep-link native platform configuration;
- AI.

No AI features.

MFA and production email delivery remain explicit later/deferred work.

======================================================================
IMPORTANT PRODUCT HONESTY
======================================================================

TASK 020 must NOT claim:

- production email delivery is configured;
- verification email was actually delivered externally;
- password reset email was actually sent by a real provider.

Implement a provider-neutral account-action delivery boundary.

TASK 020 provides a DEVELOPMENT/TEST delivery mechanism only.

Production must NEVER silently use a development account-action provider.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct dependency

FLUTTER:
no new direct dependency

Reuse existing:

Backend:
- Dart Frog
- mongo_dart
- hashlib
- dart:convert
- dart:math
- existing password/auth/session architecture

Flutter:
- Dio
- Riverpod
- go_router
- flutter_secure_storage
- Dart SDK

Do NOT add:

mailer
firebase_auth
firebase_messaging
oauth packages
OTP packages
crypto package if existing hashlib functionality is sufficient
another router
another HTTP package
another state manager

If a genuinely unavoidable package is required:

STOP before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 019 checkpoint:

Backend:

dart analyze:
clean

dart test:
483 passed

Flutter:

flutter analyze:
clean

flutter test:
349 passed

Verify these exact baselines first.

Use Dart Frog route command:

dart pub global run dart_frog_cli:dart_frog list

Do NOT rely on:

dart_frog list

because the CLI is not directly available on PATH.

======================================================================
ACCOUNT ACTION TOKEN COLLECTION
======================================================================

Create:

account_action_tokens

Use one shared secure token mechanism for:

email verification
password reset

rather than implementing two unrelated cryptographic/token systems.

Document:

{
  "_id": ObjectId,

  "user_id": ObjectId,

  "purpose": String,

  "token_hash": String,

  "expires_at": DateTime,

  "claimed_at": DateTime?,
  "revoked_at": DateTime?,

  "created_at": DateTime
}

All timestamps:

UTC.

Do NOT persist raw token.

Do NOT persist:

password
JWT
refresh token
email password
SMTP credentials
Mongo URI
secret keys.

======================================================================
ACCOUNT ACTION PURPOSE
======================================================================

Create enum:

AccountActionPurpose

Wire values:

email_verification
password_reset

Do not scatter raw strings.

======================================================================
ACCOUNT ACTION TOKEN GENERATION
======================================================================

Generate:

32 secure random bytes

using:

Random.secure()

Encode:

base64url
without padding

Persist only:

SHA-256 lowercase hexadecimal hash

of raw token.

Do NOT store raw token in Mongo.

Do NOT log raw token.

Do NOT include token in audit/notification data.

======================================================================
TOKEN EXPIRY
======================================================================

Email verification token:

24 hours

Password reset token:

30 minutes

Use centralized constants/policy.

Tests must inject/override clock where needed.

Do not scatter DateTime.now() throughout services.

======================================================================
TOKEN CLAIMING
======================================================================

Consuming a token must use a conditional atomic repository operation.

Match:

token_hash
purpose
claimed_at == null
revoked_at == null
expires_at > now

Then atomically set:

claimed_at = now

Return claimed token/document.

This prevents two consumers from successfully using the same token.

Do NOT:

find token
then unconditionally mark used.

======================================================================
TOKEN CLAIM FAILURE
======================================================================

For:

unknown
expired
already claimed
revoked

return the same safe application error:

invalid_or_expired_account_action_token

Do not tell attacker which condition applied.

======================================================================
TOKEN REPLACEMENT
======================================================================

When issuing a new token for:

same user
same purpose

revoke existing unclaimed/unrevoked live tokens first.

Then create the new token.

This means newest action request supersedes previous links.

Do not physically delete token history merely to replace it.

======================================================================
TOKEN TTL INDEX
======================================================================

Add TTL on:

expires_at

expireAfterSeconds:
0

TTL deletion is cleanup only.

Correctness must still check:

expires_at > now

because Mongo TTL cleanup is asynchronous.

======================================================================
TOKEN CROSS-DOCUMENT CONSISTENCY
======================================================================

Token claim and user/password mutation span multiple documents.

There is no existing general Mongo multi-document transaction architecture.

TASK 020 policy:

1. atomically claim token;
2. perform intended user/password mutation;
3. perform session revocation if required.

If the user mutation unexpectedly fails after token claim:

the token remains consumed.

User may request a new action token.

Do NOT attempt unsafe rollback of the token claim.

Document this limitation clearly.

======================================================================
ACCOUNT ACTION TOKEN REPOSITORY
======================================================================

Create narrow:

AccountActionTokenRepository

Responsibilities:

revokeLiveForUserAndPurpose
create
claimByRawTokenHash
find as needed for tests

No arbitrary updates.

No raw token accepted except at service boundary where it is immediately hashed.

======================================================================
EMAIL VERIFIED STATE
======================================================================

Existing:

users.email_verified

remains authoritative.

Signup creates:

email_verified = false

Email verification sets:

email_verified = true

Do not create a second profile verification flag.

======================================================================
SIGNUP SECURITY CHANGE
======================================================================

IMPORTANT BEHAVIOR CHANGE.

Current signup flow must change.

Before TASK 020:

signup may create authenticated access/refresh session.

After TASK 020:

successful signup:

1. creates user;
2. user.email_verified == false;
3. issues email-verification account-action token;
4. invokes account-action delivery provider;
5. DOES NOT create UserSession;
6. DOES NOT return access token;
7. DOES NOT return refresh token.

Return:

201

Safe shape conceptually:

{
  "success": true,
  "data": {
    "user": {
      ...
      "email_verified": false
    },
    "verification_required": true,
    "development_action": ...
  }
}

`development_action`:

ONLY appears when backend development/test delivery provider explicitly
produces it.

Production response must never contain a verification token.

======================================================================
SIGNUP DELIVERY FAILURE
======================================================================

User persistence and account-action delivery are cross-system operations.

If user was successfully created but account-action delivery is unavailable:

do NOT delete the user.

Return safe indication that account exists but verification delivery is
currently unavailable.

Suggested:

503
account_action_delivery_unavailable

The user may later use:

resend verification.

Do not attempt to roll back account creation.

Document this.

======================================================================
LOGIN EMAIL VERIFICATION
======================================================================

Login behavior:

1. normalize email;
2. perform existing user lookup;
3. preserve existing dummy-password verification for unknown users;
4. verify supplied password;
5. check account status;
6. require email_verified == true;
7. only then create session/tokens.

Correct-password unverified account:

403

code:

email_not_verified

Do not issue:

access token
refresh token
session

for unverified account.

Unknown email / wrong password must remain indistinguishable:

401
invalid_credentials

Do NOT check verification before password verification because that could leak
account existence.

======================================================================
EXISTING ACCOUNTS / TEST FIXTURES
======================================================================

Do NOT silently migrate live account documents.

TASK 020 must not update live users.

Automated tests must explicitly mark pre-existing fake accounts:

email_verified = true

when testing normal authenticated flows.

Existing production/user migration policy is deferred because this project has
not been creating live user fixtures during prior tasks.

Document that behavior.

======================================================================
ACCOUNT ACTION DELIVERY BOUNDARY
======================================================================

Create provider-neutral interface:

AccountActionDeliveryProvider

Responsibilities conceptually:

deliverEmailVerification(...)
deliverPasswordReset(...)

Provider input may include:

recipient email
raw action token
expiry

but implementation must not persist/log the raw token.

Do not expose raw provider response into application services.

======================================================================
DEVELOPMENT ACCOUNT ACTION PROVIDER
======================================================================

Create:

DevelopmentAccountActionDeliveryProvider

Allowed only when:

APP_ENV == development
or
APP_ENV == test

Production:

must not use it.

No automatic production fallback.

======================================================================
DEVELOPMENT ACTION RESULT
======================================================================

For local portfolio development:

development/test delivery provider may return a safe development result:

{
  "purpose": "...",
  "token": "<raw one-time token>"
}

or:

{
  "action_url": "...token..."
}

This is permitted ONLY in development/test.

Production API responses:

must NEVER contain raw account-action token.

Do not log the development token.

Prefer returning:

development_action

through service result only when environment explicitly allows it.

======================================================================
PRODUCTION DELIVERY POLICY
======================================================================

TASK 020 does NOT integrate a production email provider.

When production account-action delivery is requested:

return:

503
account_action_delivery_unavailable

Do not silently return raw token.

Do not pretend email was sent.

The rest of backend must continue to boot and serve unrelated features.

======================================================================
EMAIL VERIFICATION REQUEST
======================================================================

Add:

POST /api/v1/auth/email-verification/request

Body:

{
  "email": "..."
}

Behavior must resist account enumeration.

For:

unknown email
already verified email

return the SAME generic success response as a normal accepted request:

200

Conceptually:

{
  "success": true,
  "data": {
    "message": "If verification is required for that account, instructions are available."
  }
}

Do not reveal:

account_not_found
already_verified

through production response.

======================================================================
DEVELOPMENT VERIFICATION RESPONSE
======================================================================

In development/test ONLY:

if an unverified known account generated an action:

the response MAY additionally contain:

development_action

for local testing.

This development-only behavior is explicitly non-production.

Tests must prove production does not expose it.

======================================================================
EMAIL VERIFICATION CONSUME
======================================================================

Add:

POST /api/v1/auth/email-verification/verify

Body:

{
  "token": "..."
}

Flow:

1. hash token;
2. atomically claim email_verification token;
3. load user;
4. set email_verified true conditionally/idempotently;
5. return safe success.

No session is created automatically.

User signs in normally after verification.

Success:

200

{
  "success": true,
  "data": {
    "email_verified": true
  }
}

======================================================================
VERIFICATION IDEMPOTENCY POLICY
======================================================================

A claimed token used again:

invalid_or_expired_account_action_token

Do not make raw token infinitely replayable.

If user is already verified using another token/action:

verification request remains generic.

======================================================================
PASSWORD RESET REQUEST
======================================================================

Add:

POST /api/v1/auth/password-reset/request

Body:

{
  "email": "..."
}

Account-enumeration resistance mandatory.

Unknown user:

generic 200.

Known user:

generic 200.

Do not return:

user_not_found.

If known account:

issue password_reset token
+
invoke delivery provider.

Do NOT require email_verified == true to request reset.

Reason:

a user may need to recover the account before completing verification.

======================================================================
PASSWORD RESET REQUEST ACCOUNT STATUS
======================================================================

For suspended/deactivated account:

still return generic response.

Do NOT create password-reset token for deactivated account.

For suspended account:

token issuance may be allowed, but successful reset does NOT reactivate account.

Preferred:

allow suspended account reset.

Account status remains suspended.

Document exact policy.

======================================================================
PASSWORD RESET CONSUME
======================================================================

Add:

POST /api/v1/auth/password-reset/confirm

Body:

{
  "token": "...",
  "new_password": "..."
}

Flow:

1. validate new password using EXISTING PasswordPolicy;
2. hash token;
3. atomically claim password_reset token;
4. load user;
5. reject deactivated user safely;
6. hash new password with existing PasswordHasher;
7. update password_hash;
8. revoke ALL user sessions;
9. return success.

Do NOT automatically log user in.

Success response indicates:

reauthentication_required = true

======================================================================
PASSWORD RESET PASSWORD REUSE
======================================================================

If new password verifies against current password hash:

reject:

409
password_reuse_not_allowed

Important ordering:

avoid consuming a valid reset token merely for a trivially rejected reused
password when practical.

Suggested:

before claim:
- locate token safely enough to resolve user without marking it used;
- verify new password is not current;
- then atomically claim.

However correctness against replay must still rely on atomic claim.

If architecture makes this unsafe/overcomplicated:

claim first, then check reuse and document that rejected reuse consumes the
token.

Prefer preserving token on client validation errors when possible.

Do not weaken one-time token concurrency to accomplish this.

======================================================================
PASSWORD RESET SESSION SECURITY
======================================================================

After successful password change:

revoke all refresh sessions.

Existing access JWTs may still exist briefly.

Persisted authorization remains based on active account.

Refresh attempts from revoked sessions fail.

Flutter should clear any existing local token pair if the reset occurs while
the same user is signed in.

======================================================================
AUTHENTICATED PASSWORD CHANGE
======================================================================

Add:

POST /api/v1/account/password/change

Protected account route.

Body:

{
  "current_password": "...",
  "new_password": "..."
}

Requirements:

- authenticated active user;
- resolve current persisted user;
- verify current password;
- validate new password with existing PasswordPolicy;
- new password must NOT equal current password;
- hash using existing PasswordHasher;
- conditionally update password;
- revoke ALL sessions;
- return:
  reauthentication_required = true.

Do not return new tokens.

Flutter clears secure token pair and returns to login after success.

======================================================================
PASSWORD CHANGE FAILURE
======================================================================

Wrong current password:

400

code:

invalid_current_password

Do not expose hash details.

New same password:

409
password_reuse_not_allowed

Invalid new password:

existing password validation error behavior.

======================================================================
PASSWORD HASH REHASH BEHAVIOR
======================================================================

Existing login-time hash rehash behavior must remain.

Password reset/change always creates a fresh current-policy hash.

Do not create separate password algorithms.

======================================================================
SESSION MANAGEMENT API
======================================================================

Existing:

DELETE /api/v1/account/sessions

continues to revoke all user sessions.

Add:

GET /api/v1/account/sessions

DELETE /api/v1/account/sessions/[sessionId]

Protected active user.

======================================================================
SESSION LIST PRIVACY
======================================================================

Return safe session metadata only:

id
created_at
expires_at
last_rotated_at
is_current

Optional:

revoked status only if listing historical sessions is deliberately chosen.

Preferred:

list ACTIVE/non-revoked sessions only.

Do NOT return:

refresh_token_hash
used_refresh_token_hashes
raw refresh token
access token
JWT id
password data.

======================================================================
CURRENT SESSION DETECTION
======================================================================

Existing verified access JWT principal already contains:

sessionId

Use that to compute:

is_current

Do not trust client-provided current session id.

======================================================================
SESSION LIST ORDER
======================================================================

Sort:

created_at descending

Maximum:

50 active sessions

A normal account should have far fewer.

No pagination required for TASK 020.

Document the cap.

======================================================================
REVOKE ONE SESSION
======================================================================

DELETE:

/api/v1/account/sessions/[sessionId]

Selector/authorization:

session _id
AND
user_id == authenticated user

Unknown/foreign:

404
session_not_found

Do not reveal foreign session existence.

If already revoked:

idempotent 200 is acceptable.

If revoking current session:

response:

current_session_revoked = true

Flutter then clears local tokens and routes to login.

If revoking another session:

current login remains.

======================================================================
AUTH SESSION SERVICE EXTENSIONS
======================================================================

Extend existing:

AuthSessionService

narrowly.

Responsibilities may add:

listActiveForUser
revokeOwnedSession

Do not expose refresh-token fields to HTTP.

Do not rewrite refresh rotation.

Do not weaken reuse detection.

======================================================================
PASSWORD RESET TOKEN VS SESSION TOKEN
======================================================================

Account-action tokens and refresh tokens are completely separate security
domains.

Do NOT:

reuse refresh-token hashes
store password-reset token in user_sessions
encode password reset as JWT
encode verification as access JWT.

Account-action tokens are opaque random one-time tokens.

======================================================================
AUTH RESPONSE CACHE CONTROL
======================================================================

Ensure sensitive authentication/account-action endpoints return:

Cache-Control: no-store

and where reasonable:

Pragma: no-cache

at least for responses that may contain:

access tokens
refresh tokens
development account-action tokens.

Do not add browser-specific complexity beyond safe headers.

Existing API functionality must remain.

======================================================================
AUTH ERROR CONSISTENCY
======================================================================

Add safe codes:

email_not_verified
invalid_or_expired_account_action_token
account_action_delivery_unavailable
invalid_current_password
password_reuse_not_allowed
session_not_found

Reuse existing:

invalid_credentials
account_unavailable
invalid_request
password validation codes

Do not expose:

token hash
user existence in recovery requests
Mongo errors
stack traces.

======================================================================
DATABASE INDEXES
======================================================================

ACCOUNT_ACTION_TOKENS

1.

account_action_tokens_token_hash_unique

token_hash: 1

unique:
true

2.

account_action_tokens_user_purpose_created

user_id: 1
purpose: 1
created_at: -1

3.

account_action_tokens_expires_ttl

expires_at: 1

expireAfterSeconds:
0

USER_SESSIONS

Evaluate existing indexes.

Only add an additional user/session listing index if existing:

user_id

index does not adequately support:

user_id + revoked_at + created_at

query.

Possible:

user_sessions_user_revoked_created

user_id: 1
revoked_at: 1
created_at: -1

Create only if query-purpose justified.

Do NOT blindly add redundant session index.

======================================================================
COLLECTION NAMES
======================================================================

Extend central collection constants with:

account_action_tokens

Do not scatter collection name strings.

======================================================================
LIVE DATABASE POLICY
======================================================================

TASK 020 may live-mutate Atlas ONLY via:

controlled index ensure.

Do NOT live:

create account-action token
verify user
reset password
change password
revoke real session
create fake user
login/signup

against real Atlas.

Automated tests:

fakes/in-memory seams only.

Do not dump:

users
sessions
security tokens.

======================================================================
AUTHENTICATION SERVICE REFACTOR
======================================================================

Update existing AuthenticationService carefully.

Signup:

- no session before verification.

Login:

- preserve timing hardening;
- password first;
- verification check after valid password;
- no session for unverified account.

Refresh:

existing behavior unchanged.

Logout:

existing behavior unchanged.

Do NOT split auth into duplicated password/session implementations.

======================================================================
ACCOUNT SECURITY SERVICE
======================================================================

Create HTTP-independent:

AccountSecurityService

Responsibilities conceptually:

requestEmailVerification
verifyEmail
requestPasswordReset
confirmPasswordReset
changePassword
listSessions
revokeSession

You may separate public recovery and authenticated account security into two
services if that keeps dependencies cleaner.

Do not put Mongo operations directly in route handlers.

======================================================================
ACCOUNT ACTION SERVICE
======================================================================

Prefer a focused internal:

AccountActionTokenService

Responsibilities:

issue
hash
replace
claim

It composes:

AccountActionTokenRepository
clock
secure token generation

Delivery belongs to higher-level recovery/verification service.

Do not mix email/provider concerns into token repository.

======================================================================
BACKEND TESTS — ACCOUNT ACTION TOKEN
======================================================================

Test:

32 secure-byte token contract through injectable generator/test seam
base64url unpadded format
SHA-256 lowercase hash
raw token not persisted
verification 24h expiry
reset 30m expiry
revoke prior live token
claim once
second claim fails
expired fails
revoked fails
wrong purpose fails
TTL spec
unique token index.

No Atlas.

======================================================================
BACKEND TESTS — SIGNUP / VERIFICATION
======================================================================

Test:

signup creates user unverified
signup does NOT create session
signup does NOT return access token
signup does NOT return refresh token
verification action issued
dev/test response may contain development action
production response never contains token
delivery unavailable behavior
duplicate email unchanged

login:
unknown/wrong password still same 401
correct password + unverified → 403 email_not_verified
no session created
verified account login works normally

verify:
valid token
sets email_verified true
claimed once
expired/revoked invalid
unknown token same error
does not automatically issue auth session

resend:
unknown generic 200
verified generic 200
unverified generic 200
replacement revokes old token
production no raw action token exposure.

======================================================================
BACKEND TESTS — PASSWORD RESET REQUEST
======================================================================

Test:

unknown email generic response
known email same generic production response
development action only development/test
production token never exposed
previous reset token revoked
deactivated account does not get usable reset action
suspended policy works as documented
delivery provider unavailable safely
no account enumeration through error code/body.

======================================================================
BACKEND TESTS — PASSWORD RESET CONFIRM
======================================================================

Test:

valid reset
password policy
fresh password hash
same password rejected
expired token
revoked token
used token
wrong-purpose token
all sessions revoked
user not auto-logged in
suspended remains suspended
deactivated blocked
raw token not persisted/logged.

======================================================================
BACKEND TESTS — PASSWORD CHANGE
======================================================================

Test:

authenticated user
correct current password
wrong current password
new policy validation
same password rejected
fresh hash
all sessions revoked
reauthentication required
customer allowed
cleaner allowed
admin allowed
inactive account blocked by existing persisted authorization.

======================================================================
BACKEND TESTS — SESSION MANAGEMENT
======================================================================

Test:

list own sessions
maximum cap
sort newest first
current session flag from authenticated principal
no refresh hash fields
revoke other own session
current remains authenticated
revoke current session returns flag
foreign session 404
unknown 404
already-revoked idempotent policy
revoke-all regression
refresh replay security unchanged.

======================================================================
BACKEND TESTS — CACHE / SECURITY HEADERS
======================================================================

Test sensitive auth responses as appropriate:

login token response:
Cache-Control no-store

refresh:
no-store

development account-action response:
no-store

password reset confirmation:
no-store if policy applies

Do not over-test unrelated GET resources.

======================================================================
BACKEND REGRESSION
======================================================================

All existing:

authentication
refresh rotation
JWT verification
persisted role authorization
profiles
services
booking
payment
chat
reviews
disputes
audit
earnings
payout

tests must remain green.

Important:

existing fake users used by feature tests must explicitly be:

email_verified = true

when authenticated behavior is expected.

Do NOT weaken verification requirement merely to make old tests pass.

======================================================================
FLUTTER AUTH MODEL CHANGES
======================================================================

Update signup result model.

Signup no longer assumes:

TokenPair

is returned.

Create clear result such as:

SignupPendingVerification

with:

safe user
verificationRequired
developmentAction?

Do not shoehorn into authenticated session model.

======================================================================
FLUTTER ACCOUNT ACTION DEVELOPMENT MODEL
======================================================================

Create typed:

DevelopmentAccountAction

Fields:

purpose
token

or actionUrl if backend chooses that shape.

Only exists when backend supplies it.

Do not persist token to secure storage.

Keep it in transient screen/controller state.

======================================================================
FLUTTER AUTH API
======================================================================

Extend existing AuthApi with:

requestEmailVerification
verifyEmail
requestPasswordReset
confirmPasswordReset

Update signup parsing.

Reuse existing plain Dio for PUBLIC account-action endpoints.

Do not attach Bearer token unnecessarily.

Change-password/session endpoints use authenticated Dio.

======================================================================
FLUTTER SIGNUP FLOW
======================================================================

After successful signup:

do NOT navigate authenticated home.

Navigate:

/verify-email-pending

Pass/retain safe email and optional transient development action.

Show:

"Verify your email before signing in."

Production:

"Check your email for the verification instructions."

Do not claim email was delivered if backend returned delivery-unavailable error.

======================================================================
VERIFICATION PENDING SCREEN
======================================================================

Route:

/verify-email-pending

Screen:

email display
Resend Verification
Back to Login

If backend development action exists:

show clearly labeled:

Development Verification

button:

Verify Development Account

This button consumes the returned development token.

Do NOT display development token as a production-looking email.

After successful verification:

show success
navigate login.

======================================================================
LOGIN EMAIL-NOT-VERIFIED UX
======================================================================

If login returns:

email_not_verified

show safe message:

"Verify your email before signing in."

Offer:

Resend Verification

Do not change this error into:

invalid_credentials

in UI after the server correctly authenticated password.

No session should be stored.

======================================================================
FORGOT PASSWORD SCREEN
======================================================================

Add route:

/forgot-password

Login screen:

Forgot Password?

Screen fields:

email

Submit:

Request Reset

Always show generic success-style message when request accepted:

"If an eligible account exists, password reset instructions are available."

Do not expose account existence.

If production delivery unavailable:

show honest safe error:

"Password reset delivery is currently unavailable."

======================================================================
DEVELOPMENT PASSWORD RESET FLOW
======================================================================

If backend provides:

development_action

show clearly:

Development Password Reset

Continue to:

/reset-password

using transient token.

Do not persist token.

Do not log token.

======================================================================
RESET PASSWORD SCREEN
======================================================================

Route:

/reset-password

Accept token from:

transient navigation/query state

and optionally manual token field only if needed for development.

Fields:

New Password
Confirm New Password

Use existing client password validation UX.

Backend remains authoritative.

After successful reset:

clear local auth storage if any
navigate login
show:

"Password reset. Sign in again."

======================================================================
ACCOUNT SECURITY SCREEN
======================================================================

Add authenticated route:

/account/security

Accessible to:

customer
cleaner
admin

Create:

AccountSecurityScreen

Actions:

Change Password
Manage Sessions

Optional display:

Email verified

Do not expose security internals.

======================================================================
CHANGE PASSWORD SCREEN
======================================================================

Route:

/account/security/change-password

Fields:

Current Password
New Password
Confirm New Password

On success:

backend revokes all sessions

Flutter:

clear secure token pair
invalidate auth state
navigate login

Show:

"Password changed. Sign in again."

No auto-login.

======================================================================
SESSION MANAGEMENT SCREEN
======================================================================

Route:

/account/security/sessions

Create:

SessionManagementScreen

Show active sessions:

Current Session
created time
expiry
last rotated time

For non-current session:

Revoke

For current session:

Log Out This Session

Also retain:

Log Out All Devices

with confirmation.

Do NOT display:

refresh-token hash
JWT
token id
security secret.

======================================================================
SESSION REVOKE UX
======================================================================

Revoke OTHER session:

remove/update it from list.

Current session stays authenticated.

Revoke CURRENT:

clear secure token storage
route login.

Revoke all:

existing logout-all flow
clear local token
route login.

======================================================================
ROLE HOME / PROFILE INTEGRATION
======================================================================

Add:

Security

entry from customer, cleaner, and admin account/profile/settings experience.

Do not duplicate three different security implementations.

Shared screen/route is preferred.

======================================================================
AUTH CONTROLLER CHANGES
======================================================================

Keep AuthController responsible only for authentication/session state.

Update:

signup no longer authenticates user.

Verification does not authenticate user.

Password reset does not authenticate user.

Change password clears auth state after successful server operation.

Do not add:

password-form state
verification-form state
session-list state

directly into AuthController.

Use focused controllers/providers.

======================================================================
FLUTTER CONTROLLERS
======================================================================

Create focused state/controllers such as:

EmailVerificationController

PasswordRecoveryController

AccountSecurityController

SessionManagementController

or another clean separation.

Avoid one giant security controller if responsibilities become unclear.

======================================================================
FLUTTER ROUTER
======================================================================

Public allowed while unauthenticated:

/login
/signup
/verify-email-pending
/forgot-password
/reset-password

Authenticated users attempting those public auth-action screens:

may redirect home except when an explicit change/reset flow needs otherwise.

Protected:

/account/security
/account/security/change-password
/account/security/sessions

All active roles allowed.

Role-specific homes remain unchanged.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Map safely:

email_not_verified
invalid_or_expired_account_action_token
account_action_delivery_unavailable
invalid_current_password
password_reuse_not_allowed
session_not_found

Never display:

DioException.toString()
token hash
raw server exception
Mongo error
stack trace.

======================================================================
FLUTTER TESTS — SIGNUP / VERIFICATION
======================================================================

API/models:

signup without TokenPair
verification-required parsing
development action parsing
production-like response without development action
request verification
verify token

Controller:

signup pending verification
resend
verify
safe errors

Widgets:

signup → verification pending
no authenticated home after signup
resend
back login
development verify button only when available
verification success → login
login email_not_verified path.

======================================================================
FLUTTER TESTS — PASSWORD RECOVERY
======================================================================

API:

request reset
generic response
development action
confirm reset
safe errors

Controller:

request
development transition
confirm
loading
safe failures

Widgets:

Forgot Password link
request form
generic success
delivery unavailable
development reset button only when available
reset password validation
confirmation mismatch
success → login.

======================================================================
FLUTTER TESTS — CHANGE PASSWORD
======================================================================

API/controller:

authenticated request
wrong current password
reuse error
success
session/auth clear behavior

Widget:

current password
new password
confirm
loading
success → login.

======================================================================
FLUTTER TESTS — SESSION MANAGEMENT
======================================================================

Models/API:

safe session parse
list
revoke one
revoke all

Controller:

load
revoke other
revoke current
revoke all
safe error

Widgets:

current label
session metadata
revoke other
current logout
logout all confirmation
no token/hash fields.

======================================================================
FLUTTER AUTH/ROUTER REGRESSION TESTS
======================================================================

Verify:

signup no longer authenticates.

unverified login:
no TokenPair stored.

verified login:
normal authenticated routing.

startup token restore unchanged.

refresh:
unchanged.

session expiry:
login.

password change:
login.

current-session revoke:
login.

other-session revoke:
stay authenticated.

All customer/cleaner/admin routes from TASK 012–019 remain green.

======================================================================
SECURITY AUDIT
======================================================================

EMAIL VERIFICATION

Confirm:

- raw token secure-random;
- raw token not persisted;
- SHA-256 hash only;
- one-time atomic claim;
- 24h expiry;
- replacement revokes older token;
- login password verified before email verification check;
- no session before verified;
- production response never exposes verification token.

PASSWORD RESET

Confirm:

- generic request response;
- no user enumeration;
- 30m token expiry;
- opaque random token, not JWT;
- hash at rest;
- one-time claim;
- new password uses existing Argon2id policy;
- all sessions revoked;
- no auto-login.

PASSWORD CHANGE

Confirm:

- requires current password;
- rejects reuse;
- fresh hash;
- all sessions revoked;
- client reauth required.

SESSIONS

Confirm:

- persisted ownership;
- foreign session hidden 404;
- refresh hashes never serialized;
- current session derived from verified principal;
- refresh rotation/replay behavior unchanged.

DELIVERY

Confirm:

- development/test provider only;
- no production fallback;
- no raw token logging;
- no production email claim.

FLUTTER

Confirm:

- no Mongo URI;
- no ACCESS_TOKEN_SECRET;
- no sandbox webhook secrets;
- no account-action token persisted in secure auth storage;
- authenticated Dio reused for protected account routes;
- plain Dio used appropriately for public recovery routes.

GLOBAL

Confirm:

backend/.env ignored
no secrets committed
no password/token logs
existing financial/security regressions green.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/account-action-tokens-collection.md

Document:

fields
purpose
hashed token
expiry
atomic claim
replacement
TTL cleanup
cross-document limitation
privacy.

======================================================================
DOCUMENTATION — API
======================================================================

Create:

documentation/api/account-security-api.md

Document:

signup behavior change
email verification request/consume
password reset request/confirm
change password
session list/revoke
revoke all
errors
cache headers
development action behavior
production delivery limitation.

Use fake examples.

Never include a real token.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/account-recovery-verification-and-session-security.md

Document flows:

SIGNUP

signup
→ unverified user
→ account action token
→ delivery provider
→ verification
→ login
→ session

RESET

generic request
→ account action token
→ delivery
→ token claim
→ password update
→ session revocation
→ login

PASSWORD CHANGE

authenticated user
→ current password
→ new password
→ session revoke all
→ reauthentication

SESSION MANAGEMENT

verified JWT principal
→ persisted user
→ owned sessions
→ targeted revocation

Explain:

- why action token is opaque rather than JWT;
- why raw token is not stored;
- why signup does not authenticate before email verification;
- why recovery requests are generic;
- why delivery is provider-neutral;
- why dev delivery is forbidden in production;
- cross-document token/user consistency limitation.

======================================================================
ADR-018
======================================================================

Create:

documentation/decisions/ADR-018-account-recovery-verification-and-session-security.md

Required:

# ADR-018 — Account Recovery, Email Verification, and Session Security

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must cover:

- email verification required before session issuance;
- signup does not authenticate;
- shared account_action_tokens collection;
- opaque CSPRNG tokens;
- SHA-256 hashes at rest;
- purpose enum;
- token replacement;
- atomic claiming;
- TTL cleanup;
- generic recovery request responses;
- existing PasswordPolicy/Argon2id reuse;
- password-reset session revocation;
- authenticated change-password reauthentication;
- safe own-session management;
- development/test-only delivery provider;
- no production token exposure;
- no real production email provider yet.

Alternatives:

### Automatically authenticate after signup
Rejected because unverified email would receive an authenticated marketplace
session.

### Encode verification/reset as JWT
Rejected because one-time revocation/claim semantics are clearer with opaque
stored token hashes.

### Store raw action tokens
Rejected.

### Reveal whether reset/verification email exists
Rejected due account enumeration.

### Keep sessions after password reset
Rejected because compromised refresh sessions must be invalidated.

### Change password without current password
Rejected for authenticated password-change flow.

### Automatically log in after password reset
Rejected to force explicit reauthentication.

### Use development delivery in production
Rejected.

### Integrate SMTP/provider now
Deferred because provider credentials/domain setup have not been selected.

Deferred:

production email provider
native deep links/app links
MFA
TOTP
passkeys
OAuth
CAPTCHA
distributed auth rate limiting
breached-password external service
security-event email alerts.

======================================================================
DOCUMENTATION INDEX UPDATES
======================================================================

Update as necessary:

documentation/README.md
documentation/api/README.md
documentation/database/README.md
documentation/architecture/README.md
documentation/decisions/README.md

documentation/architecture/backend-api-architecture.md
documentation/architecture/flutter-client-architecture.md

backend/README.md
project/README.md
README.md

Update authentication documentation that still claims signup immediately returns
tokens.

Do not leave contradictory old docs.

Do not claim:

production email
MFA
OAuth
passkeys

exist.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From root:

git rev-parse --show-toplevel
git branch --show-current
git status
git status --short
git log -10 --oneline

Expected:

root:
D:\freelance\erfankhan_cse489\final

branch:
main

working tree:
clean

latest commit:
TASK 019 checkpoint

Verify:

documentation/cursor/019_cleaner_earnings_payouts_and_reconciliation.md

Status:
SUCCESS

Verify:

backend/.env ignored.

If tree not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend:

dart pub get
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Expected:

483 passed
0 failed

If not:

STOP.

======================================================================
STEP 3 — FLUTTER BASELINE

From project:

flutter pub get
flutter analyze
flutter test

Expected:

349 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new direct dependency required.

If required:

STOP before adding.

======================================================================
STEP 5 — ACCOUNT ACTION TOKEN DOMAIN

Implement:

AccountActionPurpose
AccountActionToken
token service
repository
indexes
clock/random seams
tests.

======================================================================
STEP 6 — DELIVERY PROVIDER

Implement:

AccountActionDeliveryProvider
DevelopmentAccountActionDeliveryProvider
production unavailable behavior

without real external email.

Tests.

======================================================================
STEP 7 — SIGNUP / VERIFICATION

Refactor signup.

Implement:

verification request
verification consume
login verification enforcement.

Update tests comprehensively.

======================================================================
STEP 8 — PASSWORD RECOVERY

Implement:

request
confirm
password reuse rules
session revocation.

Tests.

======================================================================
STEP 9 — PASSWORD CHANGE

Implement protected change-password flow.

Tests.

======================================================================
STEP 10 — SESSION MANAGEMENT

Implement:

list active sessions
revoke one
current session detection

while preserving revoke-all/refresh rotation.

Tests.

======================================================================
STEP 11 — SECURITY RESPONSE HEADERS

Add/verify no-store behavior for sensitive auth/account-action responses.

Tests.

======================================================================
STEP 12 — BACKEND ROUTES

Implement all TASK 020 routes.

Thin handlers.

No direct Mongo logic in route handlers.

======================================================================
STEP 13 — BACKEND PRE-LIVE VERIFICATION

Run:

dart format .
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

All green.

Record exact test count/routes.

======================================================================
STEP 14 — LIVE INDEX ENSURE

Run controlled index tool.

Only index metadata mutation.

Verify TASK 020 token/session indexes.

Do not create live tokens/users/sessions.

======================================================================
STEP 15 — FLUTTER DATA / API

Update authentication models/API.

Implement verification/password recovery/account security/session APIs.

Reuse current Dio architecture.

======================================================================
STEP 16 — FLUTTER STATE

Implement focused controllers.

Update AuthController only where authentication-state behavior genuinely
changes.

======================================================================
STEP 17 — FLUTTER ROUTING

Add public recovery/verification routes and shared protected security routes.

Preserve role guards.

======================================================================
STEP 18 — FLUTTER UI

Implement:

VerificationPendingScreen
ForgotPasswordScreen
ResetPasswordScreen
AccountSecurityScreen
ChangePasswordScreen
SessionManagementScreen

Update:

SignupScreen
LoginScreen
role account/profile/home entry as needed.

======================================================================
STEP 19 — FLUTTER TESTS

Add comprehensive:

models
API
controllers
widgets
router
auth regressions.

Then:

dart format lib test
flutter analyze
flutter test

All green.

Record exact test count.

======================================================================
STEP 20 — ANDROID DEBUG BUILD

Run:

flutter build apk --debug

Must succeed.

Do not change release signing/network security unnecessarily.

======================================================================
STEP 21 — SAFE LIVE BACKEND VERIFICATION

Only call:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Expected 200.

Do NOT live call:

signup
login
verification
password reset
password change
session management

against Atlas.

======================================================================
STEP 22 — SECURITY AUDIT

Perform every TASK 020 security check.

Regression verify TASK 012–019 remains green.

======================================================================
STEP 23 — DOCUMENTATION

Create:

documentation/database/account-action-tokens-collection.md

documentation/api/account-security-api.md

documentation/architecture/account-recovery-verification-and-session-security.md

documentation/decisions/ADR-018-account-recovery-verification-and-session-security.md

Update all conflicting old auth documentation and README/index files.

======================================================================
STEP 24 — FINAL BACKEND VERIFICATION

Run:

dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Record exact count/routes.

======================================================================
STEP 25 — FINAL FLUTTER VERIFICATION

Run:

flutter analyze
flutter test
flutter build apk --debug

Record exact count.

======================================================================
STEP 26 — FINAL GIT / SECRET REVIEW

From root:

git status --short
git check-ignore -v backend/.env
git diff --check

Inspect:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm no:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET
raw account-action token in documentation
password
JWT
refresh token
token hash dumps
private user/session data
APK
build directory
SDK artifact
project/devtools_options.yaml
temporary prompt file
unrelated generated file

is tracked.

Development tokens may appear only as obviously fake literal fixtures in tests,
never runtime secret output copied into repository documentation.

Do NOT stage.

======================================================================
STEP 27 — TASK REPORT

Create:

documentation/cursor/020_account_recovery_verification_and_session_security.md

Use existing task report template.

The report MUST contain the COMPLETE EXACT TASK 020 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 019 checkpoint;
- backend/Flutter baseline counts;
- dependency audit;
- signup behavior change;
- email verification;
- login verification enforcement;
- account action token schema;
- token randomness/hash;
- token replacement;
- expiry;
- atomic claim;
- cross-document limitation;
- delivery provider;
- development-only action behavior;
- production unavailable behavior;
- password reset;
- account enumeration protection;
- password reuse;
- password change;
- session revocation;
- session list;
- revoke one;
- current session behavior;
- cache-control security;
- indexes/live ensure;
- backend routes;
- backend test count;
- Flutter APIs/controllers;
- verification UX;
- recovery UX;
- change password;
- session management;
- routing;
- Flutter test count;
- APK;
- safe live checks;
- security audit;
- live data safety;
- files;
- warnings;
- final Git state.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET
real raw account-action token
real token hashes
passwords
JWTs
refresh tokens
private user/session data.

======================================================================
STEP 28 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 020 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 020 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## Signup Verification Change

## Account Action Token Model

## Token Security

## Token Replacement and Expiry

## Account Action Delivery Boundary

## Development Delivery

## Production Delivery Behavior

## Email Verification

## Login Verification Enforcement

## Password Reset Request

## Account Enumeration Protection

## Password Reset Confirmation

## Password Reuse Protection

## Password Change

## Session Revocation

## Session Management

## Authentication Cache Controls

## MongoDB Indexes

## Backend Tests

## Backend Routes

## Flutter Signup and Verification Experience

## Flutter Login Experience

## Flutter Password Recovery Experience

## Flutter Password Change Experience

## Flutter Session Management Experience

## Flutter State

## Flutter Routing

## Flutter Tests

## Flutter Static Analysis

## Android Debug Build

## Live Backend Verification

## Live Data Safety

## Files Created

## Files Modified

## Files Deleted

## Documentation

## Security Verification

## Git Status

## Issues / Warnings

## Final Statement

State whether email verification + password recovery + authenticated password
change + secure one-time account-action tokens + session management +
authentication hardening are complete and ready for ChatGPT review.

Do NOT implement MFA.

Do NOT integrate a real email provider.

Do NOT implement OAuth.

Do NOT begin TASK 021.

Start TASK 020 now.
~~~~

## Git Status

TASK 020 changes remain **uncommitted** by design for ChatGPT review. No `git add`, `git commit`, or `git push` was performed for TASK 020C.

## Issues / Warnings

- Dart Frog CLI may still show PATH / non-TTY environment quirks depending on shell setup; routes remain listable when the CLI is available.
