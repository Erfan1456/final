# Cursor Task 012 — Protected Backend Authentication + Flutter Authentication Vertical Slice

## Metadata

- Task ID: 012
- Task title: Protected Backend Authentication + Flutter Authentication Vertical Slice
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Implement reusable Bearer access-token authentication and two protected account endpoints on the Dart Frog backend, then implement the Flutter authentication vertical slice: secure token storage, plain/authenticated Dio, single-flight rotating refresh, Riverpod session state, go_router guards, and login/signup/home screens. Do not implement marketplace/booking features, do not create live Atlas fixtures, and do not commit.

## Exact Cursor Prompt

```text
# TASK 012 — Protected Backend Authentication + Flutter Authentication Vertical Slice

Repository:

D:\freelance\erfankhan_cse489\final

Current high-level layout:

final/
├── backend/          ← Dart Frog backend
├── documentation/
└── project/          ← Flutter mobile client

TASK 011 established and checkpointed the authentication application service
and public HTTP API.

Current backend authentication endpoints:

POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

Existing backend infrastructure includes:

- MongoDB Atlas connectivity;
- users persistence;
- Argon2id password hashing;
- access JWTs;
- rotating opaque refresh sessions;
- AuthenticationService;
- login timing hardening;
- password rehashing;
- customer/cleaner signup;
- logout.

Current Flutter foundation includes:

- Flutter + Dart;
- Riverpod;
- go_router;
- Dio;
- AppConfig / API_BASE_URL;
- Material 3 app foundation;
- no Flutter authentication implementation yet.

TASK 012 is intentionally a substantially larger vertical-slice task.

It will implement:

BACKEND:
- reusable Bearer access-token authentication;
- protected authenticated principal context;
- protected current-user endpoint;
- protected revoke-all-sessions endpoint;
- protected-account tests and documentation.

FLUTTER:
- secure token storage;
- authentication API client;
- automatic Bearer-token attachment;
- rotating-refresh handling;
- concurrency-safe single-flight token refresh;
- automatic original-request retry;
- session-expiry signaling;
- authentication repository;
- startup session restoration;
- signup;
- login;
- logout;
- logout-all-devices;
- Riverpod authentication state;
- go_router authentication guards;
- Splash screen;
- Login screen;
- Signup screen;
- authenticated account/home screen;
- Android-emulator local HTTP development configuration;
- comprehensive tests;
- documentation.

Do NOT begin marketplace/service/booking functionality yet.

======================================================================
APPROVED NEW FLUTTER DEPENDENCY
======================================================================

Add exactly:

flutter_secure_storage: ^11.0.0

Do not add any other Flutter package unless a genuine blocker occurs.

Existing:

flutter_riverpod
go_router
dio

must be reused.

Do NOT add:

shared_preferences
get_it
provider
bloc
hooks_riverpod
jwt_decoder
retrofit
freezed
json_serializable
build_runner
hydrated_bloc
another secure-storage package
another HTTP package

No backend dependency should normally be required.

======================================================================
TOKEN STORAGE POLICY
======================================================================

Flutter may store ONLY authentication credentials in secure storage:

- access token;
- refresh token.

Do NOT store:

- password;
- password hash;
- MongoDB URI;
- ACCESS_TOKEN_SECRET;
- user profile JSON unless later justified;
- database credentials.

Prefer storing the access/refresh pair as ONE JSON value under one stable key,
rather than two unrelated writes.

Example conceptual secure value:

{
  "access_token": "...",
  "refresh_token": "..."
}

Never print this value.

Never put it into logs.

Never put it into SharedPreferences.

Never hard-code development tokens.

======================================================================
FLUTTER AUTH FLOW
======================================================================

App startup:

secure storage
    ↓
token pair exists?
    ↓
NO → unauthenticated → Login
YES
    ↓
GET protected current-user endpoint
    ↓
access token valid → authenticated
401 because access expired
    ↓
single refresh attempt
    ↓
store rotated token pair
    ↓
retry current-user request
    ↓
authenticated

If refresh fails:

- delete local secure tokens;
- become unauthenticated;
- redirect to Login.

======================================================================
REFRESH CONCURRENCY REQUIREMENT
======================================================================

Refresh tokens ROTATE.

Therefore multiple concurrent HTTP 401 responses MUST NOT each independently
send the same refresh token.

Flutter must implement a single-flight refresh mechanism.

If five protected requests fail with 401 at approximately the same time:

only ONE:

POST /api/v1/auth/refresh

may occur.

Other requests wait for that result.

If refresh succeeds:

- persist new token pair;
- retry waiting requests with new access token.

If refresh fails:

- clear stored credentials once;
- notify authentication state that the session expired;
- do not enter a refresh loop.

This is a critical requirement.

======================================================================
BACKEND PROTECTED API
======================================================================

Add exactly these protected endpoints:

GET /api/v1/account/me

DELETE /api/v1/account/sessions

Do not add more account endpoints in TASK 012.

GET /api/v1/account/me

returns the currently authenticated user's safe public account representation.

DELETE /api/v1/account/sessions

revokes all refresh sessions belonging to the authenticated user.

The access JWT used to make the revoke-all request may remain cryptographically
valid until its normal 15-minute expiration.

Flutter must nevertheless delete its local tokens immediately after successful
or locally-forced logout-all.

======================================================================
AUTHORIZATION HEADER
======================================================================

Protected requests use:

Authorization: Bearer <access-token>

Reject:

- missing header;
- wrong scheme;
- blank token;
- malformed JWT;
- bad signature;
- expired JWT;
- wrong issuer;
- wrong audience;
- non-HS256 JWT;
- malformed user/session IDs;
- invalid role.

Externally use one generic authentication response:

HTTP 401

{
  "success": false,
  "error": {
    "code": "invalid_access_token",
    "message": "Authentication is required."
  }
}

Do not expose JWT parser details.

If token verification infrastructure itself is unavailable due server
configuration:

HTTP 503
authentication_unavailable

======================================================================
CURRENT ACCOUNT POLICY
======================================================================

For:

GET /api/v1/account/me

After JWT verification:

- load UserAccount using claims.userId;
- missing user → authentication failure;
- active → return safe account;
- suspended → 403 account_unavailable;
- deactivated → 403 account_unavailable.

Return the current persisted role from UserAccount.

Do not return password_hash or email_normalized.

======================================================================
AUTH PRINCIPAL
======================================================================

Create a small authenticated-principal type representing verified access-token
identity.

Suggested fields:

ObjectId userId
ObjectId sessionId
UserRole role
String jwtId

Do not include:

password
email
refresh token
token hash
Mongo credentials

Only create this object after successful access-token verification.

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

TASK 011 must be committed.

Verify required TASK 011 files exist, including:

backend/routes/api/v1/auth/signup.dart
backend/routes/api/v1/auth/login.dart
backend/routes/api/v1/auth/refresh.dart
backend/routes/api/v1/auth/logout.dart
backend/lib/src/features/auth/application/authentication_service.dart
documentation/cursor/011_authentication_application_service_and_http_api.md

Verify:

backend/.env

exists and is ignored.

Run:

git check-ignore -v backend/.env

Do NOT print backend/.env.

Safely determine whether ACCESS_TOKEN_SECRET is configured WITHOUT printing its
value.

Use existing ServerConfig/environment-loading code or a tiny sanitized
one-off Dart check.

Report only:

ACCESS_TOKEN_SECRET configured: yes/no

Never its contents.

Do not STOP merely because it is absent; tests use fake configuration.
However record whether live auth would be available.

======================================================================
STEP 2 — PRE-TASK BACKEND BASELINE
======================================================================

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

183 tests pass

Routes should include:

/
/api/v1/health
/api/v1/ready
/api/v1/auth/login
/api/v1/auth/logout
/api/v1/auth/refresh
/api/v1/auth/signup

If baseline fails:

STOP.

======================================================================
STEP 3 — PRE-TASK FLUTTER BASELINE
======================================================================

From project/:

flutter pub get
flutter analyze
flutter test

Record exact current test count.

If baseline fails:

STOP.

Do not repair unrelated pre-existing failures.

======================================================================
STEP 4 — BACKEND ACCESS AUTHENTICATOR
======================================================================

Inspect:

AccessTokenService
JwtAccessTokenService
existing auth HTTP helpers
Dart Frog middleware/provider structure

Create reusable protected-request authentication code under an appropriate
backend auth HTTP/security location.

Implement responsibilities:

1. read Authorization;
2. require Bearer;
3. extract token;
4. verify through AccessTokenService;
5. convert verified claims to AuthenticatedPrincipal;
6. expose principal to protected Dart Frog handlers;
7. sanitize failures.

Do NOT duplicate JWT cryptography.

Do NOT call JWT.decode directly.

Do NOT manually reimplement HS256.

Use AccessTokenService.

======================================================================
STEP 5 — PROTECTED ACCOUNT MIDDLEWARE
======================================================================

Create a protected route scope:

backend/routes/api/v1/account/

Use:

backend/routes/api/v1/account/_middleware.dart

or the closest correct Dart Frog structure.

Middleware must:

- resolve shared access-token verification dependency;
- authenticate every route under /account;
- provide AuthenticatedPrincipal through RequestContext;
- return safe 401 on invalid/missing token;
- return safe 503 on auth configuration failure.

Do not authenticate:

/health
/ready
/auth/login
/auth/signup
/auth/refresh
/auth/logout

Those existing routes must remain unaffected.

Do not connect MongoDB for /health merely because account middleware exists.

======================================================================
STEP 6 — CURRENT ACCOUNT APPLICATION SERVICE
======================================================================

Create a small HTTP-independent account/authenticated-user service if useful.

Responsibilities:

getCurrentUser(userId)

and:

revokeAllSessions(userId)

Reuse:

UserRepository
AuthSessionService / UserSessionRepository

Do not put MongoDB queries directly into route handlers.

Do not create generic account CRUD.

======================================================================
STEP 7 — GET /api/v1/account/me
======================================================================

Create:

GET /api/v1/account/me

Use the protected principal.

Load current persisted UserAccount.

Behavior:

active user:
200

safe response conceptually:

{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "role": "customer",
      "email": "...",
      "account_status": "active",
      "email_verified": false,
      "created_at": "...",
      "updated_at": "..."
    }
  }
}

Do not expose:

password_hash
passwordHash
email_normalized
session hashes
JWT
refresh token

Missing user:
401 generic authentication failure

Suspended/deactivated:
403 account_unavailable

Wrong method:
405

======================================================================
STEP 8 — DELETE /api/v1/account/sessions
======================================================================

Create:

DELETE /api/v1/account/sessions

Protected endpoint.

Use authenticated principal.userId.

Revoke all user refresh sessions using the existing repository/service
primitive.

Return safe success such as:

{
  "success": true,
  "data": {
    "sessions_revoked": true
  }
}

Do not return:

token hashes
session documents
session IDs
Mongo update details

Wrong method:
405

======================================================================
STEP 9 — BACKEND TESTS
======================================================================

Add tests using fakes/mocks only.

No Atlas.

Test protected authentication:

- missing Authorization → 401;
- wrong scheme → 401;
- blank Bearer → 401;
- invalid access token → 401;
- valid token produces principal;
- auth configuration unavailable → 503.

Test /account/me:

- valid active user → 200;
- safe user shape;
- password fields absent;
- normalized email absent;
- missing user → safe failure;
- suspended/deactivated → 403;
- wrong method → 405.

Test DELETE /account/sessions:

- valid principal → revokeAllForUser called;
- success → 200;
- unauthorized → 401;
- wrong method → 405.

No backend test may use real Atlas.

======================================================================
STEP 10 — VERIFY BACKEND
======================================================================

Run:

dart format .
dart analyze
dart test
dart_frog list

Expected new routes in addition to existing:

/api/v1/account/me
/api/v1/account/sessions

Record exact backend test count.

======================================================================
STEP 11 — FLUTTER DEPENDENCY
======================================================================

From project/:

flutter pub add "flutter_secure_storage:^11.0.0"

Do NOT run flutter pub upgrade.

Confirm it is the only new direct Flutter dependency.

Inspect pubspec.lock.

Do not change:

flutter_riverpod
go_router
dio

versions unnecessarily.

======================================================================
STEP 12 — SECURE TOKEN STORAGE ABSTRACTION
======================================================================

Create real auth data-layer files.

Suggested structure:

project/lib/features/auth/
├── data/
│   ├── auth_api.dart
│   ├── auth_repository.dart
│   ├── auth_token_pair.dart
│   ├── auth_token_storage.dart
│   └── flutter_secure_auth_token_storage.dart
├── domain/
│   ├── auth_user.dart
│   └── auth_session_state.dart
└── presentation/
    ├── auth_controller.dart
    ├── login_screen.dart
    ├── signup_screen.dart
    └── authenticated_home_screen.dart

Adapt if a slightly different feature-oriented layout is cleaner.

Do not create empty directories.

Define:

AuthTokenStorage

with operations conceptually:

read()
write(AuthTokenPair pair)
clear()

Implement using FlutterSecureStorage.

Use ONE secure-storage key.

Serialize pair as JSON.

Corrupt/malformed stored JSON:

- clear it;
- treat as no session;
- do not crash startup.

Do not print values.

======================================================================
STEP 13 — AUTH USER MODEL
======================================================================

Create Flutter-side:

AuthUser

Fields needed now:

String id
String role
String email
String accountStatus
bool emailVerified
DateTime createdAt
DateTime updatedAt

Parse safe backend JSON explicitly.

Do NOT include:

password hash
email_normalized
Mongo ObjectId type
refresh token
JWT claims

Keep backend IDs as strings in Flutter.

======================================================================
STEP 14 — TOKEN RESPONSE MODEL
======================================================================

Create:

AuthTokenPair

with:

accessToken
refreshToken

Parse:

access_token
refresh_token

Do not decode JWT in Flutter merely to determine user identity.

The backend `/account/me` remains authoritative for current account data.

Do not add jwt_decoder.

======================================================================
STEP 15 — PUBLIC AUTH API CLIENT
======================================================================

Create a focused AuthApi.

Use the existing base Dio infrastructure.

Public operations:

signup
login
refresh
logout

Protected operations:

me
revokeAllSessions

Keep HTTP DTO parsing outside widgets.

Map known backend errors into small stable client failures.

Examples:

invalid_credentials
duplicate_email
account_unavailable
invalid_refresh_token
authentication_unavailable
invalid_input

Do not expose Dio internals directly to UI.

Do not create a gigantic generic networking framework.

======================================================================
STEP 16 — PLAIN AND AUTHENTICATED DIO
======================================================================

Avoid refresh recursion.

Use two logical Dio paths:

PLAIN DIO:
- signup
- login
- refresh
- logout
- no bearer-refresh interceptor

AUTHENTICATED DIO:
- /account/me
- future protected APIs
- attaches access token
- handles expired access token through refresh

They may share common BaseOptions/configuration.

Do not duplicate API base URL logic.

Refactor:

core/network/dio_provider.dart

carefully if needed.

Do not put auth feature logic into AppConfig.

======================================================================
STEP 17 — AUTHORIZATION INTERCEPTOR
======================================================================

Create an authenticated Dio interceptor.

On outgoing protected request:

- read current token pair;
- if access token exists:
  Authorization = Bearer <token>

Never attach Bearer tokens to public auth calls.

Never log Authorization header.

Do not add LogInterceptor that prints request headers/bodies.

======================================================================
STEP 18 — SINGLE-FLIGHT REFRESH COORDINATOR
======================================================================

Implement concurrency-safe refresh.

Maintain at most one in-flight refresh Future.

When authenticated request returns HTTP 401:

if request has already been retried:
→ do not retry again.

Otherwise:

if refresh already in progress:
→ await same Future.

else:
→ start one refresh using current stored refresh token.

On refresh success:

- atomically replace secure token-pair value;
- retry original request once with new access token.

On failure:

- clear token storage;
- emit one session-expired event;
- reject original requests safely.

Do not issue multiple concurrent refresh requests for the same token.

Do not use a Mutex package.

A cached Future is sufficient.

======================================================================
STEP 19 — AUTH SESSION EVENT SIGNAL
======================================================================

Create a tiny session event mechanism independent of UI.

Purpose:

network interceptor can report:

sessionExpired

without directly depending on AuthController.

A small broadcast StreamController/service is acceptable.

AuthController subscribes and becomes unauthenticated.

Dispose resources correctly.

Do not create a global mutable service locator.

Use Riverpod providers.

======================================================================
STEP 20 — REFRESH LOOP PROTECTION
======================================================================

Ensure:

POST /api/v1/auth/refresh

is NEVER processed through the authenticated-refresh interceptor.

A retried request must carry an internal marker such as:

extra['auth_retry'] = true

or equivalent.

One original request:
maximum one retry.

Prevent:

401
→ refresh
→ retry
→ 401
→ refresh
→ infinite loop

Add tests.

======================================================================
STEP 21 — AUTH REPOSITORY
======================================================================

Create Flutter AuthRepository.

Responsibilities:

signUp(...)
login(...)
restoreSession()
logout()
logoutAll()
getCurrentUser()

Signup/login:

1. call API;
2. parse user + tokens;
3. write tokens securely;
4. return authenticated user.

restoreSession:

1. read secure tokens;
2. none → unauthenticated;
3. tokens → GET /account/me via authenticated Dio;
4. interceptor may transparently refresh;
5. success → user;
6. irrecoverable authentication failure → clear storage → unauthenticated.

logout:

1. read refresh token;
2. attempt backend POST /auth/logout;
3. ALWAYS clear local storage in finally;
4. become unauthenticated even if network unavailable.

logoutAll:

1. call protected DELETE /account/sessions if possible;
2. clear local storage afterward;
3. local device becomes unauthenticated.

Do not preserve tokens after user explicitly logs out.

======================================================================
STEP 22 — AUTH CONTROLLER
======================================================================

Use Riverpod.

Create:

AuthController

with states capable of representing:

- restoring/initializing;
- unauthenticated;
- authenticated(user);
- submission/loading;
- safe UI error.

Do not put TextEditingController inside global auth state.

On app startup:

restoreSession()

must run once.

Expose actions:

login
signup
logout
logoutAll

Listen for session-expired event from network layer.

When event occurs:

- become unauthenticated;
- do not show raw network error.

Avoid rebuilding expensive infrastructure per widget.

======================================================================
STEP 23 — ROUTER AUTH GUARDS
======================================================================

Replace the foundation-only router with actual authentication routing.

Routes:

/splash
/login
/signup
/home

Root `/` may redirect.

Required navigation rules:

Restoring session:
→ /splash

Unauthenticated:
→ /login

Unauthenticated may access:
/login
/signup

Authenticated:
→ /home

Authenticated user visiting:
/login
/signup
/splash
→ /home

Do not create customer/cleaner marketplace pages yet.

Preserve one stable GoRouter instance where practical.

Use refreshListenable or an equivalent clean bridge so router redirects react
to auth state without recreating the router unnecessarily.

No auth checks inside individual screen build methods when routing can own it.

======================================================================
STEP 24 — SPLASH SCREEN
======================================================================

Create a small functional SplashScreen.

Purpose:

session restoration only.

UI may contain:

- app name;
- CircularProgressIndicator;
- brief "Restoring session..." text.

Do not make it a product landing page.

======================================================================
STEP 25 — LOGIN SCREEN
======================================================================

Create a functional Material 3 Login screen.

Fields:

Email
Password

Requirements:

- password obscured;
- email keyboard type;
- submit button;
- disabled/loading state while request active;
- navigation link to signup;
- safe user-readable server errors;
- no password logging;
- no token display.

Do not require 15-character minimum in login UI before submission.

Mirror only:

- email basic format;
- password non-empty;
- password max 128 code points.

Backend remains authoritative.

======================================================================
STEP 26 — SIGNUP SCREEN
======================================================================

Create functional Signup screen.

Fields:

Email
Password
Role

Role selector:

Customer
Cleaner

No Admin option.

Password UX may mention:

15–128 characters

but do not require:

uppercase
number
symbol

Do not trim password.

Disable submit while active.

On success:
authenticated → /home.

Do not implement cleaner onboarding yet.

======================================================================
STEP 27 — AUTHENTICATED HOME SCREEN
======================================================================

Replace the old FoundationScreen as the post-authenticated placeholder.

Keep it intentionally simple.

Show safe account information:

Home Cleaning Service Marketplace
Signed in
email
role
email verification status

Provide buttons:

Log out
Log out all devices

No cleaners list.

No bookings.

No payments.

No fake marketplace data.

Do not make this the final visual design.

======================================================================
STEP 28 — DELETE OBSOLETE FOUNDATION PLACEHOLDER
======================================================================

If:

features/foundation/presentation/foundation_screen.dart

is no longer used:

delete it.

Remove all imports/references.

Do not leave dead architecture-demo UI.

======================================================================
STEP 29 — APP BOOTSTRAP
======================================================================

Preserve:

ProviderScope
MaterialApp.router
Material 3 theme
system theme mode

main.dart must remain small.

Authentication initialization belongs in providers/controller, not main.dart.

======================================================================
STEP 30 — API BASE URL
======================================================================

Continue using:

API_BASE_URL

via String.fromEnvironment.

Do NOT hard-code production URL.

For Android Emulator development document:

flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

Do not put MongoDB URI in Flutter.

Do not put ACCESS_TOKEN_SECRET in Flutter.

If API_BASE_URL is missing:

app must still boot.

Auth submissions should show a safe configuration error instead of crashing.

======================================================================
STEP 31 — ANDROID DEBUG HTTP POLICY
======================================================================

Because Android API 28+ blocks cleartext traffic by default and local Dart Frog
development uses HTTP, add DEBUG-ONLY Android network policy.

Use:

project/android/app/src/debug/AndroidManifest.xml

and:

project/android/app/src/debug/res/xml/network_security_config.xml

or the correct equivalent.

Debug build may allow local cleartext development traffic.

Do NOT weaken:

src/main/AndroidManifest.xml

for production.

Do NOT enable cleartext globally in release configuration.

The debug policy exists only to access development backend such as:

http://10.0.2.2:8080

Preserve INTERNET permission.

Do not change package/application ID.

======================================================================
STEP 32 — FLUTTER SECURE STORAGE PLATFORM CHECK
======================================================================

Current flutter_secure_storage 11.0.0 Android minimum is API 23.

Existing project minSdk is expected to be 24.

Verify compatibility.

Do NOT lower or unnecessarily change minSdk.

Do not add biometric storage configuration.

Default secure storage is enough for TASK 012.

No native identifier changes.

======================================================================
STEP 33 — TOKEN STORAGE TESTS
======================================================================

Do NOT rely on real platform secure storage in unit tests.

Test the abstraction with fakes or an injected secure-storage adapter.

Verify:

- write/read round trip;
- clear;
- corrupt JSON clears safely;
- missing value;
- no password fields exist;
- one logical storage key.

If the concrete FlutterSecureStorage implementation itself requires a
MethodChannel, do not make ordinary unit tests depend on real platform channels.

======================================================================
STEP 34 — AUTH API TESTS
======================================================================

Use Dio test seams such as a fake HttpClientAdapter or lightweight local fake.

Do not add another package.

Test parsing/mapping:

signup success
login success
refresh success
logout
me
logout-all

Errors:

400
401
403
409
503

Verify sensitive backend internals are not surfaced.

======================================================================
STEP 35 — INTERCEPTOR TESTS
======================================================================

This section is mandatory.

Test:

1. Bearer token attached to protected request.
2. No token → no Authorization.
3. One 401 → one refresh → retry succeeds.
4. New rotated token pair is stored.
5. Retried request uses NEW access token.
6. Failed refresh clears tokens.
7. Failed refresh emits sessionExpired.
8. Retry marker prevents infinite loop.
9. Refresh endpoint itself never recursively refreshes.
10. Concurrent protected 401s share ONE refresh operation.
11. Waiting requests retry after same successful refresh.
12. Concurrent refresh failure clears session safely.

Use fake tokens only.

Do not print them.

======================================================================
STEP 36 — REPOSITORY TESTS
======================================================================

Test:

signup:
- stores returned pair;
- returns user.

login:
- stores returned pair;
- returns user.

restore:
- no tokens → unauthenticated;
- token + me success → authenticated;
- expired access + refresh success → authenticated;
- refresh failure → storage cleared.

logout:
- backend succeeds → cleared;
- backend unavailable → still cleared.

logoutAll:
- protected revoke requested;
- local storage cleared.

No real network/Atlas.

======================================================================
STEP 37 — AUTH CONTROLLER TESTS
======================================================================

Test:

startup restoration
unauthenticated startup
login success
login error
signup success
logout
logout-all
session-expired event
loading state behavior

No real secure storage or backend.

======================================================================
STEP 38 — ROUTER TESTS
======================================================================

Test routing behavior:

restoring → splash
unauthenticated → login
unauthenticated can open signup
authenticated → home
authenticated cannot remain on login/signup
logout redirects to login
restored session reaches home

Use provider overrides/fakes.

======================================================================
STEP 39 — WIDGET TESTS
======================================================================

Add practical widget tests:

Login:
- fields render;
- password obscured;
- link navigates to signup;
- validation;
- loading behavior;
- safe error display.

Signup:
- fields render;
- Customer/Cleaner selection;
- no Admin option;
- password rule;
- successful flow.

Authenticated home:
- safe email/role displayed;
- logout action;
- logout-all action.

Do not assert final styling.

======================================================================
STEP 40 — FLUTTER FORMAT / ANALYZE / TEST
======================================================================

From project/:

dart format lib test
flutter analyze
flutter test

All must pass.

Report exact final Flutter test count.

No blanket lint suppressions.

======================================================================
STEP 41 — ANDROID DEBUG BUILD
======================================================================

From project/ run:

flutter build apk --debug

This verifies:

- flutter_secure_storage native integration;
- Android manifest merge;
- debug network policy;
- Flutter compilation.

It must succeed.

Do not create a release build.

Do not modify signing configuration.

======================================================================
STEP 42 — BACKEND LIVE REGRESSION
======================================================================

Start Dart Frog only long enough for safe checks.

Verify:

GET /
GET /api/v1/health
GET /api/v1/ready

all succeed as before.

Do NOT create a disposable Atlas user just for TASK 012.

Do NOT POST signup against live Atlas automatically.

If ACCESS_TOKEN_SECRET is configured, merely report that auth runtime
configuration is available.

Protected endpoint behavior is verified through tests.

Stop server afterward.

======================================================================
STEP 43 — NO LIVE ACCOUNT FIXTURES
======================================================================

TASK 012 must not:

- create fake Atlas users;
- create fake Atlas sessions;
- delete existing users;
- dump user data.

Backend protected/account behavior is covered using fakes/mocks.

Manual user signup through the final Flutter application may be performed by
the developer later.

======================================================================
STEP 44 — SECURITY AUDIT
======================================================================

Review Flutter source for:

password
access_token
refresh_token
Authorization
secure storage

Confirm:

- no passwords persisted;
- no tokens logged;
- no token JSON printed;
- no Authorization header logged;
- no debug logger exposes credentials;
- tokens stored only through AuthTokenStorage;
- concrete storage uses FlutterSecureStorage;
- refresh is single-flight;
- refresh loops impossible;
- logout clears local tokens even on network error;
- session-expired clears credentials;
- Flutter contains no MONGODB_URI;
- Flutter contains no ACCESS_TOKEN_SECRET.

Review backend:

- protected principal created only after verified JWT;
- /account responses expose no password/token hashes;
- safe 401/403/503 behavior;
- no raw JWT exception exposed.

======================================================================
STEP 45 — DOCUMENT BACKEND PROTECTED AUTH
======================================================================

Create:

documentation/architecture/protected-api-authentication.md

Document:

- Bearer access JWT boundary;
- verified AuthenticatedPrincipal;
- protected account middleware;
- /account/me;
- /account/sessions;
- account-status behavior;
- 15-minute access-token revocation tradeoff;
- refresh-session revocation behavior;
- no access-token blacklist.

======================================================================
STEP 46 — DOCUMENT FLUTTER AUTH ARCHITECTURE
======================================================================

Create:

documentation/architecture/flutter-authentication.md

Document:

Flutter UI
   ↓
AuthController
   ↓
AuthRepository
   ↓
AuthApi
   ↓
Plain Dio / Authenticated Dio
   ↓
Dart Frog API

and:

Authenticated Dio
   ↓ 401
Single-flight refresh coordinator
   ↓
POST /auth/refresh using Plain Dio
   ↓
FlutterSecureStorage
   ↓
retry original request

Document:

- secure token pair storage;
- no JWT decoding for identity;
- `/account/me` authoritative;
- session restoration;
- automatic refresh;
- concurrency requirement;
- session-expiry event;
- logout behavior;
- routing guards.

======================================================================
STEP 47 — CREATE ADR-010
======================================================================

Create:

documentation/decisions/ADR-010-flutter-authentication-and-secure-session-storage.md

Sections:

# ADR-010 — Flutter Authentication and Secure Session Storage

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must include:

- flutter_secure_storage 11.0.0;
- token pair in secure platform storage;
- one JSON secure-storage entry;
- no passwords stored;
- separate plain/authenticated Dio clients;
- Bearer interceptor;
- single-flight rotating-token refresh;
- original request retry once;
- session-expiry event;
- backend /account/me session restoration;
- Riverpod auth state;
- go_router guards;
- debug-only local HTTP Android policy;
- production HTTPS.

Alternatives considered:

### SharedPreferences for tokens
Rejected.

### Decode JWT client-side and treat it as current user
Rejected.

### Refresh independently for every 401
Rejected because rotating refresh tokens make concurrent refresh unsafe.

### One Dio instance including refresh endpoint
Rejected because it increases recursion/interceptor complexity.

### Hard-coded localhost API
Rejected.

### Release cleartext HTTP
Rejected.

### Store password for silent login
Rejected.

Deferred:

- biometrics;
- device binding;
- certificate pinning;
- push notifications;
- offline account cache;
- final UI design;
- email verification;
- password reset;
- MFA;
- production rate limiting.

======================================================================
STEP 48 — UPDATE API DOCUMENTATION
======================================================================

Update:

documentation/api/authentication-api.md

Add protected authentication section for:

GET /api/v1/account/me
DELETE /api/v1/account/sessions

Document Authorization Bearer usage.

Do not include real tokens.

Update:

documentation/api/README.md
documentation/architecture/README.md
documentation/decisions/README.md
documentation/README.md
backend/README.md
project/README.md
README.md

only as necessary.

======================================================================
STEP 49 — LOCAL DEVELOPMENT DOCUMENTATION
======================================================================

Update setup docs with Android-emulator workflow:

Backend:

cd backend
dart_frog dev

Flutter:

cd project
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

Explain:

10.0.2.2
→ Android Emulator route to host machine

localhost inside emulator
→ emulator itself

The HTTP exception is DEBUG ONLY.

Production API must use HTTPS.

Document ACCESS_TOKEN_SECRET as backend-only configuration, but NEVER its
value.

======================================================================
STEP 50 — VERIFY NO UNAPPROVED CHANGES
======================================================================

Review:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm:

Backend:
- only protected-auth/current-account work plus tests/docs.

Flutter:
- auth/session vertical slice;
- one new dependency;
- debug-only Android HTTP config.

No:

bookings
cleaner profiles
payments
messages
reviews
service discovery
admin dashboard
MongoDB client in Flutter
AI features

======================================================================
STEP 51 — FINAL BACKEND VERIFICATION
======================================================================

From backend/:

dart analyze
dart test
dart_frog list

All pass.

Record exact backend test count.

Expected routes include exactly the previous routes plus:

/api/v1/account/me
/api/v1/account/sessions

No unintended routes.

======================================================================
STEP 52 — FINAL FLUTTER VERIFICATION
======================================================================

From project/:

flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug

All pass.

Record:

- flutter_secure_storage resolved version;
- test count;
- APK build result.

======================================================================
STEP 53 — FINAL SECRET / GIT CHECK
======================================================================

From repository root:

git check-ignore -v backend/.env
git status --short

Confirm:

backend/.env is ignored.

Do NOT print it.

Search Flutter source/docs for:

MONGODB_URI
ACCESS_TOKEN_SECRET
mongodb+srv://

There must be no secret/client database configuration.

A documentation sentence naming ACCESS_TOKEN_SECRET as a backend-only variable
is acceptable.

Do not expose its value.

======================================================================
STEP 54 — CREATE TASK 012 REPORT
======================================================================

Create:

documentation/cursor/012_protected_backend_and_flutter_auth_vertical_slice.md

Use:

documentation/cursor/task-report-template.md

The report MUST contain the COMPLETE EXACT TASK 012 prompt under:

## Exact Cursor Prompt

Document:

- clean checkpoint;
- backend baseline;
- Flutter baseline;
- backend protected principal/middleware;
- /account/me;
- /account/sessions;
- backend tests;
- flutter_secure_storage requested/resolved;
- token storage;
- plain/authenticated Dio separation;
- Bearer interceptor;
- single-flight refresh;
- refresh retry behavior;
- session-expiry behavior;
- AuthApi;
- AuthRepository;
- AuthController;
- router guards;
- screens;
- debug Android network policy;
- Flutter tests;
- backend final test count;
- Flutter final test count;
- analyze results;
- APK debug build;
- live non-mutating backend health check;
- security audit;
- Flutter secret audit;
- files created;
- files modified;
- files deleted;
- documentation;
- final Git status;
- unresolved issues.

Never include:

- backend/.env contents;
- ACCESS_TOKEN_SECRET value;
- MONGODB_URI;
- real passwords;
- real access tokens;
- real refresh tokens;
- real token hashes;
- real Atlas user/session documents.

======================================================================
STEP 55 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 012 entirely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond with exactly:

# TASK 012 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:
- Git root
- branch
- clean start
- latest commit
- backend baseline test count
- Flutter baseline test count
- ACCESS_TOKEN_SECRET configured yes/no without value
- backend/.env ignored

## Backend Protected Authentication

Describe:
- AuthenticatedPrincipal
- Bearer verification
- protected middleware
- safe failure behavior

## Protected Account API

Report:
- GET /api/v1/account/me
- DELETE /api/v1/account/sessions
- status behavior

## Backend Tests

Report exact backend test count and analyze result.

## Flutter Dependency

Report:
flutter_secure_storage requested/resolved

Confirm no other new direct package.

## Secure Token Storage

Describe one-entry secure token-pair storage and corruption handling.

## Flutter Networking

Describe:
- plain Dio
- authenticated Dio
- Bearer attachment
- no credential logging

## Single-Flight Refresh

Describe:
- concurrency protection
- rotating token replacement
- retry-once behavior
- refresh failure cleanup
- session-expiry signal

## Flutter Auth Repository

Describe:
signup
login
restoreSession
getCurrentUser
logout
logoutAll

## Authentication State

Describe AuthController and startup restoration.

## Routing

Describe splash/login/signup/home guards.

## Flutter Screens

Describe:
Splash
Login
Signup
Authenticated Home

## Android Development Networking

Describe debug-only HTTP policy and 10.0.2.2.

Confirm release/main configuration was not weakened.

## Flutter Tests

List test areas.

Report exact Flutter test count.

## Flutter Static Analysis

Report flutter analyze.

## Android Debug Build

Report flutter build apk --debug result.

## Backend Routes

Provide final dart_frog list.

## Live Verification

Report only non-mutating:
GET /
GET /health
GET /ready

Confirm no live signup/account fixtures were created.

## Files Created

List.

## Files Modified

List.

## Files Deleted

List.

## Documentation

Confirm:

documentation/architecture/protected-api-authentication.md
documentation/architecture/flutter-authentication.md
documentation/decisions/ADR-010-flutter-authentication-and-secure-session-storage.md
documentation/cursor/012_protected_backend_and_flutter_auth_vertical_slice.md

## Security Verification

Confirm:
- no password persisted;
- no tokens logged;
- no Authorization logging;
- secure storage only;
- no Mongo URI in Flutter;
- no ACCESS_TOKEN_SECRET in Flutter;
- refresh is single-flight;
- refresh loops prevented;
- logout clears local tokens;
- backend/.env ignored;
- no secret exposed.

## Git Status

Provide git status --short.

## Issues / Warnings

Report all issues.

## Final Statement

State whether the protected backend + Flutter authentication vertical slice is
complete and ready for ChatGPT review.

Do NOT implement marketplace/booking functionality.

Do NOT begin TASK 013.

Start TASK 012 now.
```

