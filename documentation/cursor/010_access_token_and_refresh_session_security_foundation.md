# Cursor Task 010 — Access Token and Refresh Session Security Foundation

## Metadata

- Task ID: 010
- Task title: Access Token and Refresh Session Security Foundation
- Date: 2026-08-25 01:11 +06:00
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Establish access-token and refresh-session security primitives before signup, login, refresh, or logout: HS256 JWTs, opaque refresh tokens, UserSession persistence, atomic rotation, replay detection, session revocation, and user_sessions indexes. Do not add authentication HTTP routes, create live session documents, change Flutter, or commit.

## Exact Cursor Prompt

````text
# TASK 010 — Access Token and Refresh Session Security Foundation

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

TASK 009 established and checkpointed the password-security foundation.

The backend currently has:

GET /
GET /api/v1/health
GET /api/v1/ready

Existing relevant backend capabilities now include:

- MongoDB Atlas connectivity;
- UserAccount persistence;
- UserRole;
- AccountStatus;
- UserRepository / MongoUserRepository;
- normalized unique email;
- Argon2id password hashing;
- PasswordPolicy;
- PasswordHasher.

TASK 010 establishes access-token and refresh-session security BEFORE signup,
login, refresh, logout, or protected application endpoints are exposed.

This task must NOT implement authentication HTTP routes.

======================================================================
APPROVED TOKEN STRATEGY
======================================================================

Access tokens:

type:
signed JWT

library:
dart_jsonwebtoken: ^3.4.1

algorithm:
HS256

lifetime:
15 minutes

issuer:
home_cleaning_marketplace_api

audience:
home_cleaning_marketplace

Access tokens are intentionally short lived.

Refresh tokens:

type:
opaque cryptographically random token

entropy:
32 random bytes / 256 bits

encoding:
base64url without unnecessary padding

lifetime:
30 days absolute maximum per login/session

Refresh tokens are NOT JWTs.

Refresh tokens must NOT contain:

- user ID;
- email;
- role;
- session metadata;
- JSON;
- claims.

They are opaque secrets.

======================================================================
ACCESS TOKEN CLAIMS
======================================================================

Access JWTs should contain only the information necessary for authorization.

Required claims:

sub
→ UserAccount ObjectId represented as a string

sid
→ UserSession ObjectId represented as a string

role
→ explicit UserRole wire value

jti
→ cryptographically random token identifier

iss
→ home_cleaning_marketplace_api

aud
→ home_cleaning_marketplace

iat
→ issuance time

exp
→ issuance time + 15 minutes

Do NOT put into the access token:

- password hash;
- refresh token;
- refresh-token hash;
- email unless later justified;
- MongoDB URI;
- full profile;
- address;
- phone number;
- cleaner data;
- payment information.

Access JWT payloads are signed, NOT encrypted.

Do not place unnecessary personal information in them.

======================================================================
ACCESS TOKEN SIGNING SECRET
======================================================================

Server configuration variable:

ACCESS_TOKEN_SECRET

This secret belongs ONLY to the backend/server environment.

It must never enter Flutter source.

TASK 010 must add support for this configuration but must NOT require the user
to place a real value into backend/.env yet.

The backend must continue to start and serve:

GET /
GET /api/v1/health
GET /api/v1/ready

when ACCESS_TOKEN_SECRET is absent, because no authentication route uses the
token service yet.

The AccessTokenService itself must fail safely if constructed/used without a
valid secret.

Minimum accepted key material:

at least 32 UTF-8 bytes

This protects the HS256 256-bit key-size boundary.

Do not log the secret.

Do not include it in ServerConfig.toString.

Do not invent a default development secret.

======================================================================
REFRESH TOKEN STORAGE
======================================================================

The raw refresh token is returned only to the future client.

MongoDB must store only:

SHA-256(raw refresh token)

Use the already installed:

hashlib

package for hashing where appropriate.

Do NOT store the raw refresh token.

Do NOT encrypt and store the raw token.

Do NOT use the Argon2 password hasher for refresh tokens.

Refresh tokens already have high machine-generated entropy, so a deterministic
cryptographic hash is needed for lookup.

======================================================================
USER SESSION MODEL
======================================================================

Implement a MongoDB collection:

user_sessions

One document represents one logical login/device session.

Initial document shape:

{
  "_id": ObjectId,
  "user_id": ObjectId,
  "refresh_token_hash": String,
  "used_refresh_token_hashes": [String],
  "expires_at": DateTime,
  "revoked_at": DateTime?,
  "created_at": DateTime,
  "last_rotated_at": DateTime
}

Important:

A refresh-token rotation updates the SAME logical session document.

Do NOT create one database document for every token rotation.

This design enables atomic single-document token rotation and replay
detection without requiring a multi-document transaction.

All timestamps must be UTC.

======================================================================
REFRESH TOKEN ROTATION MODEL
======================================================================

For an active session:

current token hash:
refresh_token_hash

Previously consumed token hashes:
used_refresh_token_hashes

Successful rotation must conceptually perform one atomic MongoDB modification:

current refresh_token_hash
    ↓ move old hash into
used_refresh_token_hashes

new refresh_token_hash
    ↓ becomes
refresh_token_hash

last_rotated_at
    ↓ updated

The atomic query must require at minimum:

- expected current refresh_token_hash;
- revoked_at is null;
- expires_at is still in the future.

This ensures that two concurrent requests using the same current refresh token
cannot both successfully rotate it.

Only one atomic rotation may succeed.

======================================================================
REFRESH TOKEN REPLAY DETECTION
======================================================================

If an incoming refresh token hash no longer matches refresh_token_hash but
matches an entry in:

used_refresh_token_hashes

then that token was already consumed.

Treat this as refresh-token reuse/replay.

Required behavior:

- revoke the entire logical session;
- do not issue another refresh token;
- expose a stable internal exception/result such as
  RefreshTokenReuseDetectedException;
- do not expose database internals;
- do not reveal whether an attacker or legitimate client caused the replay.

No HTTP behavior is implemented yet.

Future routes will map this to a generic authentication failure.

======================================================================
SESSION EXPIRATION MODEL
======================================================================

A logical refresh session has an ABSOLUTE lifetime of:

30 days

Rotation does NOT extend:

expires_at

This prevents endless session extension.

A future explicit re-authentication creates a new session.

Inactive/sliding expiration may be considered later if justified.

======================================================================
SESSION REVOCATION MODEL
======================================================================

