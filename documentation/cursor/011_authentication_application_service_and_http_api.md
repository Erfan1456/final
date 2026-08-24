# Cursor Task 011 — Authentication Application Service and HTTP API

## Metadata

- Task ID: 011
- Task title: Authentication Application Service and HTTP API
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Compose existing user, password, access-token, and refresh-session primitives into an HTTP-independent `AuthenticationService` and four public Dart Frog routes: signup, login, refresh, and logout. Do not add Flutter auth, middleware for protected marketplace routes, `/me`, logout-all, password reset, email verification, OAuth, MFA, rate limiting, live Atlas user/session mutations, or a Git commit.

## Exact Cursor Prompt

``text
# TASK 011 — Authentication Application Service and HTTP API

You are working inside the existing Git repository:

D:\freelance\erfankhan_cse489\final

Current high-level layout:

final/
├── .git/
├── .gitignore
├── README.md
├── backend/                  ← Dart Frog backend
├── documentation/
└── project/                  ← Flutter client

TASK 010 established and checkpointed the access-token and refresh-session
security foundation.

The backend currently exposes only:

GET /
GET /api/v1/health
GET /api/v1/ready

Existing backend authentication primitives now include:

- UserAccount persistence;
- UserRepository / MongoUserRepository;
- unique normalized-email enforcement;
- UserRole;
- AccountStatus;
- PasswordPolicy;
- PasswordHasher / Argon2idPasswordHasher;
- AccessTokenService / JwtAccessTokenService;
- opaque refresh tokens;
- AuthSessionService;
- UserSessionRepository / MongoUserSessionRepository;
- rotating refresh-token sessions;
- replay detection;
- session revocation.

TASK 011 will compose those existing primitives into the first real
authentication application behavior and HTTP API.

======================================================================
APPROVED AUTHENTICATION ENDPOINTS
======================================================================

Add exactly:

POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

Do NOT add any other authentication endpoint in TASK 011.

There is still no:

- password reset;
- email verification endpoint;
- OAuth;
- MFA;
- logout-all endpoint;
- /me endpoint;
- auth middleware;
- protected marketplace route.

======================================================================
PUBLIC SIGNUP ROLES
======================================================================

Public signup may create only:

customer
cleaner

Public signup MUST NOT create:

admin

If role is:

admin
unknown
missing

the request must fail validation.

Admin provisioning will be designed separately.

Cleaner approval is NOT handled here.

A cleaner account may be created with:

role = cleaner

but cleaner onboarding/verification/approval remains a later feature.

======================================================================
NEW ACCOUNT DEFAULTS
======================================================================

Public signup creates:

account_status = active
email_verified = false

This is intentional for the current implementation.

Email-verification delivery does not exist yet.

Do NOT invent an email service.

Do NOT block initial login solely because email_verified is false yet.

Document this as a deferred verification policy.

======================================================================
AUTHENTICATION RESPONSE MODEL
======================================================================

Successful signup/login should expose a safe JSON structure conceptually like:

{
  "success": true,
  "data": {
    "user": {
      ...
    },
    "tokens": {
      "access_token": "...",
      "refresh_token": "...",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}

The user object MUST come from the existing safe public UserAccount
serialization or an equivalently safe DTO.

It MUST NOT expose:

password_hash
passwordHash
email_normalized
MongoDB internals
refresh-token hashes
used refresh-token hashes

Refresh success may return:

{
  "success": true,
  "data": {
    "tokens": {
      ...
    }
  }
}

It does not need to return the full user unless implementation needs justify
that later.

Logout should return a simple successful JSON response.

======================================================================
REQUEST SHAPES
======================================================================

Signup:

POST /api/v1/auth/signup

JSON:

{
  "email": "person@example.com",
  "password": "...",
  "role": "customer"
}

Allowed role values:

customer
cleaner

Login:

POST /api/v1/auth/login

JSON:

{
  "email": "person@example.com",
  "password": "..."
}

Refresh:

POST /api/v1/auth/refresh

JSON:

{
  "refresh_token": "..."
}

Logout:

POST /api/v1/auth/logout

JSON:

{
  "refresh_token": "..."
}

Use snake_case for HTTP JSON fields.

======================================================================
HTTP STATUS BASELINE
======================================================================

Use consistent status semantics.

Signup success:
201

Login success:
200

Refresh success:
200

Logout success:
200

Malformed JSON / invalid input:
400

Duplicate signup email:
409

Invalid login credentials:
401

Invalid/expired/replayed refresh token:
401

Inactive account after correct authentication:
403

Auth service unavailable because server authentication configuration is
missing/invalid:
503

Unsupported HTTP method:
405

Do not return raw Dart, MongoDB, JWT, or crypto errors.

======================================================================
ERROR ENVELOPE
======================================================================

Use the existing JSON response/error convention.

Conceptual shape:

{
  "success": false,
  "error": {
    "code": "invalid_credentials",
    "message": "Invalid email or password."
  }
}

Keep error codes stable and machine-readable.

Do not return:

stack traces
exception class names
MongoDB error codes
JWT parser errors
Argon2 parser errors
database host information

======================================================================
LOGIN USER-ENUMERATION POLICY
======================================================================

Login failures for:

unknown email
wrong password

must both return the SAME external response:

HTTP 401

code:
invalid_credentials

message:
Invalid email or password.

Do not expose whether the email exists.

======================================================================
LOGIN TIMING HARDENING
======================================================================

A nonexistent-user login must not skip password verification entirely.

Use a process-scoped dummy Argon2 password hash.

When a login email does not resolve to a UserAccount:

perform one PasswordHasher.verify(...) call against the dummy encoded Argon2
hash before returning invalid_credentials.

The dummy hash:

- is not a real credential;
- must use the existing approved Argon2id hasher;
- does not need to be secret;
- should be created once for the process/service composition rather than
  hashing a new dummy password on every login request.

Do NOT sleep for arbitrary timing delays.

Do NOT attempt perfect constant-time network authentication.

The goal is to avoid the large obvious timing difference caused by skipping
Argon2 entirely for nonexistent users.

Tests must verify that the missing-user path performs a password verification.

======================================================================
PASSWORD POLICY USE
======================================================================

Signup:

MUST enforce the existing PasswordPolicy.

Login:

MUST NOT reject a password merely because it is below the current signup
minimum before attempting authentication.

Reason:

future password policies can evolve and existing accounts may contain older
valid password hashes.

Login should still enforce a conservative maximum supported input size to
avoid unreasonable input.

Do not transform login passwords.

For both signup and login:

Do NOT:

trim password
lowercase password
uppercase password
Unicode-normalize password
collapse whitespace

Passwords remain opaque.

======================================================================
EMAIL INPUT POLICY
======================================================================

TASK 008's normalization remains authoritative for identity lookup:

trim + lowercase

For signup/login HTTP input:

- require a String;
- trim leading/trailing whitespace from the EMAIL only;
- reject empty email;
- impose a reasonable maximum such as 254 characters;
- reject ASCII control characters / whitespace embedded inside the address;
- require exactly one meaningful @ separator;
- require non-empty local and domain portions.

Do NOT implement a giant RFC-5322 regex.

Do NOT perform Gmail-specific normalization.

Do NOT remove plus addressing.

Do NOT remove dots.

Do NOT lowercase the stored display email merely because normalization exists.

Pass the trimmed email to persistence.

The existing repository remains responsible for normalized identity lookup.

======================================================================
ACCOUNT STATUS LOGIN POLICY
======================================================================

After the submitted password has been successfully verified:

active
→ login allowed

suspended
→ reject with HTTP 403 account_unavailable

deactivated
→ reject with HTTP 403 account_unavailable

Do not expose separate external messages for suspended vs deactivated in
TASK 011.

Use a generic safe error such as:

{
  "success": false,
  "error": {
    "code": "account_unavailable",
    "message": "This account is currently unavailable."
  }
}

======================================================================
REFRESH ACCOUNT STATUS POLICY
======================================================================

A successful refresh-token rotation must not result in a new access token for
a user whose account is no longer active.

After rotation resolves the session/user identity:

- user missing → revoke session and fail generically;
- suspended → revoke session and fail;
- deactivated → revoke session and fail;
- active → issue new access token.

If rotation already produced a new refresh token but the user is unavailable,
revoke the session and DO NOT return the generated token.

Do not extend session expires_at.

======================================================================
PASSWORD REHASH POLICY
======================================================================

The password-security layer already supports:

needsRehash(...)

After a SUCCESSFUL login password verification:

if:
passwordHasher.needsRehash(user.passwordHash) == true

then:

1. generate a fresh approved Argon2id hash from the supplied password;
2. persist the replacement hash;
3. update users.updated_at;
4. continue login.

This must happen only after successful password verification.

Extend UserRepository only as much as necessary, e.g.:

Future<void> updatePasswordHash({
  required ObjectId userId,
  required String passwordHash,
  required DateTime updatedAt,
});

or an equivalently narrow API.

Do NOT add general user-update functionality.

Mongo implementation must update only:

password_hash
updated_at

Do not change role/status/email as part of password rehash.

Tests must verify:

- current hash → no update;
- outdated hash → update;
- wrong password → no update.

TASK 011 must NOT perform a live password-rehash mutation against Atlas.

======================================================================
LOGOUT SEMANTICS
======================================================================

Logout receives the refresh token.

Use the existing session revocation primitive.

Logout should be externally idempotent.

If the supplied refresh token is:

already revoked
already invalid
unknown
expired

the endpoint may still return the normal logout success response.

Do not reveal token/session existence through logout.

Replay-detection logic belongs primarily to refresh rotation.

Do NOT return a refresh-token hash.

======================================================================
RATE LIMITING NOTE
======================================================================

TASK 011 does NOT implement production rate limiting.

Do NOT create a misleading single-process in-memory limiter and describe it as
scalable production protection.

Document explicitly that before internet-facing deployment:

signup
login
refresh

require a production rate-limiting strategy using infrastructure appropriate
for multiple backend instances.

Rate limiting will be a later dedicated architecture task.

======================================================================
PURPOSE OF TASK 011
======================================================================

TASK 011 must:

1. verify TASK 010 is committed and repository starts clean;
2. verify backend baseline health;
3. add no new package unless a genuine blocker is found;
4. create focused authentication input validation;
5. create authentication application result/error contracts;
6. create AuthenticationService;
7. implement signup behavior;
8. implement login behavior;
9. implement missing-user timing hardening;
10. implement transparent password rehash;
11. implement refresh behavior;
12. implement logout behavior;
13. add only the four approved HTTP endpoints;
14. compose required dependencies cleanly with Dart Frog;
15. keep route handlers thin;
16. use existing response envelope;
17. avoid account enumeration;
18. add comprehensive service tests;
19. add comprehensive route tests using fakes/test dependency overrides;
20. avoid real Atlas user/session mutations;
21. preserve health/readiness;
22. document the authentication API;
23. verify Flutter remains unchanged;
24. run formatting/analyze/tests/routes;
25. create TASK 011 report;
26. leave everything uncommitted for ChatGPT review.

======================================================================
STRICT SAFETY RULES
======================================================================

For TASK 011:

1. Do NOT modify Flutter.
2. Do NOT add Flutter packages.
3. Do NOT implement auth UI.
4. Do NOT implement Flutter token storage.
5. Do NOT implement auth middleware for protected marketplace routes.
6. Do NOT add /me.
7. Do NOT add logout-all.
8. Do NOT add password reset.
9. Do NOT add email verification delivery.
10. Do NOT add email verification endpoint.
11. Do NOT implement OAuth.
12. Do NOT implement MFA.
13. Do NOT implement rate limiting.
14. Do NOT implement captcha.
15. Do NOT add Redis.
16. Do NOT add session cookies.
17. Do NOT use browser cookies for Flutter-native auth in this task.
18. Do NOT put refresh tokens into access JWTs.
19. Do NOT put password data into JWTs.
20. Do NOT expose password hashes.
21. Do NOT log passwords.
22. Do NOT log access tokens.
23. Do NOT log refresh tokens.
24. Do NOT log token hashes.
25. Do NOT print backend/.env.
26. Do NOT expose ACCESS_TOKEN_SECRET.
27. Do NOT create a default signing secret.
28. Do NOT publicly expose MongoDB errors.
29. Do NOT create admin accounts through public signup.
30. Do NOT create customer_profiles.
31. Do NOT create cleaner_profiles.
32. Do NOT create addresses.
33. Do NOT create bookings.
34. Do NOT create any other product collection.
35. Do NOT seed users.
36. Do NOT create sample/live users on Atlas.
37. Do NOT call signup/login endpoints against real Atlas if doing so would create
    test data.
38. Do NOT create live session documents for testing.
39. Do NOT alter existing live application data.
40. Do NOT modify password parameters.
41. Do NOT modify token/session security parameters.
42. Do NOT add packages unless genuinely necessary.
43. Do NOT stage.
44. Do NOT commit.
45. Do NOT push.
46. Do NOT modify historical TASK 001–010 reports.
47. Do NOT make unrelated changes.

No live Atlas application-data mutation is authorized in TASK 011.

======================================================================
STEP 1 — VERIFY CLEAN CHECKPOINT
======================================================================

From repository root:

git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -10 --oneline

Expected:

Git root:
D:\freelance\erfankhan_cse489\final

Branch:
main

Working tree:
clean

backend/.env may exist but remains ignored.

Verify required files including:

backend/lib/src/features/users/data/user_repository.dart
backend/lib/src/features/users/data/mongo_user_repository.dart
backend/lib/src/features/auth/security/password_policy.dart
backend/lib/src/features/auth/security/password_hasher.dart
backend/lib/src/features/auth/tokens/access_token_service.dart
backend/lib/src/features/auth/tokens/jwt_access_token_service.dart
backend/lib/src/features/auth/sessions/auth_session_service.dart
backend/lib/src/features/auth/sessions/user_session_repository.dart
backend/routes/api/v1/health.dart
backend/routes/api/v1/ready.dart
documentation/cursor/010_access_token_and_refresh_session_security_foundation.md

Run:

git check-ignore -v backend/.env

Do NOT print backend/.env.

If working tree is not clean:

STOP.

======================================================================
STEP 2 — PRE-TASK BACKEND HEALTH
======================================================================

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

dart analyze
→ no issues

dart test
→ 118 tests pass

Routes:

/
/api/v1/health
/api/v1/ready

If baseline fails:

STOP.

======================================================================
STEP 3 — DEPENDENCY AUDIT
======================================================================

Inspect backend/pubspec.yaml.

TASK 011 should normally require:

NO new direct package.

Use existing:

dart_frog
mongo_dart
hashlib
dart_jsonwebtoken
mocktail
test

Do not add a validation framework merely for four small request objects.

Do not add serialization/code-generation packages.

If a new dependency is genuinely unavoidable:

STOP and report before adding it.

======================================================================
STEP 4 — INSPECT EXISTING AUTH CONTRACTS
======================================================================

Before implementing anything, inspect:

UserRepository
MongoUserRepository
PasswordPolicy
PasswordHasher
AccessTokenService
JwtAccessTokenService
AuthSessionService
UserSessionRepository
JSON response helper
Dart Frog middleware/provider structure

Reuse current contracts.

Do not duplicate cryptography or token/session logic inside route handlers.

======================================================================
STEP 5 — CREATE AUTH INPUT VALIDATION
======================================================================

Create a focused application/input area such as:

backend/lib/src/features/auth/application/

Create only real files.

Implement a small email validator/helper.

Required behavior:

- input must be String;
- email is trimmed;
- non-empty;
- <= 254 characters;
- no embedded whitespace/control characters;
- exactly one valid @ split;
- non-empty local part;
- non-empty domain part.

Avoid a giant email regex.

Create JSON parsing helpers/contracts for:

SignupRequest
LoginRequest
RefreshRequest
LogoutRequest

or equivalent names.

Required fields must reject:

missing
null
wrong type

Ignore/allow unknown JSON fields only if deliberately documented.

Prefer rejecting malformed required input while not overengineering strict
schema machinery.

======================================================================
STEP 6 — JSON BODY HANDLING
======================================================================

Auth routes accept:

Content-Type: application/json

Reject clearly unsupported media types with a suitable 400/415 behavior based
on the existing API conventions.

Malformed JSON must return a safe 400 error.

Do not expose JSON parser exception messages.

Do not print request bodies.

Do not log passwords or tokens.

======================================================================
STEP 7 — CREATE AUTH APPLICATION EXCEPTIONS
======================================================================

Create a small stable set, such as:

InvalidSignupInputException
InvalidCredentialsException
DuplicateEmailException / reuse existing DuplicateUserEmailException mapping
AccountUnavailableException
InvalidRefreshCredentialsException
AuthenticationConfigurationException

Reuse existing feature-specific exceptions where appropriate.

Do NOT create dozens of one-line exception classes if an enum/result is more
coherent.

Keep the external HTTP error mapping centralized.

======================================================================
STEP 8 — AUTHENTICATION RESULT
======================================================================

Create a safe result type such as:

AuthenticationResult

containing:

UserAccount user
String accessToken
String refreshToken

and, if useful:

int expiresInSeconds = 900

Do not include:

passwordHash
refreshTokenHash
used hashes
signing secret

For refresh, a token-only result may be a separate:

RefreshedTokens

or reuse a coherent result without forcing unnecessary user data.

======================================================================
STEP 9 — CREATE AUTHENTICATION SERVICE
======================================================================

Create:

AuthenticationService

or equivalent under auth application logic.

It composes:

UserRepository
PasswordPolicy
PasswordHasher
AccessTokenService
AuthSessionService

It must NOT depend on:

Dart Frog Request
Response
RequestContext

Keep HTTP outside the application service.

======================================================================
STEP 10 — PROCESS-SCOPED DUMMY HASH
======================================================================

AuthenticationService needs a dummy encoded Argon2id hash for missing-user
login timing hardening.

Do NOT create a new dummy hash on every login.

Choose a clean process/service-scoped approach.

Examples:

- create the dummy hash once when the shared AuthenticationService is composed;
- inject a dummy hash into AuthenticationService construction.

The dummy value must be generated using the approved PasswordHasher with a
fixed fake/non-secret password.

Do NOT use a real credential.

Do NOT log the dummy hash.

Tests may inject a simple fake value.

======================================================================
STEP 11 — SIGNUP SERVICE
======================================================================

Implement conceptually:

signUp({
  required String email,
  required String password,
  required UserRole role,
})

Rules:

1. role must be customer or cleaner;
2. email HTTP validation passed;
3. password must pass PasswordPolicy;
4. do NOT mutate password;
5. hash password using PasswordHasher;
6. call UserRepository.create with:
   role
   trimmed email
   password hash
   accountStatus active
   emailVerified false
7. database unique index remains final duplicate-email boundary;
8. map DuplicateUserEmailException to a stable application duplicate result;
9. create refresh session using AuthSessionService;
10. issue access JWT using:
    user.id
    session.id
    user.role
11. return safe AuthenticationResult.

IMPORTANT:

Before user creation, ensure token/signing configuration is usable.

A missing/short signing secret must NOT allow the route to create a user and
then fail while issuing tokens.

If necessary, expose a safe configuration-readiness method or construct the
access-token service in a way that fails before persistence mutation.

Do not duplicate JWT secret validation logic manually if the token service can
own it coherently.

======================================================================
STEP 12 — SIGNUP FAILURE RECOVERY
======================================================================

If UserRepository.create succeeds but later session creation fails because of
an unexpected infrastructure problem:

do NOT automatically delete the newly created user in TASK 011.

Account creation can remain durable and the user can later log in.

Document this non-transactional consequence.

Do NOT introduce a cross-collection transaction merely for TASK 011 unless the
existing Mongo architecture already supports it naturally.

Do NOT claim signup is transactionally atomic across users and sessions.

======================================================================
STEP 13 — LOGIN SERVICE
======================================================================

Implement:

login({
  required String email,
  required String password,
})

Flow:

1. validate/trim EMAIL;
2. do not normalize/transform password;
3. find user through UserRepository.findByEmail;
4. if user does not exist:
   call PasswordHasher.verify against the process-scoped dummy hash;
   throw InvalidCredentialsException;
5. if user exists:
   call PasswordHasher.verify against user.passwordHash;
6. wrong password:
   InvalidCredentialsException;
7. only after valid password:
   inspect accountStatus;
8. non-active:
   AccountUnavailableException;
9. if active:
   optionally rehash password as described later;
10. create refresh session;
11. issue access JWT;
12. return AuthenticationResult.

Unknown-user and wrong-password routes must map to identical HTTP 401
responses.

======================================================================
STEP 14 — LOGIN INPUT SIZE
======================================================================

Do NOT apply the signup minimum-length policy before login verification.

However reject clearly unreasonable login password input.

Use the existing PasswordPolicy maximum:

128 Unicode code points

as a supported login upper bound.

Empty password may be rejected as invalid credentials/input.

Do not trim it.

Do not enforce:

15-character minimum
uppercase
number
symbol

during login.

======================================================================
STEP 15 — USER REPOSITORY PASSWORD UPDATE
======================================================================

Extend UserRepository narrowly with an operation equivalent to:

updatePasswordHash({
  required ObjectId userId,
  required String passwordHash,
  required DateTime updatedAt,
});

Implement in MongoUserRepository.

The Mongo update selector must use:

_id

The update must change only:

password_hash
updated_at

Do not expose a generic arbitrary update map to higher application layers.

Add repository tests without Atlas.

======================================================================
STEP 16 — TRANSPARENT PASSWORD REHASH
======================================================================

During login, AFTER correct password verification and active-account check:

if:

passwordHasher.needsRehash(user.passwordHash)

then:

newHash = passwordHasher.hash(password)

persist through:

UserRepository.updatePasswordHash(...)

Use UTC updatedAt.

If update succeeds:

continue authentication.

Do not expose whether rehash occurred.

If the persistence update fails unexpectedly:

do not silently pretend it succeeded.

Propagate as an internal/infrastructure failure.

Tests:

current hash:
→ no update

outdated hash:
→ one update

wrong password:
→ no update

missing user:
→ no update

======================================================================
STEP 17 — REFRESH SERVICE
======================================================================

Implement application-level refresh:

refresh(rawRefreshToken)

Flow:

1. require non-empty token;
2. call AuthSessionService.rotateRefreshToken;
3. receive rotated session + NEW raw refresh token;
4. load user by rotated session.userId;
5. if user missing:
   revoke session;
   fail generically;
6. if accountStatus != active:
   revoke session;
   fail generically/account unavailable as appropriate internally;
7. issue new access JWT using:
   user.id
   session.id
   current user.role
8. return:
   new access token
   new refresh token
   expires_in = 900

Never return the old refresh token.

Never extend session expiresAt.

Replay detection from AuthSessionService remains authoritative.

======================================================================
STEP 18 — REFRESH EXTERNAL FAILURE POLICY
======================================================================

Externally, these should all become:

HTTP 401
code:
invalid_refresh_token

or an equally stable generic code:

unknown token
expired token
revoked token
replayed/consumed token
missing user after session resolution

Do not tell an unauthenticated client:

"replay detected"
"user deleted"
"session revoked"

Internally replay must still revoke the session.

======================================================================
STEP 19 — LOGOUT SERVICE
======================================================================

Implement logout via the existing:

AuthSessionService.revokeSession(rawRefreshToken)

The HTTP behavior should be idempotent.

For:

valid token
unknown token
expired token
already revoked token

return the normal success response.

Do not expose token validity.

Do not issue replacement tokens.

Do not delete session documents.

======================================================================
STEP 20 — TOKEN RESPONSE DTO
======================================================================

Create a safe HTTP/application serialization boundary.

Token response fields:

access_token
refresh_token
token_type
expires_in

Values:

token_type:
Bearer

expires_in:
900

Do NOT return:

session refresh hash
used hashes
JWT signing information
JWT secret
password data

======================================================================
STEP 21 — AUTH DEPENDENCY COMPOSITION
======================================================================

Inspect the existing Dart Frog middleware architecture.

Compose shared authentication dependencies without creating expensive objects
or dummy Argon2 hashes per request.

Requirements:

- reuse shared MongoDatabase lifecycle;
- repositories may be lightweight;
- PasswordHasher may be shared;
- dummy hash generated once per auth service/process composition;
- ACCESS_TOKEN_SECRET validation remains owned by token service/configuration;
- route handlers receive an AuthenticationService through an appropriate Dart
  Frog Provider/context boundary.

If Dart Frog's middleware/provider structure makes a process-scoped service
awkward, create a small explicit dependency container/factory.

Do NOT use a global mutable service locator.

Do NOT add get_it or another DI package.

Do NOT initialize MongoDB solely because /health is requested.

Prefer auth-specific middleware under:

routes/api/v1/auth/_middleware.dart

if that cleanly scopes dependencies to auth routes.

======================================================================
STEP 22 — AUTH CONFIGURATION WITHOUT REAL SECRET
======================================================================

TASK 010 intentionally did not require a real ACCESS_TOKEN_SECRET.

TASK 011 tests must use fake secrets.

The backend should still be able to start without a real secret.

If an auth endpoint is invoked while ACCESS_TOKEN_SECRET is absent/too short:

return sanitized:

HTTP 503
code:
authentication_unavailable

Do not create a user/session before this failure.

Do not return the configuration reason.

Do not generate a default signing key.

======================================================================
STEP 23 — SIGNUP ROUTE
======================================================================

Create:

backend/routes/api/v1/auth/signup.dart

POST only.

Responsibilities:

- parse JSON;
- validate request type/fields;
- parse role;
- call AuthenticationService.signUp;
- map application exceptions to HTTP;
- serialize safe result.

Do NOT:

hash password in route
query MongoDB in route
create JWT in route
create session directly in route

Expected key behaviors:

valid customer/cleaner:
201

admin:
400

duplicate email:
409

invalid password:
400

invalid email:
400

wrong method:
405

======================================================================
STEP 24 — LOGIN ROUTE
======================================================================

Create:

backend/routes/api/v1/auth/login.dart

POST only.

Responsibilities:

- parse JSON;
- validate fields;
- call AuthenticationService.login;
- map result.

Invalid email/password credentials externally:

401
invalid_credentials

Do not expose account existence.

Inactive account after correct credentials:

403
account_unavailable

Wrong method:
405

======================================================================
STEP 25 — REFRESH ROUTE
======================================================================

Create:

backend/routes/api/v1/auth/refresh.dart

POST only.

Responsibilities:

- parse refresh_token String;
- call AuthenticationService.refresh;
- return rotated token pair.

Invalid/replayed/expired/revoked token externally:

401
invalid_refresh_token

Never expose replay-specific information.

Wrong method:
405

======================================================================
STEP 26 — LOGOUT ROUTE
======================================================================

Create:

backend/routes/api/v1/auth/logout.dart

POST only.

Responsibilities:

- parse refresh_token String;
- call AuthenticationService.logout;
- return generic success.

Do not expose whether the token/session existed.

Wrong method:
405

======================================================================
STEP 27 — ROUTE ERROR MAPPING
======================================================================

Keep route/application error mapping centralized enough that the four routes
do not each reinvent a large switch.

A small:

auth_http_errors.dart
auth_route_helpers.dart

or equivalent is acceptable.

Do not create a full web framework inside Dart Frog.

Use the existing JSON helper.

======================================================================
STEP 28 — SERVICE TESTS
======================================================================

Create AuthenticationService tests using fakes/mocks only.

Test signup:

- customer success;
- cleaner success;
- admin rejected;
- password policy failure;
- duplicate email mapped;
- password is hashed before persistence;
- password is not transformed;
- email is trimmed;
- account active;
- emailVerified false;
- session created;
- access token issued;
- config failure occurs before user persistence.

Test login:

- success;
- wrong password;
- nonexistent user;
- missing-user dummy verify occurs;
- wrong-password and nonexistent-user use same application error;
- suspended account;
- deactivated account;
- current hash no rehash;
- outdated hash rehashed;
- wrong password no rehash;
- session/access tokens created only after successful authentication.

Test refresh:

- success returns NEW refresh token;
- access token uses current role;
- missing user revokes session and fails;
- suspended/deactivated user revokes session;
- replay/invalid exceptions map to generic application refresh failure;
- expiry is not extended.

Test logout:

- valid delegates revoke;
- invalid token still produces idempotent success externally/application
  behavior as designed.

No Atlas.

======================================================================
STEP 29 — ROUTE TEST DEPENDENCY OVERRIDES
======================================================================

Route tests MUST NOT connect to Atlas.

Use Dart Frog context provider overrides / fake AuthenticationService.

Do not construct the production Mongo repositories in route tests.

If AuthenticationService is difficult to fake because it is concrete, create a
small:

AuthenticationServiceContract

or equivalent interface.

Do not overengineer.

======================================================================
STEP 30 — SIGNUP ROUTE TESTS
======================================================================

Test:

POST valid:
201

malformed JSON:
400

wrong content/body types:
400

missing email:
400

invalid email:
400

missing password:
400

short password result:
400

customer:
accepted

cleaner:
accepted

admin:
400

duplicate:
409

wrong HTTP method:
405

configuration unavailable:
503

Verify password/tokens are never included in error payloads.

======================================================================
STEP 31 — LOGIN ROUTE TESTS
======================================================================

Test:

valid:
200

wrong credentials:
401

unknown-user application failure:
same 401 body semantics

inactive account:
403

malformed JSON:
400

missing fields:
400

wrong method:
405

configuration unavailable:
503 if applicable

No account-existence distinction in 401 body.

======================================================================
STEP 32 — REFRESH ROUTE TESTS
======================================================================

Test:

valid:
200

new access token field exists in fake result
new refresh token field exists in fake result

invalid token:
401

replay-internal exception:
still generic 401 externally

malformed JSON:
400

missing refresh_token:
400

wrong method:
405

configuration unavailable:
503 if applicable

Do not expose replay detection in response.

======================================================================
STEP 33 — LOGOUT ROUTE TESTS
======================================================================

Test:

valid:
200

unknown/invalid:
200 idempotent success

malformed input:
400

wrong method:
405

Do not expose session/token existence.

======================================================================
STEP 34 — RESPONSE SECURITY TESTS
======================================================================

Across route tests explicitly check successful signup/login responses do NOT
contain keys or text equivalent to:

password_hash
passwordHash
email_normalized
refresh_token_hash
used_refresh_token_hashes
ACCESS_TOKEN_SECRET

It is expected to contain raw:

access_token
refresh_token

because those are authentication credentials deliberately returned to the
client.

Do not print their fake values in test logs.

======================================================================
STEP 35 — JSON RESPONSE SHAPE
======================================================================

Signup/login:

{
  "success": true,
  "data": {
    "user": <safe public user>,
    "tokens": {
      "access_token": "...",
      "refresh_token": "...",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}

Refresh:

{
  "success": true,
  "data": {
    "tokens": {
      "access_token": "...",
      "refresh_token": "...",
      "token_type": "Bearer",
      "expires_in": 900
    }
  }
}

Logout may use:

{
  "success": true,
  "data": {
    "logged_out": true
  }
}

or an equally small established response shape.

======================================================================
STEP 36 — NO LIVE AUTH CALLS
======================================================================

Do NOT invoke:

POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

against the real locally configured Atlas backend during TASK 011.

Reason:

signup/session creation would mutate live development application data.

Route behavior is verified through fake/context-based tests.

Only live checks permitted:

GET /
GET /api/v1/health
GET /api/v1/ready

No real user/session documents.

======================================================================
STEP 37 — FORMAT
======================================================================

From backend/:

dart format .

======================================================================
STEP 38 — ANALYZE
======================================================================

Run:

dart analyze

Must report no issues.

======================================================================
STEP 39 — TEST
======================================================================

Run:

dart test

All tests must pass.

Report exact final count.

No test contacts Atlas.

======================================================================
STEP 40 — ROUTE LIST
======================================================================

Run:

dart_frog list

Expected routes now:

/
/api/v1/health
/api/v1/ready
/api/v1/auth/signup
/api/v1/auth/login
/api/v1/auth/refresh
/api/v1/auth/logout

No other new route.

======================================================================
STEP 41 — HEALTH REGRESSION
======================================================================

Start Dart Frog only if practical.

Verify only:

GET /
GET /api/v1/health
GET /api/v1/ready

Do NOT call auth endpoints live.

The backend must still start when the developer has not added
ACCESS_TOKEN_SECRET because token service use should fail lazily/safely.

Health:
200

Ready:
200 when Atlas is reachable.

Stop server afterward.

Report non-TTY StdinException if it recurs.

======================================================================
STEP 42 — VERIFY NO LIVE DATA MUTATION
======================================================================

Do not count/dump user or session documents.

Instead verify:

- all auth HTTP route tests use fake AuthenticationService;
- no live auth HTTP request was executed;
- no database setup tool inserting users/sessions was run;
- TASK 011 does not contain a new live auth fixture script.

No live Atlas application mutation is allowed.

======================================================================
STEP 43 — SECURITY AUDIT
======================================================================

Review new source for:

password
token
secret
credential
email

Confirm:

- passwords never logged;
- passwords are never transformed;
- missing-user login still verifies a dummy hash;
- wrong-password and unknown-email responses are identical;
- access/refresh tokens never logged;
- refresh-token hashes never sent in HTTP;
- UserAccount public representation remains safe;
- JWT creation stays inside AccessTokenService;
- password hashing stays inside PasswordHasher;
- session token generation stays inside AuthSessionService;
- admin cannot public-signup;
- inactive accounts cannot login;
- inactive/missing accounts cannot refresh;
- malformed auth errors are sanitized;
- no real secret added;
- backend/.env ignored.

======================================================================
STEP 44 — RATE-LIMITING DOCUMENTATION
======================================================================

Document clearly that these new endpoints are NOT ready for unrestricted
public internet exposure until production rate limiting is added.

Do not state that CORS is rate limiting.

Do not claim password hashing alone prevents brute-force login attempts.

State that a later multi-instance-capable rate limiting design is required for:

signup
login
refresh

======================================================================
STEP 45 — DOCUMENT AUTHENTICATION API
======================================================================

Create:

documentation/api/authentication-api.md

Document:

POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

For each:

request JSON
success status
safe response shape
major error statuses/codes

Document:

- public roles customer/cleaner only;
- admin cannot self-register;
- passwords 15–128 on signup;
- login errors do not reveal account existence;
- refresh token rotates;
- replay failure is externally generic;
- logout idempotent;
- access lifetime 15 minutes;
- refresh session absolute lifetime 30 days.

Do NOT include real tokens, passwords, hashes, or secrets.

Add a clear:

Production Security Prerequisite

section noting rate limiting is still required.

======================================================================
STEP 46 — DOCUMENT AUTH APPLICATION ARCHITECTURE
======================================================================

Create:

documentation/architecture/authentication-application-flow.md

Document:

Signup:

HTTP route
  ↓
AuthenticationService
  ↓
PasswordPolicy / PasswordHasher
  ↓
UserRepository
  ↓
AuthSessionService
  ↓
AccessTokenService

Login:

route
  ↓
AuthenticationService
  ↓
UserRepository
  ↓
PasswordHasher
  ↓
optional password rehash
  ↓
AuthSessionService
  ↓
AccessTokenService

Refresh:

route
  ↓
AuthenticationService
  ↓
AuthSessionService atomic rotation
  ↓
UserRepository account-state check
  ↓
AccessTokenService

Logout:

route
  ↓
AuthenticationService
  ↓
AuthSessionService revocation

Document missing-user dummy hash timing hardening.

Document non-transactional signup consequence if user creation succeeds but
session creation later fails.

======================================================================
STEP 47 — CREATE ADR-009
======================================================================

Create:

documentation/decisions/ADR-009-authentication-application-flow.md

Use:

# ADR-009 — Authentication Application Flow

## Status
## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Status:
Accepted

Decision must include:

- dedicated AuthenticationService;
- thin Dart Frog routes;
- customer/cleaner public signup only;
- active + email_verified=false initial accounts;
- generic login credential errors;
- missing-user dummy Argon2 verification;
- transparent password rehash after successful login;
- refresh session rotation through AuthSessionService;
- account-status check before issuing new refreshed access token;
- idempotent logout;
- no live auth fixtures in development Atlas;
- production rate limiting deferred but required before public deployment.

Alternatives:

### Business logic directly in route handlers

Rejected.

### Returning "email not found" during login

Rejected because it enables account enumeration.

### Skipping hashing for nonexistent users

Rejected because it creates an obvious timing distinction.

### Apply current signup minimum password length during login

Rejected because future policy changes must not lock out legacy valid users.

### Allow admin self-registration

Rejected.

### Delete a newly created user when session creation fails

Not selected in TASK 011 because implicit compensation can create additional
failure modes; account remains valid and can later login.

### In-memory rate limiter

Not adopted as production protection because it does not coordinate across
multiple backend instances.

Consequences:

- first real auth HTTP API exists;
- signup may durably create an account even if later session infrastructure
  fails;
- login avoids basic user enumeration;
- password hashes can migrate transparently;
- refresh checks current account status;
- routes remain testable through service dependency overrides;
- public deployment still requires rate limiting.

Deferred:

- email verification delivery/enforcement;
- password reset;
- authentication middleware;
- protected routes;
- logout-all HTTP route;
- production rate limiting;
- captcha;
- MFA;
- OAuth;
- Flutter secure token storage;
- Flutter auth UI.

======================================================================
STEP 48 — UPDATE DOCUMENTATION INDEXES
======================================================================

Update only as needed:

documentation/README.md
documentation/api/README.md
documentation/architecture/README.md
documentation/decisions/README.md
documentation/architecture/backend-api-architecture.md
backend/README.md

Add links to:

documentation/api/authentication-api.md
documentation/architecture/authentication-application-flow.md
documentation/decisions/ADR-009-authentication-application-flow.md

Update API docs to reflect the four new real endpoints.

Do not claim authentication middleware/protected marketplace routes exist.

======================================================================
STEP 49 — FLUTTER VERIFICATION
======================================================================

From repository root:

git diff -- project/

Expected:

empty.

Do not modify Flutter API services yet.

======================================================================
STEP 50 — REVIEW EXACT CHANGES
======================================================================

Run:

git status --short
git diff -- backend/pubspec.yaml
git diff -- backend/pubspec.lock
git diff -- backend/lib/
git diff -- backend/routes/
git diff -- backend/test/
git diff -- project/
git diff -- documentation/
git diff -- backend/README.md

Expected:

no dependency changes unless an approved blocker was reported.

Auth routes/application code are expected.

Flutter unchanged.

No real secret.

No live fixture.

======================================================================
STEP 51 — CREATE TASK 011 REPORT
======================================================================

Create:

documentation/cursor/011_authentication_application_service_and_http_api.md

using:

documentation/cursor/task-report-template.md

The report MUST contain the COMPLETE EXACT TASK 011 prompt under:

## Exact Cursor Prompt

Document:

- clean checkpoint;
- pre-task analyze/test/routes;
- dependency audit;
- auth input validation;
- AuthenticationService;
- dummy-hash timing hardening;
- signup behavior;
- login behavior;
- password rehash;
- refresh behavior;
- logout behavior;
- repository password-hash update;
- dependency composition;
- routes;
- HTTP error mapping;
- service tests;
- route tests;
- exact final test count;
- analysis result;
- route list;
- live health/readiness result;
- explicit no-live-auth-call confirmation;
- no Atlas app-data mutation;
- security audit;
- rate-limiting prerequisite;
- Flutter unchanged;
- documentation;
- files created;
- files modified;
- files deleted;
- final Git status;
- unresolved issues.

Never include:

- backend/.env;
- ACCESS_TOKEN_SECRET;
- MONGODB_URI;
- real passwords;
- real access tokens;
- real refresh tokens;
- real token hashes;
- real user/session documents.

======================================================================
STEP 52 — FINAL VERIFICATION
======================================================================

From backend/:

dart analyze
dart test
dart_frog list

From repository root:

git status --short
git diff -- project/
git check-ignore -v backend/.env

Expected routes exactly:

/
/api/v1/health
/api/v1/ready
/api/v1/auth/signup
/api/v1/auth/login
/api/v1/auth/refresh
/api/v1/auth/logout

All tests pass.

No Flutter diff.

======================================================================
STEP 53 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 011 uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond with exactly these top-level sections:

# TASK 011 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:

- Git root
- branch
- clean starting state
- latest commit
- pre-task analysis
- pre-task test count
- pre-task routes
- backend/.env ignored

## Dependencies

State whether any new package was added.

Expected:

None.

## Input Validation

Describe email/password/request validation.

## Authentication Service

Describe composed dependencies and HTTP-independent design.

## Signup

Describe:

- allowed roles
- defaults
- password hashing
- duplicate handling
- session/access-token creation

## Login

Describe:

- generic credential failure
- dummy-hash timing hardening
- account status handling
- session/access-token creation

## Password Rehash

Describe current/outdated hash behavior and repository update.

## Refresh

Describe:

- token rotation
- user/account-state validation
- new access-token issuance
- generic external refresh failures

## Logout

Describe idempotent revocation behavior.

## HTTP API

List the four endpoints with final statuses/error mapping.

## Tests

List new/modified tests.

Report exact:

dart test

result and test count.

Confirm route tests use fakes and tests do not contact Atlas.

## Static Analysis

Report:

dart analyze

result.

## Routes

Provide final:

dart_frog list

## Live Backend Verification

Report only root/health/readiness checks.

Confirm auth routes were NOT invoked against live Atlas.

## Live Data Safety

Confirm no real user/session document was inserted, updated, deleted, or
dumped.

## Files Created

List TASK 011-created files.

## Files Modified

List TASK 011-modified files.

## Files Deleted

List TASK 011-deleted files.

## Documentation

Confirm creation of:

documentation/api/authentication-api.md
documentation/architecture/authentication-application-flow.md
documentation/decisions/ADR-009-authentication-application-flow.md
documentation/cursor/011_authentication_application_service_and_http_api.md

## Rate-Limiting Prerequisite

Confirm documentation states production rate limiting remains required before
public exposure.

## Flutter Verification

Report:

git diff -- project/

## Security Verification

Confirm:

- passwords not logged/transformed;
- missing-user dummy verify exists;
- unknown user and wrong password map identically;
- admin self-signup prohibited;
- inactive accounts cannot authenticate;
- tokens not logged;
- hashes not exposed;
- no default signing secret;
- backend/.env ignored;
- no secret exposed.

## Git Status

Provide final:

git status --short

## Issues / Warnings

Report relevant warnings.

## Final Statement

State whether authentication application behavior and HTTP API are complete
and ready for ChatGPT review.

Do NOT implement Flutter auth.

Do NOT implement protected marketplace routes.

Do NOT begin TASK 012.

Start TASK 011 now.
``

## Pre-Task Repository State

- Git root: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- Working tree: clean (TASK 010 committed)
- Latest commit: `dc4b0e8` `access_token_and_refresh_session_security_foundation`
- `backend/.env` present and ignored (`.gitignore:8:.env`)
- Pre-task `dart analyze`: no issues
- Pre-task `dart test`: 118 tests passed
- Pre-task `dart_frog list`: `/`, `/api/v1/health`, `/api/v1/ready`
- No new packages were added (`pubspec.yaml` unchanged)

## Work Performed

1. Verified the TASK 010 checkpoint and backend baseline.
2. Extended `UserRepository` with `updatePasswordHash` (`password_hash` + `updated_at` only).
3. Added `AccessTokenService.ensureConfigured` so missing/short signing secrets fail before persistence.
4. Added `AuthSessionService.revokeById` for post-rotation account-status failures.
5. Implemented auth application validation, exceptions, results, JSON DTOs, `AuthenticationService`, dummy-hash composition, and HTTP helpers.
6. Added four POST-only Dart Frog routes plus auth-scoped middleware that process-scopes the service.
7. Added service tests (fakes/mocks) and route tests (`FakeAuthenticationService`, no Mongo).
8. Documented the API, application flow, ADR-009, and indexes.
9. Formatted, analyzed, tested, listed routes, and live-checked only `/`, `/health`, and `/ready`.
10. Did not commit, push, stage, modify Flutter, or call live auth endpoints.

## Files Created

- `backend/lib/src/features/auth/application/auth_exceptions.dart`
- `backend/lib/src/features/auth/application/email_input.dart`
- `backend/lib/src/features/auth/application/auth_requests.dart`
- `backend/lib/src/features/auth/application/authentication_result.dart`
- `backend/lib/src/features/auth/application/auth_json.dart`
- `backend/lib/src/features/auth/application/authentication_service.dart`
- `backend/lib/src/features/auth/application/auth_composition.dart`
- `backend/lib/src/features/auth/http/auth_http_errors.dart`
- `backend/lib/src/features/auth/http/auth_route_helpers.dart`
- `backend/routes/api/v1/auth/_middleware.dart`
- `backend/routes/api/v1/auth/signup.dart`
- `backend/routes/api/v1/auth/login.dart`
- `backend/routes/api/v1/auth/refresh.dart`
- `backend/routes/api/v1/auth/logout.dart`
- `backend/test/helpers/fake_authentication_service.dart`
- `backend/test/helpers/auth_route_test_utils.dart`
- `backend/test/src/features/auth/application/email_input_test.dart`
- `backend/test/src/features/auth/application/auth_requests_test.dart`
- `backend/test/src/features/auth/application/authentication_service_test.dart`
- `backend/test/routes/api/v1/auth/signup_test.dart`
- `backend/test/routes/api/v1/auth/login_test.dart`
- `backend/test/routes/api/v1/auth/refresh_test.dart`
- `backend/test/routes/api/v1/auth/logout_test.dart`
- `documentation/api/authentication-api.md`
- `documentation/architecture/authentication-application-flow.md`
- `documentation/decisions/ADR-009-authentication-application-flow.md`
- `documentation/cursor/011_authentication_application_service_and_http_api.md`

## Files Modified

- `backend/lib/src/features/users/data/user_repository.dart`
- `backend/lib/src/features/users/data/user_document_store.dart`
- `backend/lib/src/features/users/data/mongo_user_repository.dart`
- `backend/lib/src/features/auth/tokens/access_token_service.dart`
- `backend/lib/src/features/auth/tokens/jwt_access_token_service.dart`
- `backend/lib/src/features/auth/sessions/auth_session_service.dart`
- `backend/test/src/features/users/data/mongo_user_repository_test.dart`
- `backend/README.md`
- `documentation/README.md`
- `documentation/api/README.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/architecture/password-security.md`
- `documentation/database/users-collection.md`
- `documentation/decisions/README.md`
- `README.md`

## Files Deleted

None.

## Commands Executed

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status --short` / `git status`
- `git log -10 --oneline` / `git log -1 --oneline`
- `git check-ignore -v backend/.env`
- `dart pub get` (pre-task, from `backend/`)
- `dart analyze` (pre-task and post-task)
- `dart test` (pre-task 118; post-task 183)
- `dart_frog list` (pre-task and post-task)
- `dart format .`
- Focused `dart test` while fixing route Content-Type defaults and service tests
- `dart_frog dev --port 8099`
- `curl.exe` GET `/`, `/api/v1/health`, `/api/v1/ready` only
- Stopped the dev server
- `git diff --stat -- project/`
- Final `git status --short`

Did not run `git add`, `git commit`, or `git push`. Did not POST any auth route against the live Atlas-backed server.

## Implementation Details

### Input validation

- Email: must be a string; trim only; non-empty; ≤ 254; no embedded ASCII whitespace/control characters; exactly one `@`; non-empty local and domain. No RFC 5322 regex, Gmail rewriting, plus-stripping, or display-email lowercasing.
- Signup password: existing `PasswordPolicy` (15–128 Unicode code points). Never trimmed or case-folded.
- Login password: no signup minimum; empty rejected as invalid input; maximum 128 code points; never transformed.
- Requests: `SignupRequest`, `LoginRequest`, `RefreshRequest`, `LogoutRequest`. Required fields reject missing/null/wrong type. Unknown JSON fields are ignored.
- Public signup roles: `customer` and `cleaner` only. `admin`, unknown, and missing fail with `invalid_role`.

### AuthenticationService

HTTP-independent. Composes `UserRepository`, `PasswordPolicy`, `PasswordHasher`, `AccessTokenService`, `AuthSessionService`. Dummy Argon2id hash is injected at construction (process-scoped via `AuthComposition`).

Signup: ensure token config → validate role/email/policy → hash → `create` with `active` / `email_verified=false` → session → JWT. Duplicate email maps from `DuplicateUserEmailException`. Missing/short secret fails before `create`. If user create succeeds and session create later fails, the user is not deleted.

Login: trim email → find user → if missing, `verify` dummy hash then `InvalidCredentialsException` → else verify stored hash → same exception on mismatch → non-active after correct password → `AccountUnavailableException` → optional rehash → session → JWT.

Refresh: rotate via `AuthSessionService` → load user → missing/non-active revokes session and fails generically → issue JWT with current role. Replay/invalid map to `InvalidRefreshCredentialsException`. New refresh token is never returned after revoke.

Logout: `revokeSession`; `InvalidRefreshTokenException` is swallowed (idempotent success).

### HTTP

Thin POST routes. Shared JSON parse (415 unsupported media type, 400 invalid JSON without parser text). Central `mapAuthException`. Success uses existing `jsonSuccess` envelope. User objects are snake_case and omit hashes/normalized email. Tokens: `access_token`, `refresh_token`, `token_type=Bearer`, `expires_in=900`.

Statuses: signup 201; login/refresh/logout 200; bad input 400; duplicate 409; bad credentials / bad refresh 401; inactive login 403; missing config / infra 503; wrong method 405.

### Composition

`routes/api/v1/auth/_middleware.dart` resolves a process-scoped service. Dummy hash is created once. Mongo `connect()` happens on first auth composition, not on `/health`. Missing secret uses `UnavailableAccessTokenService` so signup/login/refresh fail before persistence; logout can still run if Mongo is available. Unconfigured Mongo yields `UnconfiguredAuthenticationService` (503).

## Technical Decisions

- Interface `AuthenticationService` so route tests can inject a fake without Mongo.
- Snake_case auth user JSON equivalent to `UserAccount.toPublicJson`, not camelCase, to match HTTP JSON policy.
- Dummy hash generated once with a fixed fake password through the approved hasher.
- Refresh failures (including missing/inactive user after rotation) are all HTTP 401 `invalid_refresh_token`.
- Login inactive accounts are HTTP 403 `account_unavailable` with one message for suspended and deactivated.
- No in-memory rate limiter.

## Verification Performed

- Pre-task git/analyze/test/routes/ignore
- Post-task `dart format .`, `dart analyze`, `dart test`, `dart_frog list`
- Live GET `/`, `/api/v1/health`, `/api/v1/ready` only
- `git diff -- project/` empty
- `git check-ignore -v backend/.env`

## Verification Results

- `dart analyze`: No issues found
- `dart test`: **183 tests passed** (118 baseline + 65 TASK 011 tests)
- Route tests use `FakeAuthenticationService` / mocked `RequestContext`; no Atlas
- Service tests use mocktail fakes; dummy-hash verify is asserted for missing users
- `dart_frog list`:

```text
/
/api/v1/health
/api/v1/ready
/api/v1/auth/login
/api/v1/auth/logout
/api/v1/auth/refresh
/api/v1/auth/signup
```

- Live: GET `/` 200, GET `/api/v1/health` 200, GET `/api/v1/ready` 200
- Auth routes were not invoked live
- Flutter: no diff

## Errors / Warnings

- `dart_frog dev` still raises `StdinException: Error setting terminal echo mode` in this non-TTY environment after the server starts. Health/readiness were reachable before/during that failure, matching prior tasks.
- During implementation, route tests initially returned 415 because helpers passed `contentType: null` and overrode the JSON default. Fixed by defaulting POST helpers to `application/json`.

## Security / Secrets Check

- No real secret added. No default signing secret.
- `backend/.env` remains gitignored; contents were never printed.
- Passwords are not logged or transformed.
- Missing-user login verifies a dummy Argon2id hash.
- Unknown user and wrong password map to identical `invalid_credentials`.
- Admin cannot public-signup.
- Inactive accounts cannot login; missing/inactive accounts cannot refresh to a new access token.
- Access/refresh tokens and hashes are not logged; hashes are not in HTTP JSON.
- User public JSON omits `password_hash` and `email_normalized`.
- JWT creation stays in `AccessTokenService`; hashing in `PasswordHasher`; session tokens in `AuthSessionService`.
- Route tests assert error/success bodies do not contain `password_hash`, `passwordHash`, `email_normalized`, `refresh_token_hash`, `used_refresh_token_hashes`, or `ACCESS_TOKEN_SECRET`.
- No live Atlas user/session inserts, updates, deletes, or dumps.

## Git Diff Summary

Uncommitted TASK 011 work: auth application/HTTP layer, four routes, repository password-hash update, token/session small extensions, tests, and documentation. `backend/pubspec.yaml` / lockfile unchanged. Flutter unchanged. No `.env` or secrets.

## Final Repository State

Uncommitted on `main`. Ready for ChatGPT review. Not staged, committed, or pushed.

## Unresolved Issues

- Production rate limiting is still required before public internet exposure of signup/login/refresh.
- Email verification delivery/enforcement is deferred (`email_verified=false` does not block login).
- Signup is not transactional across `users` and `user_sessions`.
- Authentication middleware, `/me`, logout-all, password reset, OAuth, MFA, Flutter token storage, and Flutter auth UI remain future work.
- `dart_frog dev` non-TTY `StdinException` remains an environment limitation.

## Suggested Next Step

A later task may add authentication middleware and a `/me` (or equivalent) protected route, or a dedicated production rate-limiting design. Do not start that work in TASK 011.