## Pre-Task Repository State

- Git root: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- Working tree: clean (TASK 011 committed)
- Latest commit: `a3fff2a` `uthentication_application_service_and_http_api`
- TASK 011 files present, including auth routes, `AuthenticationService`, and `documentation/cursor/011_authentication_application_service_and_http_api.md`
- `backend/.env` present and ignored (`.gitignore:8:.env`)
- ACCESS_TOKEN_SECRET configured: no (value never printed; live JWT issuance unavailable; tests use fakes). TASK 012 used `EnvironmentLoader` → `ServerConfig` from `backend/`. That path was correct; see TASK 012C.
- Pre-task backend `dart analyze`: no issues
- Pre-task backend `dart test`: 182 passed, 1 failed (`test/src/http/cors_test.dart` OPTIONS origin depended on production middleware loading the developer's private `.env`)
- Pre-task `dart_frog list`: `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/auth/login`, `/api/v1/auth/logout`, `/api/v1/auth/refresh`, `/api/v1/auth/signup`
- Pre-task Flutter `flutter analyze`: no issues
- Pre-task Flutter `flutter test`: 4 passed
- Baseline was not fully green because of the pre-existing CORS environment interaction. TASK 012 work continued; TASK 012C later isolated that test.

## Work Performed

1. Verified the TASK 011 checkpoint, `.env` ignore, and sanitized ACCESS_TOKEN_SECRET presence check.
2. Added `AuthenticatedPrincipal`, `AccessAuthenticator`, and generic 401 `invalid_access_token` mapping.
3. Added protected `/api/v1/account/` middleware, `CurrentAccountService`, `GET /account/me`, and `DELETE /account/sessions`.
4. Added backend fakes/mocks tests (no Atlas).
5. Added `flutter_secure_storage: 11.0.0` only.
6. Implemented Flutter token storage, AuthApi, plain/authenticated Dio, Bearer interceptor, single-flight refresh, session-expiry events, repository, controller, router guards, and screens.
7. Added debug-only Android cleartext policy for `10.0.2.2` / localhost / 127.0.0.1. Set `compileSdk = 37` because flutter_secure_storage 11.0.0 requires API 37. Did not change `minSdk` or application ID.
8. Added Flutter unit/widget/router tests.
9. Built debug APK successfully after a local SDK junction `android-37` -> `android-37.0` (Gradle looks for `android-37`; the SDK packaged the platform as `android-37.0`).
10. Live-checked only `GET /`, `GET /api/v1/health`, and `GET /api/v1/ready`. No live signup/account fixtures.
11. Documented protected API auth, Flutter auth, ADR-010, API docs, and this report.
12. Did not run git add, git commit, or git push.
13. TASK 012C: made CORS middleware tests inject explicit `ServerConfig` so they no longer load private `.env`; re-verified ACCESS_TOKEN_SECRET through `EnvironmentLoader` → `ServerConfig` from `backend/`.

## Files Created

- `backend/lib/src/features/account/application/account_composition.dart`
- `backend/lib/src/features/account/application/current_account_service.dart`
- `backend/lib/src/features/account/http/account_route_helpers.dart`
- `backend/lib/src/features/auth/http/access_authenticator.dart`
- `backend/lib/src/features/auth/http/authenticated_principal.dart`
- `backend/routes/api/v1/account/_middleware.dart`
- `backend/routes/api/v1/account/me.dart`
- `backend/routes/api/v1/account/sessions.dart`
- `backend/test/helpers/account_route_test_utils.dart`
- `backend/test/helpers/fake_current_account_service.dart`
- `backend/test/routes/api/v1/account/me_test.dart`
- `backend/test/routes/api/v1/account/sessions_test.dart`
- `backend/test/src/features/account/application/current_account_service_test.dart`
- `backend/test/src/features/auth/http/access_authenticator_test.dart`
- `backend/test/src/features/auth/http/account_middleware_test.dart`
- `documentation/architecture/protected-api-authentication.md`
- `documentation/architecture/flutter-authentication.md`
- `documentation/decisions/ADR-010-flutter-authentication-and-secure-session-storage.md`
- `documentation/cursor/012_protected_backend_and_flutter_auth_vertical_slice.md`
- `project/android/app/src/debug/res/xml/network_security_config.xml`
- `project/lib/core/network/auth_session_events.dart`
- `project/lib/features/auth/data/auth_api.dart`
- `project/lib/features/auth/data/auth_failure.dart`
- `project/lib/features/auth/data/auth_interceptor.dart`
- `project/lib/features/auth/data/auth_repository.dart`
- `project/lib/features/auth/data/auth_token_pair.dart`
- `project/lib/features/auth/data/auth_token_storage.dart`
- `project/lib/features/auth/data/flutter_secure_auth_token_storage.dart`
- `project/lib/features/auth/data/single_flight_refresher.dart`
- `project/lib/features/auth/domain/auth_session_state.dart`
- `project/lib/features/auth/domain/auth_user.dart`
- `project/lib/features/auth/presentation/auth_controller.dart`
- `project/lib/features/auth/presentation/auth_validation.dart`
- `project/lib/features/auth/presentation/authenticated_home_screen.dart`
- `project/lib/features/auth/presentation/login_screen.dart`
- `project/lib/features/auth/presentation/signup_screen.dart`
- `project/lib/features/auth/presentation/splash_screen.dart`
- `project/test/app/router/app_router_test.dart`
- `project/test/features/auth/data/auth_api_test.dart`
- `project/test/features/auth/data/auth_interceptor_test.dart`
- `project/test/features/auth/data/auth_repository_test.dart`
- `project/test/features/auth/data/auth_token_storage_test.dart`
- `project/test/features/auth/presentation/auth_controller_test.dart`
- `project/test/features/auth/presentation/authenticated_home_screen_test.dart`
- `project/test/features/auth/presentation/login_screen_test.dart`
- `project/test/features/auth/presentation/signup_screen_test.dart`
- `project/test/helpers/auth_test_fakes.dart`

## Files Modified

- `README.md`
- `backend/README.md`
- `backend/lib/src/features/auth/http/auth_http_errors.dart`
- `documentation/README.md`
- `documentation/api/README.md`
- `documentation/api/authentication-api.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/architecture/flutter-client-architecture.md`
- `documentation/decisions/README.md`
- `documentation/setup/README.md`
- `documentation/setup/development-environment.md`
- `project/README.md`
- `project/android/app/build.gradle.kts`
- `project/android/app/src/debug/AndroidManifest.xml`
- `project/lib/app/router/app_router.dart`
- `project/lib/app/router/app_routes.dart`
- `project/lib/core/network/dio_provider.dart`
- `project/pubspec.yaml`
- `project/pubspec.lock`
- `project/test/app/app_smoke_test.dart`
- `backend/routes/_middleware.dart` (TASK 012C test seam)
- `backend/test/src/http/cors_test.dart` (TASK 012C deterministic CORS tests)

## Files Deleted

- `project/lib/features/foundation/presentation/foundation_screen.dart`

## Commands Executed

- git rev-parse, branch, status, log
- git check-ignore -v backend/.env
- sanitized Dart check: ACCESS_TOKEN_SECRET configured yes/no (temporary script deleted)
- backend dart pub get, dart analyze, dart test, dart_frog list
- Flutter flutter pub get, flutter analyze, flutter test
- flutter pub add flutter_secure_storage:^11.0.0 (no flutter pub upgrade)
- dart format (backend and Flutter)
- flutter build apk --debug
- dart_frog dev --port 8099 (stopped afterward)
- GET /, /api/v1/health, /api/v1/ready

## Implementation Details

### Backend protected principal

`AccessAuthenticator` reads Authorization, requires Bearer, extracts the token, and verifies it through `AccessTokenService`. `AuthenticatedPrincipal` is created only after verification and contains `userId`, `sessionId`, `role`, and `jwtId`.

`routes/api/v1/account/_middleware.dart` authenticates every `/account` route, returns generic 401/503, then provides the principal and `CurrentAccountService`. Public `/health`, `/ready`, and `/auth/*` routes are unaffected. Health does not connect to Mongo merely because account middleware exists.

`CurrentAccountService.getCurrentUser` loads the persisted account. Missing user is an authentication failure. Suspended/deactivated accounts are 403 `account_unavailable`. `revokeAllSessions` uses `AuthSessionService.revokeAllForUser`.

### Flutter session

Token pair JSON is stored under one key `auth.token_pair` via `FlutterSecureAuthTokenStorage`. Corrupt JSON is cleared. Plain Dio handles signup/login/refresh/logout. Authenticated Dio attaches Bearer tokens and uses `SingleFlightRefresher` on 401. Refresh uses plain Dio. Retries set `extra['auth_retry']=true`. Refresh failure clears storage and emits `AuthSessionEvent.expired`.

`AuthController` restores once at startup. Router guards: restoring to splash; unauthenticated to login (signup allowed); authenticated to home.

## Technical Decisions

- flutter_secure_storage 11.0.0 only new direct Flutter dependency.
- One JSON secure-storage entry for the token pair.
- Separate plain and authenticated Dio clients.
- Cached Future for single-flight refresh (no mutex package).
- `/account/me` is authoritative; no JWT decoding in Flutter.
- Debug-only Android cleartext for local HTTP.
- compileSdk = 37 required by flutter_secure_storage 11.0.0; minSdk unchanged.

## Verification Performed

### TASK 012 (initial)

- Backend dart analyze: no issues (after deleting the temporary secret-check script)
- Backend dart test: 214 passed, 1 failed (`cors_test.dart` OPTIONS preflight; environment-dependent)
- dart_frog list: existing routes plus `/api/v1/account/me` and `/api/v1/account/sessions`
- Flutter analyze: no issues
- Flutter test: 65 passed
- flutter build apk --debug: succeeded
- Live non-mutating GET /, /api/v1/health, /api/v1/ready: HTTP 200
- git check-ignore -v backend/.env: ignored
- Flutter source search: no MONGODB_URI or mongodb+srv://; ACCESS_TOKEN_SECRET named only as a backend-only variable in README

### TASK 012C (correction)

- Focused `dart test test/src/http/cors_test.dart`: first reproduced the failure (expected `http://localhost:3000`, actual `null`); after isolation, all CORS tests passed without renaming/editing `.env`
- ACCESS_TOKEN_SECRET check from `backend/` using `EnvironmentLoader` → `ServerConfig`: configured **no** (value never printed; temporary script deleted)
- Focused EnvironmentLoader, ServerConfig, JwtAccessTokenService, and AuthenticationService tests: passed (fake secrets only)
- Backend dart format / dart analyze: no issues
- Backend dart test: **217 passed, 0 failed**
- dart_frog list: unchanged TASK 012 routes
- Flutter dart format / flutter analyze: no issues
- Flutter test: **65 passed**
- flutter build apk --debug: succeeded
- Live GET `/`, `/api/v1/health`, `/api/v1/ready`: HTTP 200; no auth endpoints invoked
- authentication runtime configuration available: **no**

### TASK 012D (final secret verification)

- From `backend/`, `EnvironmentLoader` → `ServerConfig`: ACCESS_TOKEN_SECRET configured: **no**
- Temporary verification script deleted
- `.env` was not modified
- Further TASK 012D regression (full suite, APK, live health) was not run because STEP 2 required STOP when the result is no

### TASK 012D-R (re-run after developer-corrected private .env)

- Developer independently corrected ignored `backend/.env` so `ACCESS_TOKEN_SECRET` is a standalone `KEY=` assignment. This task did not modify `.env`.
- From `backend/`, `EnvironmentLoader` → `ServerConfig`: ACCESS_TOKEN_SECRET configured: **yes** (value never printed; temporary script deleted)
- Backend dart format / dart analyze: no issues
- Backend dart test: **217 passed, 0 failed**
- dart_frog list: unchanged TASK 012 routes
- Flutter dart format / flutter analyze: no issues
- Flutter test: **65 passed**
- flutter build apk --debug: succeeded
- Live GET `/`, `/api/v1/health`, `/api/v1/ready`: HTTP 200; no auth/account endpoints invoked; no Atlas user/session fixtures
- authentication runtime configuration available: **yes**

## Verification Results

- flutter_secure_storage requested: ^11.0.0
- flutter_secure_storage resolved: 11.0.0
- No other new direct Flutter package
- flutter_riverpod 3.4.2, go_router 17.5.0, dio 5.11.0 unchanged except lockfile transitives from flutter_secure_storage
- ACCESS_TOKEN_SECRET configured: **yes** after TASK 012D-R using the real backend loader from `backend/`
- TASK 012 / 012C / 012D historically reported configured **no** because the private `.env` did not yet expose a standalone `ACCESS_TOKEN_SECRET` assignment. The loader path was already correct. The developer later corrected ignored `.env` formatting. This task did not modify `.env` and never printed the value.
- No live Atlas users/sessions created
- APK first attempt failed because Android SDK Platform 37 installed as folder android-37.0 while Gradle looks for android-37. A local junction was created; TASK 012C rebuild succeeded.

## TASK 012C CORS correction

The original CORS failure was an environment-dependent test-isolation issue, not a production CORS policy bug.

Root middleware caches `ServerConfig.fromEnvironment(EnvironmentLoader().load())`. The OPTIONS preflight test imported that production middleware, so it used the developer's ignored `.env`. Development localhost fallback only applies when `APP_ENV` is exactly `development` and `ALLOWED_ORIGINS` is empty. The private file did not satisfy that test fixture, so `Access-Control-Allow-Origin` was `null`.

TASK 012C added `resetMiddlewareCaches` so tests inject an explicit `ServerConfig`. Coverage now includes development localhost, a configured allowed origin, and a disallowed origin. Production middleware still loads environment configuration. `.env` was not changed.

## Errors / Warnings

- Initial TASK 012 backend suite: 214 passed, 1 failed (`cors_test.dart`). Corrected in TASK 012C; final suite is green.
- dart_frog dev non-TTY StdinException. Health/readiness were reachable; leftover listener was stopped afterward.
- Flutter/Gradle native-access warnings during APK build; build still succeeded.
- ACCESS_TOKEN_SECRET is still not a standalone loaded variable, so live JWT auth remains unavailable. Tests use fakes. The identifier is not a parsed env key; put `ACCESS_TOKEN_SECRET=<secret>` on its own line in ignored `backend/.env`. Do not paste the value into Git or docs.

Historical note: TASK 012D stopped here. TASK 012D-R confirmed the real loader now recognizes ACCESS_TOKEN_SECRET after the developer corrected private `.env` formatting. The value was never printed. `.env` was never modified by Cursor.

## Security / Secrets Check

- No passwords persisted in Flutter.
- No tokens logged or printed.
- No Authorization header logging.
- Tokens stored only through AuthTokenStorage / FlutterSecureStorage.
- Refresh is single-flight; retry-once marker prevents refresh loops.
- Logout always clears local tokens.
- Flutter contains no Mongo URI and no access-token secret value.
- backend/.env ignored.
- Temporary secret-check script deleted.
- No real tokens, hashes, or Atlas documents recorded.

## Git Diff Summary

Backend: protected Bearer authenticator, account middleware, /account/me, /account/sessions, tests, and docs.

Flutter: authentication vertical slice, flutter_secure_storage 11.0.0, debug-only Android HTTP policy, compileSdk 37, tests, and docs.

Documentation: protected API auth, Flutter auth, ADR-010, API updates, TASK 012 report.

No bookings, cleaner profiles, payments, messages, reviews, service discovery, admin dashboard, or MongoDB client in Flutter.

## Final Repository State

Uncommitted TASK 012 + TASK 012C + TASK 012D + TASK 012D-R work on main for ChatGPT review and checkpoint. Working tree dirty. No commit/push. CORS tests are deterministic. ACCESS_TOKEN_SECRET is recognized through the real runtime configuration path.

## Unresolved Issues

- dart_frog dev StdinException in this non-TTY environment remains an environment limitation.
- Local Android SDK 37 folder-name mismatch (android-37.0 vs android-37) is a machine SDK packaging issue; a junction was used so the debug APK could compile. It is not in Git.
- Email verification, password reset, MFA, biometrics, rate limiting, and marketplace features remain deferred.

## Suggested Next Step

A later task may add production rate limiting, email verification, or the first marketplace/service listing feature after ChatGPT reviews TASK 012. Do not implement that as part of this task.