TASK 010 must support repository/service primitives for:

- revoke one logical session;
- revoke a session presented through its current refresh token;
- revoke all sessions for one user.

This prepares for:

- logout;
- logout-all-devices;
- password/security events;
- account suspension.

No route invokes them in TASK 010.

Already-issued access JWTs are NOT placed in a denylist in TASK 010.

After refresh-session revocation, an already-issued access token may remain
valid until its maximum 15-minute expiration.

Document this tradeoff explicitly.

Do not create an access-token blacklist yet.

======================================================================
PURPOSE OF TASK 010
======================================================================

TASK 010 must:

1. verify TASK 009 was committed and repository starts clean;
2. verify current backend tests/analyze/routes;
3. install only dart_jsonwebtoken 3.4.1;
4. extend safe server configuration with ACCESS_TOKEN_SECRET;
5. implement access-token claims model;
6. implement HS256 access-token issuance;
7. implement strict access-token verification;
8. implement secure JWT identifier generation;
9. implement opaque refresh-token generation;
10. implement deterministic refresh-token hashing;
11. create UserSession persistence model;
12. create UserSessionRepository;
13. create MongoUserSessionRepository;
14. implement atomic refresh-token rotation;
15. implement refresh-token replay detection primitives;
16. implement session revocation primitives;
17. create user_sessions indexes;
18. safely ensure those indexes on Atlas;
19. add comprehensive tests without creating real Atlas session records;
20. make no authentication routes;
21. make no user/session data mutations on live Atlas;
22. preserve all existing routes;
23. document token/session architecture;
24. run formatting, analysis, tests, and health checks;
25. verify Flutter remains unchanged;
26. create TASK 010 report;
27. leave everything uncommitted for ChatGPT review.

======================================================================
STRICT SAFETY RULES
======================================================================

For TASK 010:

1. Do NOT implement signup.
2. Do NOT implement login.
3. Do NOT implement logout HTTP endpoint.
4. Do NOT implement refresh HTTP endpoint.
5. Do NOT implement auth middleware.
6. Do NOT implement protected routes.
7. Do NOT implement password recovery.
8. Do NOT create actual users.
9. Do NOT create actual user-session documents on Atlas.
10. Do NOT insert session test records into live Atlas.
11. Do NOT update real Atlas session records.
12. Do NOT delete real Atlas session records.
13. Do NOT enumerate session documents.
14. Do NOT enumerate user documents.
15. Do NOT store raw refresh tokens.
16. Do NOT log raw refresh tokens.
17. Do NOT log refresh-token hashes.
18. Do NOT log JWTs.
19. Do NOT log ACCESS_TOKEN_SECRET.
20. Do NOT place ACCESS_TOKEN_SECRET in Flutter.
21. Do NOT put a real ACCESS_TOKEN_SECRET in .env.example.
22. Do NOT create a default signing secret.
23. Do NOT add JWT refresh tokens.
24. Do NOT use access JWTs as refresh tokens.
25. Do NOT create an access-token denylist.
26. Do NOT implement OAuth social login.
27. Do NOT implement MFA.
28. Do NOT implement rate limiting yet.
29. Do NOT change password-security parameters.
30. Do NOT change UserAccount persistence shape.
31. Do NOT modify the users unique-email index.
32. Do NOT create speculative device-fingerprinting fields.
33. Do NOT store IP addresses.
34. Do NOT store user-agent strings yet.
35. Do NOT add packages except the approved JWT dependency.
36. Do NOT modify Flutter.
37. Do NOT modify Flutter dependencies.
38. Do NOT change native identifiers.
39. Do NOT stage.
40. Do NOT commit.
41. Do NOT push.
42. Do NOT modify historical TASK 001–009 reports.
43. Do NOT make unrelated changes.

The only permitted live Atlas mutation is ensuring the approved user_sessions
indexes.

No session documents may be created.

======================================================================
STEP 1 — VERIFY CLEAN CHECKPOINT
======================================================================

From repository root run:

git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -9 --oneline

Expected:

Git root:
D:\freelance\erfankhan_cse489\final

Branch:
main

Working tree:
clean

backend/.env may exist but remains ignored.

Verify:

backend/pubspec.yaml
backend/pubspec.lock
backend/lib/src/config/server_config.dart
backend/lib/src/database/database_indexes.dart
backend/lib/src/database/collection_names.dart
backend/lib/src/features/users/domain/user_account.dart
backend/lib/src/features/auth/security/password_hasher.dart
backend/lib/src/features/auth/security/argon2id_password_hasher.dart
backend/routes/api/v1/health.dart
backend/routes/api/v1/ready.dart
documentation/cursor/009_password_security_foundation.md

Also verify:

git check-ignore -v backend/.env

Do NOT print backend/.env.

If working tree is not clean:

STOP.

Do not modify anything.

======================================================================
STEP 2 — PRE-TASK HEALTH
======================================================================

From backend/ run:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

dart analyze
→ no issues

dart test
→ 80 tests pass

Routes:

/
/api/v1/health
/api/v1/ready

If baseline fails:

STOP.

Report without unrelated repairs.

======================================================================
STEP 3 — INSTALL ONLY JWT PACKAGE
======================================================================

From backend/ run:

dart pub add "dart_jsonwebtoken:^3.4.1"

Do NOT run:

dart pub upgrade

Do NOT add:

uuid
crypto
random packages
session packages
oauth packages
jose
jwt_decoder
secure-storage packages

The existing hashlib dependency supplies hashing and secure random utilities
needed for refresh-token primitives.

Inspect:

backend/pubspec.yaml
backend/pubspec.lock

Record requested/resolved dart_jsonwebtoken version.

Confirm it is the only new direct dependency.

======================================================================
STEP 4 — INSPECT JWT PACKAGE API
======================================================================

Inspect the installed dart_jsonwebtoken 3.4.1 API/source only enough to verify:

- HS256 signing;
- explicit signing algorithm selection;
- signature verification;
- expiry verification;
- issuer behavior;
- audience behavior;
- JWT exception types;
- access to the verified payload.

Do not copy large dependency source sections.

Do not modify dependency source.

Do not rely on unverified JWT.decode payloads for authorization.

All trusted claims must come from a successfully verified token.

======================================================================
STEP 5 — EXTEND SERVER CONFIGURATION SAFELY
======================================================================

Update:

backend/lib/src/config/server_config.dart

Add:

ACCESS_TOKEN_SECRET

Expose something conceptually like:

accessTokenSecret
hasAccessTokenSecret

Do NOT provide a default secret.

Do NOT include the secret in:

toString
debug output
logs
exceptions

The backend must still start when the variable is absent.

Token-service construction/use can reject missing configuration.

Update ServerConfig tests.

Use fake test secrets only.

======================================================================
STEP 6 — UPDATE SAFE ENV TEMPLATE
======================================================================

Update:

backend/.env.example

Add only a placeholder:

ACCESS_TOKEN_SECRET=<replace-with-a-strong-random-secret>

or equivalent clearly non-real placeholder.

Do not generate or include a real secret.

Do not inspect/print backend/.env.

TASK 010 does NOT require modifying the developer's private backend/.env.

======================================================================
STEP 7 — CREATE ACCESS TOKEN CLAIM MODEL
======================================================================

Create an auth token area such as:

backend/lib/src/features/auth/tokens/

Create a small immutable model:

AccessTokenClaims

Containing:

ObjectId userId
ObjectId sessionId
UserRole role
String jwtId
DateTime issuedAt
DateTime expiresAt

Do not duplicate password/account/profile data.

If issuer/audience are treated as service-level constants rather than model
fields, that is preferred.

Provide safe parsing from a VERIFIED JWT payload.

Required type/parsing failures must fail predictably.

Do not silently default an unknown role to customer.

======================================================================
STEP 8 — ACCESS TOKEN SERVICE ABSTRACTION
======================================================================

Create a small abstraction such as:

AccessTokenService

Required conceptual operations:

issue(...)
verify(...)

issue requires:

userId
sessionId
role

verify returns either:

AccessTokenClaims

or a clear internal invalid-token result/exception.

Choose one coherent contract.

Future route/auth middleware should not directly call dart_jsonwebtoken APIs.

======================================================================
STEP 9 — HS256 ACCESS TOKEN IMPLEMENTATION
======================================================================

Create a Dart JWT implementation such as:

JwtAccessTokenService

Use:

HS256 ONLY

Explicitly specify HS256 during signing.

Do not rely solely on a package default.

Signing secret:

ACCESS_TOKEN_SECRET

Minimum:

32 UTF-8 bytes

Reject missing/short secrets with a sanitized configuration exception.

Do not include the secret in the exception.

Access lifetime:

15 minutes

Issuer:

home_cleaning_marketplace_api

Audience:

home_cleaning_marketplace

======================================================================
STEP 10 — JWT IDENTIFIER
======================================================================

Generate:

jti

using at least:

16 cryptographically secure random bytes

Encode using base64url without unnecessary padding.

Use secure random functionality already available through hashlib/Dart secure
RNG.

Do NOT derive jti from:

userId
sessionId
timestamp
email

Do not log jti unnecessarily.

======================================================================
STEP 11 — JWT CLAIMS
======================================================================

The signed token must contain:

sub
sid
role
jti
iat
exp
iss
aud

Use standard JWT registered claims where supported by the package.

Do not duplicate a standard claim under multiple custom names.

Do not include:

email
password data
refresh data
profile data

======================================================================
STEP 12 — STRICT JWT VERIFICATION
======================================================================

Verification must validate:

- signature;
- exact HS256 algorithm;
- expiration;
- issuer;
- audience;
- required claims;
- ObjectId syntax for sub;
- ObjectId syntax for sid;
- valid UserRole wire value;
- sensible timestamp types.

Reject:

- expired tokens;
- wrong signature;
- malformed tokens;
- wrong issuer;
- wrong audience;
- unsupported/wrong algorithm;
- missing required claims;
- invalid ObjectIds;
- unknown roles.

Do NOT trust claims obtained only through JWT.decode.

If the package's verify API accepts multiple HMAC algorithms with SecretKey,
explicitly protect against algorithm substitution so only HS256 is accepted.

Inspect the JOSE header only for algorithm-selection safety; do not trust JWT
payload claims until signature verification succeeds.

Do not expose raw package exceptions to future HTTP clients.

======================================================================
STEP 13 — ACCESS TOKEN TESTS
======================================================================

Use fake secrets only.

Test at minimum:

- valid token issues and verifies;
- claims round-trip correctly;
- lifetime is approximately 15 minutes;
- correct issuer;
- correct audience;
- HS256 used;
- unique jti values;
- wrong secret rejected;
- expired token rejected;
- wrong issuer rejected;
- wrong audience rejected;
- malformed token rejected;
- missing required claim rejected;
- malformed user ObjectId rejected;
- malformed session ObjectId rejected;
- unknown role rejected;
- non-HS256 token rejected;
- missing secret rejected;
- short secret rejected.

Do not print JWTs in tests.

======================================================================
STEP 14 — REFRESH TOKEN PRIMITIVE
======================================================================

Create a focused abstraction/implementation for opaque refresh tokens.

Example:

RefreshTokenGenerator

Production generation:

32 cryptographically secure random bytes

Output:

base64url string without padding

The raw output must carry no structured metadata.

Create:

hashToken(rawToken)

using SHA-256 via hashlib.

The resulting storage hash should have one consistent representation, for
example lowercase hexadecimal.

Choose one and test it.

Do NOT use password Argon2 for refresh-token lookup hashes.

======================================================================
STEP 15 — REFRESH TOKEN TESTS
======================================================================

Test:

- generated token is non-empty;
- decoded entropy payload is 32 bytes;
- multiple generations differ;
- output contains no JSON/user/session content;
- same raw token always hashes identically;
- different raw tokens produce different hashes;
- hash has expected SHA-256 representation length/format;
- raw token is not equal to stored hash.

Do not attempt statistical RNG certification.

======================================================================
STEP 16 — ADD COLLECTION NAME
======================================================================

Update:

backend/lib/src/database/collection_names.dart

Add only:

userSessions = 'user_sessions'

Preserve:

users

Do not add future collection names.

======================================================================
STEP 17 — CREATE USERSESSION DOMAIN MODEL
======================================================================

Create a feature area such as:

backend/lib/src/features/auth/sessions/

Create persisted:

UserSession

Fields:

ObjectId id
ObjectId userId
String refreshTokenHash
List<String> usedRefreshTokenHashes
DateTime expiresAt
DateTime? revokedAt
DateTime createdAt
DateTime lastRotatedAt

All timestamps UTC.

Provide explicit MongoDB BSON/document serialization.

Critical missing/wrong types must fail predictably.

Do NOT expose raw tokens.

If a public/debug serialization exists, it must not expose:

refreshTokenHash
usedRefreshTokenHashes

Prefer no public serialization until a real API requires one.

toString must not expose token hashes.

======================================================================
STEP 18 — SESSION CREATION INPUT
======================================================================

If helpful, create:

CreateUserSessionData

containing only values required by the repository/service.

The repository should derive:

_id
created_at

where appropriate.

No raw refresh token should enter Mongo persistence abstractions.

Persistence accepts only refresh-token hashes.

======================================================================
STEP 19 — SESSION REPOSITORY CONTRACT
======================================================================

Create:

UserSessionRepository

Keep the API narrow.

Required conceptual operations:

create(...)
findById(...)
findByCurrentRefreshTokenHash(...)
findByUsedRefreshTokenHash(...)
rotateCurrentTokenAtomically(...)
revokeById(...)
revokeAllForUser(...)

Do NOT add:

listAllSessions
admin session search
device history
IP search
user-agent operations

yet.

======================================================================
STEP 20 — MONGODB SESSION REPOSITORY
======================================================================

Create:

MongoUserSessionRepository

Use a narrow Mongo document-store seam if needed for tests, similar in spirit
to TASK 008's UserDocumentStore.

Do not create a giant generic database abstraction.

The repository receives Db/collection dependencies.

It must NOT:

- read environment variables;
- construct MongoDatabase;
- generate raw refresh tokens;
- create JWTs.

======================================================================
STEP 21 — ATOMIC TOKEN ROTATION
======================================================================

Implement repository-level atomic rotation.

Conceptual input:

currentRefreshTokenHash
newRefreshTokenHash
now

Atomic MongoDB query must match:

refresh_token_hash == currentRefreshTokenHash
revoked_at == null
expires_at > now

Atomic update must:

$set refresh_token_hash = newRefreshTokenHash
$set last_rotated_at = now
$push used_refresh_token_hashes = currentRefreshTokenHash

Return the updated session when successful.

If nothing matches:

return null / explicit unsuccessful result.

Use MongoDB findAndModify/findOneAndUpdate semantics appropriate to the actual
mongo_dart 0.10.9 API.

Inspect the current driver API instead of guessing method names.

Do NOT implement rotation as:

find
then update

because that has a race.

The compare-and-modify must be atomic.

======================================================================
STEP 22 — SESSION SECURITY SERVICE
======================================================================

Create a higher-level session service, e.g.:

AuthSessionService

Responsibilities:

createSession(userId)
rotateRefreshToken(rawRefreshToken)
revokeSession(rawRefreshToken)
revokeAllForUser(userId)

It composes:

RefreshTokenGenerator
UserSessionRepository

It must not depend on Dart Frog request objects.

======================================================================
STEP 23 — INITIAL SESSION CREATION
======================================================================

createSession must:

1. generate a raw opaque refresh token;
2. hash it;
3. create one UserSession;
4. set:
   createdAt = UTC now
   lastRotatedAt = UTC now
   expiresAt = UTC now + 30 days
   revokedAt = null
   usedRefreshTokenHashes = []
5. return the raw refresh token only to the caller together with safe session
   identity information.

The repository receives only the hash.

TASK 010 tests use fakes.

Do NOT call this against live Atlas.

======================================================================
STEP 24 — REFRESH ROTATION SERVICE
======================================================================

rotateRefreshToken(rawToken) must:

1. hash the presented raw token;
2. generate a new raw token;
3. hash the new raw token;
4. request atomic rotation from the repository;
5. if rotation succeeds:
   return the NEW raw refresh token and session;
6. never return the old token again.

expiresAt must NOT be extended.

The 30-day absolute session lifetime remains unchanged.

======================================================================
STEP 25 — REPLAY DETECTION
======================================================================

If atomic rotation fails:

Check whether the presented hash appears in:

used_refresh_token_hashes

for a logical session.

If yes:

- treat as token reuse;
- revoke that session;
- throw/return RefreshTokenReuseDetectedException or equivalent;
- do not issue a token.

If it matches neither an active current hash nor a used hash:

return/throw a generic invalid-refresh-token result.

If it belongs to an expired/revoked session:

also fail generically.

Do not expose these distinctions to a future unauthenticated HTTP client.

The internal distinction exists so replay can trigger revocation.

======================================================================
STEP 26 — CONCURRENT ROTATION TEST
======================================================================

The repository/service tests must demonstrate that two concurrent attempts to
rotate the SAME current token cannot both succeed.

Use a fake atomic store or Mongo repository seam.

Expected conceptual behavior:

request A → succeeds with new token
request B → cannot also consume the original token

If B observes the old token in used hashes:

replay behavior should revoke the session.

Do not use live Atlas for this test.

======================================================================
STEP 27 — REVOCATION
======================================================================

Implement repository/service primitives:

revokeById
revokeAllForUser

Revocation sets:

revoked_at = UTC now

Do not delete session records merely to revoke them.

This preserves refresh-token replay information until expiration.

Calling revoke on an already-revoked session should be safe/idempotent where
practical.

======================================================================
STEP 28 — USER SESSION INDEXES
======================================================================

Add approved indexes for:

user_sessions

1. Current refresh-token lookup:

name:
user_sessions_refresh_token_hash_unique

key:
refresh_token_hash: 1

unique:
true

2. Used token replay lookup:

name:
user_sessions_used_refresh_token_hashes

key:
used_refresh_token_hashes: 1

3. User-session revocation lookup:

name:
user_sessions_user_id

key:
user_id: 1

4. Expiration cleanup:

name:
user_sessions_expires_at_ttl

key:
expires_at: 1

expireAfterSeconds:
0

Do not add speculative indexes.

The TTL index is cleanup only.

Application code must STILL check expires_at because MongoDB TTL removal is
not instantaneous.

======================================================================
STEP 29 — INDEX INITIALIZATION
======================================================================

Integrate user-session indexes with the existing deliberate:

backend/tool/ensure_database_indexes.dart

and database-index initialization architecture.

Do NOT ensure indexes per request.

Running the tool is authorized.

It may create/ensure the user_sessions collection/index metadata.

It must NOT insert session documents.

Live Atlas mutation in TASK 010 is limited to these index definitions.

======================================================================
STEP 30 — SESSION INDEX TESTS
======================================================================

Without Atlas, verify specifications:

user_sessions_refresh_token_hash_unique
→ refresh_token_hash ascending
→ unique

user_sessions_used_refresh_token_hashes
→ used_refresh_token_hashes ascending

user_sessions_user_id
→ user_id ascending

user_sessions_expires_at_ttl
→ expires_at ascending
→ expireAfterSeconds 0

Preserve the users email index tests.

======================================================================
STEP 31 — LIVE INDEX ENSURE
======================================================================

Only after:

dart analyze passes
dart test passes

run:

dart run tool/ensure_database_indexes.dart

Use the ignored backend/.env indirectly.

Never print it.

Verify only sanitized index metadata.

Permitted live mutations:

ensure the four approved user_sessions indexes.

No documents.

If index creation fails:

- do not drop indexes automatically;
- do not delete data;
- do not weaken Atlas security;
- report a sanitized failure;
- mark TASK 010 PARTIAL if necessary.

======================================================================
STEP 32 — DO NOT CREATE LIVE SESSION DATA
======================================================================

Verify the live index tool:

- does not call AuthSessionService.createSession;
- does not call UserSessionRepository.create for sample data;
- performs index management only.

Do not count/dump user_sessions documents merely to prove this.

======================================================================
STEP 33 — ACCESS TOKEN REVOCATION TRADEOFF
======================================================================

Document explicitly:

Revoking a UserSession prevents future refreshes.

A previously issued access JWT remains cryptographically valid until its
15-minute exp time unless future authorization architecture adds an immediate
revocation/status check.

This is an intentional short-lived-JWT tradeoff.

Do NOT implement:

JWT blacklist
access-token collection
access-token revocation endpoint

in TASK 010.

======================================================================
STEP 34 — SERVER CONFIG TESTS
======================================================================

Extend ServerConfig tests:

- ACCESS_TOKEN_SECRET absent;
- ACCESS_TOKEN_SECRET provided;
- toString does not expose it;
- existing APP_ENV / ALLOWED_ORIGINS / MONGODB_URI behavior remains valid.

Use fake secret material only.

======================================================================
STEP 35 — SESSION MODEL TESTS
======================================================================

Test:

- BSON round trip;
- ObjectIds;
- UTC timestamps;
- empty used-token list;
- rotated used-token list;
- revoked timestamp;
- wrong required types;
- missing required fields;
- debug representation does not expose token hashes.

Use fake hashes only.

======================================================================
STEP 36 — SESSION REPOSITORY TESTS
======================================================================

Test without Atlas:

- create stores only token hash;
- find by current hash;
- find by used hash;
- active atomic rotation;
- old hash moved to used list;
- new hash becomes current;
- expiration unchanged;
- rotation rejected after revoke;
- rotation rejected after expiry;
- revoke by ID;
- revoke all for user;
- duplicate/current hash behavior where relevant.

Use fakes/mocks.

Do not add another mocking package.

======================================================================
STEP 37 — SESSION SERVICE TESTS
======================================================================

Test:

- initial session returns raw refresh token but repository receives hash only;
- absolute expiry = approximately 30 days;
- rotation returns a different raw token;
- previous raw token is never returned;
- expiry does not extend during rotation;
- raw token never enters persistence document;
- replay of consumed token triggers revocation;
- unknown token fails generically;
- revoked token fails;
- expired token fails;
- revoke is safe;
- revoke-all delegates correctly.

No Atlas.

======================================================================
STEP 38 — NO AUTH HTTP ROUTES
======================================================================

Run:

dart_frog list

Expected routes remain EXACTLY:

/
/api/v1/health
/api/v1/ready

There must be no:

/auth
/login
/signup
/register
/refresh
/logout
/sessions
/users

route.

======================================================================
STEP 39 — FORMAT
======================================================================

From backend/:

dart format .

======================================================================
STEP 40 — STATIC ANALYSIS
======================================================================

Run:

dart analyze

Must report no issues.

Do not suppress token/security warnings.

======================================================================
STEP 41 — TEST SUITE
======================================================================

Run:

dart test

All tests must pass.

Report exact final count.

Tests must not contact Atlas.

======================================================================
STEP 42 — HEALTH REGRESSION
======================================================================

If practical start Dart Frog long enough to verify:

GET /api/v1/health
→ 200

GET /api/v1/ready
→ 200

The backend must not require ACCESS_TOKEN_SECRET simply to start because no
authentication route is active.

Stop the server afterward.

Report the known non-TTY warning accurately if it recurs.

======================================================================
STEP 43 — SECURITY AUDIT
======================================================================

Review new source for:

token
secret
refresh
hash
jwt

Verify:

- ACCESS_TOKEN_SECRET never logged;
- no default secret;
- fake secrets only in tests;
- raw refresh tokens never persisted;
- raw refresh tokens never logged;
- refresh hashes never returned to clients;
- JWTs never logged;
- JWT payload contains no password/profile data;
- JWT verification requires signature;
- JWT verification requires exact HS256;
- issuer/audience/expiry are checked;
- token identifiers use secure randomness;
- replay detection revokes the logical session;
- used token hashes are retained until session expiration;
- session rotation is atomic;
- backend/.env remains ignored.

Do not print backend/.env.

======================================================================
STEP 44 — FLUTTER VERIFICATION
======================================================================

From repository root:

git diff -- project/

Expected:

empty.

Do not add secure storage to Flutter yet.

Do not modify API_BASE_URL.

======================================================================
STEP 45 — DOCUMENT SESSION COLLECTION
======================================================================

Create:

documentation/database/user-sessions-collection.md

Document:

Purpose

Document fields:

_id
user_id
refresh_token_hash
used_refresh_token_hashes
expires_at
revoked_at
created_at
last_rotated_at

Explain:

- only hashes stored;
- raw refresh token never stored;
- same logical session document rotates;
- used hashes detect replay;
- 30-day absolute expiry;
- revocation;
- TTL cleanup;
- indexes.

Do not include real token/hash examples.

======================================================================
STEP 46 — DOCUMENT TOKEN/SESSION ARCHITECTURE
======================================================================

Create:

documentation/architecture/auth-token-and-session-security.md

Document:

Access tokens:
- signed JWT;
- HS256;
- 15 minutes;
- claims;
- strict verification;
- ACCESS_TOKEN_SECRET backend-only.

Refresh tokens:
- opaque;
- 256 bits;
- secure random;
- SHA-256 stored hash;
- never JWT;
- never persisted raw.

Rotation:
- atomic single-document replacement;
- old hashes retained;
- replay detection;
- revocation on reuse.

Sessions:
- 30-day absolute lifetime;
- revocation;
- TTL cleanup.

Security tradeoff:
- revoked refresh session stops new access tokens;
- already-issued access token can remain valid for at most 15 minutes.

Current state:
- no auth endpoints yet.

======================================================================
STEP 47 — CREATE ADR-008
======================================================================

Create:

documentation/decisions/ADR-008-access-and-refresh-token-strategy.md

Use:

# ADR-008 — Access and Refresh Token Strategy

## Status
## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Status:

Accepted

Decision:

- dart_jsonwebtoken 3.4.1;
- HS256 access JWT;
- backend ACCESS_TOKEN_SECRET;
- 15-minute access lifetime;
- minimal claims;
- opaque 256-bit refresh tokens;
- SHA-256 refresh-token storage hashes;
- user_sessions persistence;
- 30-day absolute session lifetime;
- atomic same-document rotation;
- used-token-hash replay detection;
- session revocation;
- TTL cleanup.

Alternatives Considered:

### Long-lived access JWT

Rejected because compromise impact lasts too long.

### JWT refresh tokens

Rejected because opaque server-tracked tokens provide straightforward
revocation and rotation/replay state.

### Store raw refresh token

Rejected because a database leak would expose immediately usable credentials.

### Argon2 refresh-token hashing

Not selected because refresh tokens are high-entropy random machine-generated
secrets and require deterministic lookup; SHA-256 is appropriate for this
storage lookup boundary.

### New database document for every rotation

Not selected because same-session atomic replacement gives simpler
concurrency control and replay detection without a multi-document transaction.

### Access-token blacklist

Deferred because short-lived JWTs limit exposure and a blacklist adds state to
every access-token check.

### Asymmetric JWT signing

Viable for multi-service/public-key architectures, but HS256 is appropriate
for the current single trusted backend. Reevaluate if architecture becomes
multi-service.

Consequences:

- refresh requests require MongoDB session lookup;
- access-token validation can remain cryptographic/stateless;
- refresh replay can revoke sessions;
- logout cannot retroactively erase a JWT already issued;
- already-issued JWT lifetime is bounded to 15 minutes;
- signing-secret management becomes a deployment responsibility.

Deferred:

- signup;
- login;
- refresh/logout routes;
- authentication middleware;
- Flutter secure token storage;
- immediate access-token revocation;
- asymmetric signing;
- key rotation;
- MFA;
- rate limiting;
- compromised-password screening.

======================================================================
STEP 48 — UPDATE DOCUMENTATION INDEXES
======================================================================

Update only as needed:

documentation/README.md
documentation/architecture/README.md
documentation/database/README.md
documentation/decisions/README.md
documentation/architecture/backend-api-architecture.md
documentation/setup/README.md
backend/README.md
backend/.env.example

Add references to the new session/token docs.

State accurately:

- token/session primitives exist;
- no signup/login/refresh/logout routes exist yet.

======================================================================
STEP 49 — REVIEW EXACT CHANGES
======================================================================

Run:

git status --short
git diff -- backend/pubspec.yaml
git diff -- backend/pubspec.lock
git diff -- backend/lib/
git diff -- backend/test/
git diff -- backend/tool/
git diff -- backend/routes/
git diff -- project/
git diff -- documentation/
git diff -- backend/.env.example
git diff -- backend/README.md

Confirm:

- only dart_jsonwebtoken is a new direct dependency;
- no routes changed;
- Flutter unchanged;
- no real secret;
- no real sessions;
- no user data changes.

Inspect new untracked files directly.

Never print backend/.env.

======================================================================
STEP 50 — CREATE TASK 010 REPORT
======================================================================

Create:

documentation/cursor/010_access_token_and_refresh_session_security_foundation.md

using:

documentation/cursor/task-report-template.md

The report MUST contain the COMPLETE EXACT TASK 010 prompt under:

## Exact Cursor Prompt

Document:

- clean starting checkpoint;
- pre-task tests/analyze/routes;
- dependency requested/resolved;
- JWT package API inspection;
- access-token claims;
- HS256 issuance;
- strict verification;
- secret configuration;
- jti generation;
- refresh-token generation;
- refresh-token hashing;
- UserSession model;
- repository;
- Mongo implementation;
- atomic rotation;
- replay detection;
- revocation;
- indexes;
- live index ensure;
- explicit confirmation no session documents were created;
- tests;
- exact final test count;
- analysis;
- routes;
- health/readiness regression;
- database safety;
- Flutter no-change verification;
- files created;
- files modified;
- files deleted;
- documentation;
- security audit;
- final Git status;
- unresolved issues.

Never include:

- ACCESS_TOKEN_SECRET;
- backend/.env;
- MONGODB_URI;
- raw refresh tokens;
- real JWTs;
- refresh-token hashes from real users;
- real session documents.

======================================================================
STEP 51 — FINAL VERIFICATION
======================================================================

From backend/ run again:

dart analyze
dart test
dart_frog list

From repository root:

git status --short
git diff -- project/
git check-ignore -v backend/.env

Expected routes:

/
/api/v1/health
/api/v1/ready

All tests must pass.

======================================================================
STEP 52 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 010 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond with exactly these top-level sections:

# TASK 010 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:

- Git root
- branch
- starting Git state
- latest commit
- pre-task analysis
- pre-task test count
- pre-task routes
- backend/.env ignore state

## Dependency Added

Report requested/resolved:

dart_jsonwebtoken

Confirm no unrelated direct package.

## Access Token

Report:

- algorithm
- lifetime
- issuer
- audience
- claims
- jti generation
- secret requirements

Never report the secret.

## Access Token Verification

Report strict validation behavior, including exact algorithm enforcement.

## Refresh Token

Report:

- randomness
- entropy
- encoding
- hashing/storage behavior

## User Session Model

Describe persisted fields and 30-day absolute lifetime.

## Atomic Rotation

Describe the compare-and-modify behavior and concurrent-rotation protection.

## Replay Detection

Describe used-token detection and revocation behavior.

## Session Revocation

Describe one-session and all-user-session revocation primitives.

## MongoDB Indexes

Report the four approved indexes and sanitized live ensure result.

## Live Data Safety

Confirm no session or user document was created, updated, deleted, or dumped.

## Tests

List new/modified test files.

Report:

dart test

result and exact test count.

Confirm tests do not use Atlas.

## Static Analysis

Report:

dart analyze

result.

## API Routes

Report final dart_frog list.

Confirm no auth/session route was added.

## Backend Health

Report sanitized health/readiness results if verified.

## Files Created

List TASK 010-created files.

## Files Modified

List TASK 010-modified files.

## Files Deleted

List TASK 010-deleted files.

## Documentation

Confirm creation of:

documentation/database/user-sessions-collection.md
documentation/architecture/auth-token-and-session-security.md
documentation/decisions/ADR-008-access-and-refresh-token-strategy.md
documentation/cursor/010_access_token_and_refresh_session_security_foundation.md

## Flutter Verification

Report:

git diff -- project/

## Security Verification

Confirm:

- no ACCESS_TOKEN_SECRET exposed;
- no default signing secret;
- no JWT logged;
- raw refresh tokens never persisted;
- raw refresh tokens never logged;
- refresh hashes are persistence-only;
- exact HS256 verification;
- secure random token IDs;
- replay detection implemented;
- backend/.env ignored;
- no secret exposed.

## Git Status

Provide final:

git status --short

## Issues / Warnings

Report all relevant warnings.

If none:

None.

## Final Statement

State whether the access-token/refresh-session security foundation is complete
and ready for ChatGPT review.

Do NOT implement signup.

Do NOT implement login.

Do NOT begin TASK 011.

Start TASK 010 now.
````

## Pre-Task Repository State

- Git root: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- Working tree: clean (`backend/.env` present and ignored)
- Latest commit: `6d85818` `password_security_foundation` (TASK 009)
- `git check-ignore -v backend/.env` → `gitignore:8:.env`
- Required TASK 009 files present

Pre-task backend baseline from `backend/`:

- `dart pub get` succeeded
- `dart analyze` → No issues found
- `dart test` → 80 tests passed
- `dart_frog list` → `/`, `/api/v1/health`, `/api/v1/ready`

## Work Performed

1. Verified the TASK 009 checkpoint and ignored `backend/.env`.
2. Confirmed pre-task analyze/test/routes.
3. Installed only `dart_jsonwebtoken:^3.4.1` (`dart pub add`; no `dart pub upgrade`).
4. Inspected dart_jsonwebtoken 3.4.1: `JWT.sign`/`JWT.verify`, `JWTAlgorithm.HS256`, `SecretKey`, issuer/audience/expiry, JWT exception types. Confirmed `JWT.decode` must not be used for authorization and that HMAC `SecretKey` can verify HS256/HS384/HS512, so JOSE `alg` is checked for exact HS256 before verify.
5. Extended `ServerConfig` with `ACCESS_TOKEN_SECRET` / `hasAccessTokenSecret` and a non-real `.env.example` placeholder. No default secret. `toString` omits the secret.
6. Implemented `AccessTokenClaims`, `AccessTokenService`, and `JwtAccessTokenService` (HS256, 15 minutes, issuer/audience, 16-byte `jti`).
7. Implemented opaque refresh-token generation (32 secure random bytes, base64url without padding) and SHA-256 lowercase-hex hashing via hashlib.
8. Implemented `UserSession`, `CreateUserSessionData`, `UserSessionRepository`, `MongoUserSessionRepository`, atomic `findAndModify` rotation, replay detection, and revocation.
9. Implemented `AuthSessionService` over the repository and token generator/hasher.
10. Added four approved `user_sessions` indexes and integrated them into `ensureApprovedDatabaseIndexes` / `tool/ensure_database_indexes.dart`.
11. Added tests without Atlas session documents. Formatted, analyzed, and tested.
12. Ensured live indexes only. No session or user documents were created.
13. Optional live health/ready check. No auth requests.
14. Documented collection/architecture/ADR-008 and created this report.
15. Left all TASK 010 work uncommitted.

## Files Created

- `backend/lib/src/features/auth/tokens/access_token_exceptions.dart`
- `backend/lib/src/features/auth/tokens/access_token_claims.dart`
- `backend/lib/src/features/auth/tokens/access_token_service.dart`
- `backend/lib/src/features/auth/tokens/jwt_access_token_service.dart`
- `backend/lib/src/features/auth/tokens/refresh_token.dart`
- `backend/lib/src/features/auth/sessions/user_session_exceptions.dart`
- `backend/lib/src/features/auth/sessions/user_session.dart`
- `backend/lib/src/features/auth/sessions/create_user_session_data.dart`
- `backend/lib/src/features/auth/sessions/user_session_repository.dart`
- `backend/lib/src/features/auth/sessions/session_document_store.dart`
- `backend/lib/src/features/auth/sessions/mongo_user_session_repository.dart`
- `backend/lib/src/features/auth/sessions/auth_session_service.dart`
- `backend/lib/src/features/auth/sessions/session_indexes.dart`
- `backend/test/src/features/auth/tokens/jwt_access_token_service_test.dart`
- `backend/test/src/features/auth/tokens/refresh_token_test.dart`
- `backend/test/src/features/auth/sessions/user_session_test.dart`
- `backend/test/src/features/auth/sessions/session_indexes_test.dart`
- `backend/test/src/features/auth/sessions/mongo_user_session_repository_test.dart`
- `backend/test/src/features/auth/sessions/auth_session_service_test.dart`
- `documentation/database/user-sessions-collection.md`
- `documentation/architecture/auth-token-and-session-security.md`
- `documentation/decisions/ADR-008-access-and-refresh-token-strategy.md`
- `documentation/cursor/010_access_token_and_refresh_session_security_foundation.md`

## Files Modified

- `backend/pubspec.yaml`
- `backend/pubspec.lock`
- `backend/.env.example`
- `backend/README.md`
- `backend/lib/src/config/server_config.dart`
- `backend/lib/src/database/collection_names.dart`
- `backend/lib/src/database/database_indexes.dart`
- `backend/tool/ensure_database_indexes.dart`
- `backend/test/src/config/server_config_test.dart`
- `documentation/README.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/database/README.md`
- `documentation/decisions/README.md`
- `documentation/setup/README.md`

## Files Deleted

None.

## Commands Executed

From repository root:

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status --short`
- `git status`
- `git log -9 --oneline`
- `git check-ignore -v backend/.env`
- `git diff -- project/`

From `backend/`:

- `dart pub get`
- `dart analyze`
- `dart test`
- `dart_frog list`
- `dart pub add "dart_jsonwebtoken:^3.4.1"`
- `dart format .`
- `dart run tool/ensure_database_indexes.dart`
- `dart_frog dev` (non-TTY)

Sanitized HTTP checks:

- `GET /api/v1/health`
- `GET /api/v1/ready`

Stopped leftover listeners on port 8080.

dart_jsonwebtoken and mongo_dart package sources were inspected in the pub cache only as needed. Dependency source was not modified.

Never printed `backend/.env`. Never ran `git add`, `git commit`, or `git push`. Never ran `dart pub upgrade`.

## Implementation Details

Access tokens live under `lib/src/features/auth/tokens/`. Refresh sessions live under `lib/src/features/auth/sessions/`. No HTTP routes were added.

`JwtAccessTokenService` signs with explicit `JWTAlgorithm.HS256`, 15-minute expiry, issuer `home_cleaning_marketplace_api`, and audience `home_cleaning_marketplace`. Claims are `sub`, `sid`, `role`, `jti`, `iat`, `exp`, `iss`, and `aud`. `jti` is 16 secure random bytes encoded as unpadded base64url. Secrets shorter than 32 UTF-8 bytes are rejected with a sanitized configuration exception.

Verification inspects the JOSE `alg` for exact HS256, then calls `JWT.verify` with signature, expiry, issuer, and audience checks. Claims are parsed only from the verified payload. Unknown roles and malformed ObjectIds fail. Package exceptions are mapped to `InvalidAccessTokenException`.

Refresh tokens are 32 secure random bytes, unpadded base64url, with no structured metadata. Storage uses hashlib SHA-256 lowercase hex. Argon2 is not used for refresh-token lookup.

`MongoUserSessionRepository.rotateCurrentTokenAtomically` uses mongo_dart `findAndModify` matching current hash, `revoked_at == null`, and `expires_at > now`. The update `$set`s the new hash and `last_rotated_at` and `$push`es the old hash into `used_refresh_token_hashes`. `expires_at` is not changed.

`AuthSessionService.rotateRefreshToken` issues a new raw token only after atomic success. If rotation fails and the presented hash is in `used_refresh_token_hashes`, the session is revoked and `RefreshTokenReuseDetectedException` is thrown. Other failures are `InvalidRefreshTokenException`.

TTL index `user_sessions_expires_at_ttl` uses `expireAfterSeconds: 0` via `db.runCommand` because collection `createIndex` does not expose TTL options in mongo_dart 0.10.9.

`UserAccount` persistence shape was not changed.

## Technical Decisions

- dart_jsonwebtoken 3.4.1 is the only new direct dependency.
- Exact HS256 is enforced from the JOSE header because HMAC `SecretKey` verification would otherwise accept HS384/HS512.
- SHA-256 lookup hashes for high-entropy refresh tokens rather than Argon2.
- Same-document atomic rotation rather than a new document per rotation.
- No access-token denylist; 15-minute JWT lifetime is the revocation tradeoff.
- `ACCESS_TOKEN_SECRET` has no development default; the server still starts without it.

## Verification Performed

- Clean checkpoint and secret ignore checks
- Pre-task analyze/test/routes
- JWT package API inspection
- Format, analyze, tests
- Live `user_sessions` index ensure (index metadata only)
- Confirmation the index tool does not create sessions
- Live health/ready
- Source review for token/secret/refresh/hash/jwt
- Flutter diff empty
- Route list unchanged
- No secrets staged

## Verification Results

- Pre-task: analyze clean; 80 tests; routes `/`, `/api/v1/health`, `/api/v1/ready`
- dart_jsonwebtoken requested: `^3.4.1`; resolved: `3.4.1` (`direct main` in lockfile)
- No unrelated direct package added
- `dart analyze` — No issues found
- `dart test` — 118 tests passed
- `dart_frog list` unchanged; no `/auth`, `/login`, `/signup`, `/register`, `/refresh`, `/logout`, `/sessions`, `/users`
- Live indexes: all four `user_sessions` indexes exist; unique current-hash index; TTL `expireAfterSeconds = 0`
- Live health HTTP 200 `ok`; ready HTTP 200 `ready`
- `git diff -- project/` empty
- Tests do not contact Atlas
- Index tool does not call `AuthSessionService.createSession` or session `insertOne`

## Errors / Warnings

`dart_frog dev` again raised `StdinException: Error setting terminal echo mode` in this non-interactive shell (errno 6). Health/ready still returned HTTP 200. This is the known non-TTY Dart Frog limitation from earlier tasks, not an application defect.

## Security / Secrets Check

- `backend/.env` was not printed, staged, or committed.
- `MONGODB_URI` was not changed.
- No real `ACCESS_TOKEN_SECRET` was generated or written to `.env`.
- `.env.example` contains only the placeholder `<replace-with-a-strong-random-secret>`.
- No default signing secret exists.
- Tests use fake secrets and fake token material only.
- Application code does not log JWTs, raw refresh tokens, refresh-token hashes, or `ACCESS_TOKEN_SECRET`.
- Raw refresh tokens are never persisted; repositories accept hashes only.
- JWT verification requires signature and exact HS256.
- Token identifiers use hashlib secure `randomBytes`.
- Replay detection revokes the logical session.
- Used token hashes are retained on the session document.
- Rotation is atomic compare-and-modify.
- `UserAccount.toPublicJson` still excludes password fields. `UserSession.toString` excludes token hashes.
- TASK 010 did not insert, update, delete, or dump user or session documents.

## Git Diff Summary

Backend gained dart_jsonwebtoken 3.4.1, access-token/refresh-session primitives, tests, `ACCESS_TOKEN_SECRET` configuration, and `user_sessions` indexes. Documentation gained the session collection guide, token/session architecture, ADR-008, this report, and index updates. Flutter was not changed. Routes were not changed. Changes remain uncommitted.

## Final Repository State

Branch `main`, TASK 010 files unstaged/untracked. `backend/.env` ignored. No commit created.

## Unresolved Issues

- Signup, login, refresh, logout, authentication middleware, Flutter secure storage, access-token denylist, pepper, MFA, rate limiting, and compromised-password screening remain unimplemented by design.
- Dart Frog CLI still has the non-TTY `StdinException` limitation.

## Suggested Next Step

A later authentication task may add signup/login/refresh/logout routes that call `PasswordPolicy`, `PasswordHasher`, `AccessTokenService`, and `AuthSessionService`. Do not implement that as part of TASK 010.
