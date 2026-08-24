# Cursor Task 009 — Password Security Foundation

## Metadata

- Task ID: 009
- Task title: Password Security Foundation
- Date: 2026-08-25 00:44 +06:00
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Establish server-side password-security primitives before signup or login: hashlib Argon2id hashing with approved OWASP-minimum parameters, encoded PHC storage, PasswordPolicy (15–128 Unicode code points), PasswordHasher/Argon2idPasswordHasher, malformed-hash safety, needsRehash detection, tests, local timing measurement, and documentation. Do not add authentication endpoints, mutate MongoDB users, change Flutter, or commit.

## Exact Cursor Prompt

````text
# TASK 009 — Password Security Foundation

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

TASK 008 established and checkpointed the users persistence foundation.

The backend currently has:

GET /
GET /api/v1/health
GET /api/v1/ready

The users persistence layer now exists, including:

- users collection contract;
- UserRole;
- AccountStatus;
- UserAccount;
- CreateUserAccountData;
- email normalization;
- UserRepository;
- MongoUserRepository;
- unique normalized-email index.

TASK 009 establishes password-security primitives BEFORE signup/login are
implemented.

This task must NOT create authentication endpoints.

======================================================================
APPROVED PASSWORD HASHING DECISION
======================================================================

Use:

hashlib: ^2.4.2

Password hashing algorithm:

Argon2id

Initial approved parameters:

memory:
19456 KiB (19 MiB)

iterations:
2

parallelism:
1

hash output:
32 bytes

salt:
16 cryptographically secure random bytes

The parameters intentionally begin at OWASP's current Argon2id minimum
recommendation.

Do NOT silently weaken them.

If performance is unacceptable on the development machine:

- measure it;
- report it;
- do NOT automatically lower security parameters.

======================================================================
PASSWORD HASH STORAGE FORMAT
======================================================================

Store an encoded Argon2id hash containing the algorithm/version, parameters,
salt, and derived hash.

Prefer the standard encoded representation already produced by hashlib if its
current API provides it.

Conceptually it should resemble a PHC-style value such as:

$argon2id$v=19$m=19456,t=2,p=1$...$...

Do NOT manually invent a proprietary hash format if the library already
provides a correct encoded form that argon2Verify can consume.

Before implementation, inspect the installed hashlib API sufficiently to
confirm:

- how Argon2Security custom parameters are supplied;
- how Argon2id output is encoded;
- how argon2Verify consumes the encoded value;
- how secure random salt bytes are generated.

Adapt to the actual 2.4.2 API rather than guessing method names.

======================================================================
APPROVED PASSWORD POLICY
======================================================================

TASK 009 establishes a server-side password policy for future public account
creation.

Minimum length:

15 Unicode code points

Maximum length:

128 Unicode code points

Rules:

- do NOT trim the password;
- do NOT lowercase it;
- do NOT uppercase it;
- do NOT Unicode-normalize it unless explicitly decided in a future ADR;
- spaces are allowed;
- Unicode is allowed;
- punctuation is allowed;
- any printable/useful characters are allowed;
- no required uppercase character;
- no required lowercase character;
- no required number;
- no required symbol.

Password length must be counted by Unicode code points/runes rather than UTF-16
code units where practical.

A future breached/common-password blocklist is deferred.

Do NOT call external breach-check services in TASK 009.

======================================================================
IMPORTANT PASSWORD SEMANTICS
======================================================================

Passwords are opaque secrets.

The password:

" Correct Horse Battery Staple "

is NOT equivalent to:

"Correct Horse Battery Staple"

Whitespace must not be silently modified.

Similarly:

"Password"

is NOT equivalent to:

"password"

Do not reuse email normalization logic for passwords.

======================================================================
PURPOSE OF TASK 009
======================================================================

TASK 009 must:

1. verify TASK 008 was committed and repository starts clean;
2. verify existing backend health/tests;
3. install only hashlib 2.4.2;
4. establish PasswordPolicy;
5. establish a PasswordHasher abstraction;
6. implement Argon2idPasswordHasher;
7. generate cryptographically secure unique salts;
8. generate encoded Argon2id password hashes;
9. verify encoded password hashes safely;
10. support detecting hashes that should be upgraded/rehashed;
11. prevent malformed stored hashes from crashing future login flows;
12. benchmark the approved Argon2id configuration locally;
13. add comprehensive tests;
14. document password-storage decisions;
15. preserve the users persistence model;
16. make NO MongoDB data mutations;
17. make NO API route changes;
18. verify Flutter remains unchanged;
19. create TASK 009 report;
20. leave everything uncommitted for ChatGPT review.

======================================================================
STRICT SAFETY RULES
======================================================================

For TASK 009:

1. Do NOT implement signup.
2. Do NOT implement login.
3. Do NOT implement logout.
4. Do NOT implement refresh.
5. Do NOT implement password recovery.
6. Do NOT add authentication routes.
7. Do NOT implement JWT.
8. Do NOT install dart_jsonwebtoken.
9. Do NOT implement access tokens.
10. Do NOT implement refresh tokens.
11. Do NOT implement sessions.
12. Do NOT create user_sessions collection.
13. Do NOT create session indexes.
14. Do NOT create password_reset_tokens collection.
15. Do NOT create real users.
16. Do NOT insert users into Atlas.
17. Do NOT update users in Atlas.
18. Do NOT delete users from Atlas.
19. Do NOT enumerate user documents.
20. Do NOT modify the existing live users index unless required merely for
    verification, which should normally not be necessary.
21. Do NOT accept a real user password.
22. Do NOT put passwords in logs.
23. Do NOT print generated password hashes unnecessarily.
24. Do NOT print salts unnecessarily.
25. Do NOT put passwords in documentation.
26. Do NOT put real credentials into tests.
27. Do NOT print backend/.env.
28. Do NOT change MONGODB_URI.
29. Do NOT add a password pepper yet.
30. Do NOT add breach-password APIs.
31. Do NOT add composition requirements.
32. Do NOT implement MFA.
33. Do NOT modify Flutter.
34. Do NOT modify Flutter dependencies.
35. Do NOT change API routes.
36. Do NOT change native identifiers.
37. Do NOT add packages other than the one approved dependency.
38. Do NOT stage.
39. Do NOT commit.
40. Do NOT push.
41. Do NOT modify historical TASK 001–008 reports.
42. Do NOT make unrelated changes.

======================================================================
STEP 1 — VERIFY CLEAN CHECKPOINT
======================================================================

From repository root run:

git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -8 --oneline

Expected Git root:

D:\freelance\erfankhan_cse489\final

Expected branch:

main

Expected working tree:

clean

backend/.env may exist but must remain ignored.

Verify these exist:

backend/pubspec.yaml
backend/pubspec.lock
backend/lib/src/features/users/domain/user_account.dart
backend/lib/src/features/users/domain/create_user_account_data.dart
backend/lib/src/features/users/data/user_repository.dart
backend/lib/src/features/users/data/mongo_user_repository.dart
backend/routes/api/v1/health.dart
backend/routes/api/v1/ready.dart
documentation/cursor/008_user_account_persistence_foundation.md

Verify:

git check-ignore -v backend/.env

Do NOT print backend/.env.

If the repository is not clean:

STOP.

Do not modify anything.

======================================================================
STEP 2 — PRE-TASK BACKEND BASELINE
======================================================================

From backend/ run:

dart pub get
dart analyze
dart test
dart_frog list

Expected baseline:

dart analyze → no issues
dart test    → 59 tests pass

Expected routes:

/
/api/v1/health
/api/v1/ready

If baseline fails:

STOP.

Do not perform unrelated repairs.

======================================================================
STEP 3 — INSTALL ONLY HASHLIB
======================================================================

From backend/ run:

dart pub add "hashlib:^2.4.2"

Do NOT run:

dart pub upgrade

Do NOT install:

bcrypt packages
argon2 package
dargon2
dargon2_flutter
cryptography
password_guard
crypto directly
JWT packages
session packages
random packages

unless they are merely transitive dependencies of hashlib.

hashlib itself contains the required Argon2 and secure-random functionality.

Inspect:

backend/pubspec.yaml
backend/pubspec.lock

Record:

requested version
resolved version

Confirm no unrelated direct package was added.

======================================================================
STEP 4 — INSPECT HASHLIB ARGON2 API
======================================================================

Before implementing the hasher, inspect the installed hashlib 2.4.2 API/source
only as needed to determine the correct usage for:

Argon2Security
argon2id
argon2Verify
secure random bytes
encoded Argon2 output

Do not copy large package source sections into project documentation.

Do not modify dependency source.

Confirm the implementation can:

1. use Argon2id;
2. use custom m/t/p values;
3. use 16 random salt bytes;
4. produce an encoded hash;
5. verify that encoded hash later.

If the package cannot satisfy any of these requirements:

STOP.

Report the incompatibility.

Do NOT silently switch packages.

======================================================================
STEP 5 — CREATE AUTHENTICATION SECURITY AREA
======================================================================

Create only real files under a focused feature area.

Suggested location:

backend/lib/src/features/auth/security/

Do not create HTTP routes.

Initial structure should contain real files such as:

password_policy.dart
password_hasher.dart
argon2id_password_hasher.dart

Adapt filenames slightly if necessary, but keep responsibilities separate.

Do NOT create:

routes/
controllers/
sessions/
tokens/
jwt/
refresh/
middleware/

inside auth yet.

======================================================================
STEP 6 — CREATE PASSWORD POLICY
======================================================================

Create:

PasswordPolicy

or an equivalent clear abstraction.

Approved constants:

minimumLength = 15
maximumLength = 128

Count Unicode code points/runes.

The policy should distinguish at minimum:

valid
tooShort
tooLong

It may use:

PasswordValidationResult

or a similarly small explicit model.

Do not create dozens of validation error classes.

The policy MUST:

- preserve whitespace;
- preserve case;
- allow spaces;
- allow Unicode;
- impose no character-class composition rule.

Examples:

"short"
→ invalid / too short

15-code-point password
→ valid

128-code-point password
→ valid

129-code-point password
→ invalid / too long

Do NOT hash as part of policy validation.

Do NOT expose entropy estimates.

======================================================================
STEP 7 — PASSWORD HASHER ABSTRACTION
======================================================================

Create a small abstraction such as:

abstract interface class PasswordHasher {
  String hash(String password);
  bool verify({
    required String password,
    required String encodedHash,
  });
  bool needsRehash(String encodedHash);
}

If hashlib's Argon2 implementation is asynchronous, use Future-returning
methods instead.

Follow the actual library API.

Do not force synchronous APIs if doing so would make hashing less suitable.

The abstraction should be straightforward to fake/mock in future
authentication-service tests.

======================================================================
STEP 8 — ARGON2ID IMPLEMENTATION
======================================================================

Create:

Argon2idPasswordHasher

Use exactly:

Argon2id
memory = 19456 KiB
iterations = 2
parallelism = 1
hashLength = 32
saltLength = 16 bytes

Use a cryptographically secure random salt for every new hash.

Never use:

Random()

with a predictable seed.

Use hashlib's secure-random facility if available.

If its current API does not provide the required secure-random utility,
Dart's cryptographically secure system RNG may be used, but do not add another
dependency.

Do NOT reuse a global/static salt.

Do NOT derive the salt from:

email
user ID
timestamp
password

Every hash gets an independent random salt.

======================================================================
STEP 9 — UTF-8 PASSWORD BYTES
======================================================================

Convert passwords to bytes using UTF-8.

Do not use:

password.codeUnits

if that would incorrectly model Unicode text compared with UTF-8 encoding.

Use Dart's standard UTF-8 encoder where appropriate.

Hash the password exactly as supplied.

Do NOT:

trim
lowercase
uppercase
collapse spaces

before hashing.

======================================================================
STEP 10 — ENCODED HASH
======================================================================

Store/return the package's encoded Argon2id representation.

It must contain enough information for later verification, including:

algorithm
version where applicable
m/t/p parameters
salt
derived hash

Do not store salt separately in UserAccount.

The existing:

password_hash

field should eventually contain this encoded string.

TASK 009 does NOT write that field to Atlas.

Do not add:

password_salt

to UserAccount or MongoDB.

======================================================================
STEP 11 — VERIFY
======================================================================

Password verification must use the library's supported Argon2 verification
mechanism.

Correct password:
→ true

Incorrect password:
→ false

Do NOT compare encoded strings directly.

Do NOT manually compare raw hash strings using ==.

Do NOT generate a new salt before verification.

The encoded hash already contains the information needed for verification.

======================================================================
STEP 12 — MALFORMED HASH SAFETY
======================================================================

Future login must not crash because a persisted hash is malformed.

The PasswordHasher boundary should handle malformed/unsupported hash input
predictably.

Preferred external behavior:

verify(...)
→ false

for malformed or unsupported hash strings.

Do not expose parser/cryptography stack traces to future clients.

Do not catch unrelated catastrophic programming errors broadly.

Add tests for malformed values such as:

""
"not-a-password-hash"
a structurally damaged Argon2 string

Use fake values only.

======================================================================
STEP 13 — HASH UPGRADE DETECTION
======================================================================

Implement:

needsRehash(encodedHash)

or equivalent.

Purpose:

If password-hashing cost parameters are increased later, successful login can
eventually replace an older hash.

Current approved target:

algorithm = argon2id
memory = 19456
iterations = 2
parallelism = 1
hash length = 32 where encoded metadata permits assessment

Expected:

hash produced by current hasher
→ needsRehash == false

valid Argon2id hash with weaker/different cost
→ needsRehash == true

different/legacy algorithm
→ needsRehash == true

malformed hash
→ needsRehash == true

Do not rehash anything in TASK 009.

Do not modify users.

If hashlib exposes encoded-hash context/parsing, use that.

If not, implement only the small standards-aware encoded-parameter parser
necessary for this operation.

Do not create a generic PHC framework.

======================================================================
STEP 14 — DO NOT CHANGE USERACCOUNT SHAPE
======================================================================

Do NOT add new persisted password fields.

UserAccount continues to have:

passwordHash

mapped to:

password_hash

No:

passwordSalt
passwordAlgorithm
passwordUpdatedAt

is needed yet.

The encoded Argon2 string carries algorithm/parameter/salt information.

Do not make passwordHash public.

======================================================================
STEP 15 — PASSWORD POLICY TESTS
======================================================================

Create focused tests.

Test at minimum:

- below 15 code points rejected;
- exactly 15 accepted;
- 128 accepted;
- above 128 rejected;
- spaces accepted;
- Unicode accepted;
- leading/trailing spaces are counted, not trimmed;
- uppercase/lowercase are not transformed;
- no symbol/number/uppercase rule exists.

Use fake test passwords only.

Do not use real credentials.

======================================================================
STEP 16 — PASSWORD HASHER TESTS
======================================================================

Test:

1. produces an Argon2id encoded value;
2. correct password verifies;
3. wrong password fails;
4. hashing same password twice produces different encoded values because salts
   differ;
5. both independently generated hashes still verify the same password;
6. a password containing spaces verifies exactly;
7. case differences fail verification;
8. Unicode passwords verify;
9. malformed encoded hash returns false safely;
10. current hash reports needsRehash false;
11. weaker/different parameters report needsRehash true;
12. malformed hash reports needsRehash true.

Do not assert one exact generated hash because salt is intentionally random.

If a deterministic salt injection seam is useful for one low-level test, keep
it narrowly scoped.

Production must always use secure randomness.

======================================================================
STEP 17 — SALT QUALITY TEST
======================================================================

Do not attempt statistical randomness certification.

A simple behavioral test is enough:

hash the same password multiple times and verify encoded hashes/salts differ.

Do not weaken the production RNG merely to make testing easy.

======================================================================
STEP 18 — PARAMETER VERIFICATION TEST
======================================================================

Inspect the encoded output produced by the production hasher and test that it
contains/represents the approved:

Argon2id
m = 19456
t = 2
p = 1

Do not depend unnecessarily on exact salt/hash bytes.

This test protects against accidental parameter regression.

======================================================================
STEP 19 — LOCAL HASH PERFORMANCE MEASUREMENT
======================================================================

After functional tests pass, create either:

- a small non-production benchmark/tool; or
- a temporary safe measurement command.

Prefer a reusable developer tool if clean, e.g.:

backend/tool/benchmark_password_hashing.dart

It must:

- use only a fixed fake password;
- never use real credentials;
- run a small number of hashes/verifications, such as 3;
- report timing only;
- NOT print password;
- NOT print hashes;
- NOT print salts.

Measure enough to report approximate development-machine hashing latency.

Do NOT automatically tune parameters.

Do NOT lower below:

m=19456
t=2
p=1

If timing is unexpectedly severe, report it for review.

Do not turn this into a full benchmark suite.

======================================================================
STEP 20 — NO DATABASE MUTATION
======================================================================

TASK 009 must not require MongoDB for password tests.

Do NOT call:

UserRepository.create
MongoUserRepository.create

against Atlas.

Do NOT modify any user document.

Do NOT create additional indexes.

No live Atlas mutation is needed for TASK 009.

======================================================================
STEP 21 — NO ROUTE CHANGES
======================================================================

Run:

dart_frog list

Expected routes remain exactly:

/
/api/v1/health
/api/v1/ready

There must still be no:

/auth
/login
/signup
/register
/refresh
/logout
/users

route.

======================================================================
STEP 22 — FORMAT
======================================================================

From backend/:

dart format .

======================================================================
STEP 23 — STATIC ANALYSIS
======================================================================

Run:

dart analyze

It must report no issues.

Do not suppress security-related warnings.

======================================================================
STEP 24 — TEST
======================================================================

Run:

dart test

All existing and new tests must pass.

Report the exact final test count.

Tests must not contact real Atlas.

======================================================================
STEP 25 — OPTIONAL HEALTH REGRESSION CHECK
======================================================================

If practical, start Dart Frog long enough to verify:

GET /api/v1/health → 200
GET /api/v1/ready  → 200

Do not perform authentication requests.

Stop the server afterward.

The known non-TTY StdinException may recur in Cursor's shell; report it
accurately if it occurs.

======================================================================
STEP 26 — SECURITY REVIEW
======================================================================

Review new application source for:

password
hash
salt

Confirm:

- plaintext passwords exist only transiently as method parameters or fake test
  strings;
- no password is logged;
- no password is persisted by TASK 009;
- generated salts are secure/random;
- salt is never hard-coded;
- hashes are encoded;
- verify does not use direct string equality;
- password policy does not trim/normalize;
- malformed hashes are safely handled;
- public UserAccount JSON remains unchanged and excludes password hashes.

Do not print backend/.env.

Confirm no secret was introduced.

======================================================================
STEP 27 — FLUTTER VERIFICATION
======================================================================

From repository root:

git diff -- project/

Expected:

empty.

No Flutter code or dependency changes.

======================================================================
STEP 28 — DOCUMENT PASSWORD SECURITY
======================================================================

Create:

documentation/architecture/password-security.md

Document:

## Purpose

Password hashing/verification boundary used by future authentication.

## Algorithm

Argon2id.

## Parameters

memory:
19456 KiB

iterations:
2

parallelism:
1

hash length:
32 bytes

salt:
16 secure random bytes

## Storage

Explain that the encoded Argon2id value is stored in users.password_hash and
includes the salt/parameters.

No separate salt field.

## Password Semantics

Passwords are opaque.

No trimming/case transformation.

UTF-8 encoding.

## Policy

15–128 Unicode code points.

No composition rules.

Spaces and Unicode allowed.

## Verification

Library-supported Argon2 verification.

Malformed stored hashes fail authentication rather than crashing.

## Rehashing

Explain needsRehash and future cost migration.

## Security Boundaries

Never log plaintext password or encoded hashes unnecessarily.

Never expose password_hash through public serialization.

## Deferred

- compromised-password blocklist;
- pepper;
- MFA;
- rate limiting;
- login;
- signup;
- session/token handling.

Do not include real passwords/hashes.

======================================================================
STEP 29 — CREATE ADR-007
======================================================================

Create:

documentation/decisions/ADR-007-password-hashing-and-policy.md

Use:

# ADR-007 — Password Hashing and Policy

## Status
## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Status:

Accepted

Context:

The users persistence layer stores password_hash, but secure password
generation/verification must exist before signup or login accepts credentials.

Decision:

- hashlib 2.4.2;
- Argon2id;
- m=19456 KiB;
- t=2;
- p=1;
- 32-byte hash;
- 16-byte random salt;
- encoded hash storage;
- 15–128 Unicode-code-point password policy;
- no composition rules;
- no password normalization;
- needsRehash support.

Alternatives Considered:

### SHA-256 / SHA-512 directly

Rejected because general cryptographic hashes are intentionally fast and are
not suitable password-storage functions.

### bcrypt

Viable fallback but not selected because Argon2id is the preferred modern
memory-hard password hashing algorithm.

### PBKDF2

Viable in environments requiring specific compliance constraints, but Argon2id
is chosen for this application.

### Custom password-hashing algorithm

Rejected.

### Enforcing uppercase/numeric/symbol rules

Rejected because modern password guidance favors length and breached-password
screening rather than arbitrary composition rules.

### Trimming passwords

Rejected because it changes the user's authentication secret.

### Password pepper now

Deferred until production secret-management strategy is designed.

Consequences:

- hashing is intentionally CPU/memory expensive;
- login/signup must call the PasswordHasher rather than implementing crypto;
- cost parameters can evolve through needsRehash;
- password length checks occur before costly hashing;
- future rate limiting remains necessary for online attacks.

Deferred Decisions:

- compromised-password screening;
- pepper;
- access tokens;
- refresh tokens;
- session storage;
- auth middleware;
- signup;
- login;
- logout;
- password reset;
- MFA;
- rate limiting.

======================================================================
STEP 30 — UPDATE DOCUMENTATION INDEXES
======================================================================

Update only as needed:

documentation/README.md
documentation/architecture/README.md
documentation/decisions/README.md
documentation/architecture/backend-api-architecture.md
documentation/database/users-collection.md
backend/README.md

Add links to:

architecture/password-security.md
decisions/ADR-007-password-hashing-and-policy.md

Update users-collection documentation only enough to state that password_hash
will use the approved Argon2id encoded form.

Do NOT claim signup/login exists.

======================================================================
STEP 31 — REVIEW DEPENDENCY DIFF
======================================================================

Run:

git diff -- backend/pubspec.yaml
git diff -- backend/pubspec.lock

Confirm:

hashlib

is the only new direct dependency.

Transitive dependency changes are acceptable only as consequences of hashlib.

Do not manually edit the lockfile.

======================================================================
STEP 32 — REVIEW APPLICATION CHANGES
======================================================================

From repository root run:

git status --short
git diff -- backend/lib/
git diff -- backend/test/
git diff -- backend/tool/
git diff -- backend/routes/
git diff -- project/
git diff -- documentation/
git diff -- backend/README.md

New files will be untracked and may require direct inspection.

Confirm no route source was added/changed unless formatting alone somehow
affected it, which should normally not occur.

======================================================================
STEP 33 — CREATE TASK 009 REPORT
======================================================================

Create:

documentation/cursor/009_password_security_foundation.md

using:

documentation/cursor/task-report-template.md

The report MUST contain the COMPLETE EXACT TASK 009 prompt under:

## Exact Cursor Prompt

Document:

- clean starting checkpoint;
- pre-task test/analyze/routes;
- hashlib requested/resolved version;
- inspected Argon2 API behavior;
- PasswordPolicy;
- PasswordHasher;
- Argon2idPasswordHasher;
- parameters;
- secure salt generation;
- encoded format;
- UTF-8 behavior;
- exact-password semantics;
- malformed-hash handling;
- needsRehash behavior;
- test files;
- final test count;
- analysis;
- routes;
- performance measurement;
- database no-mutation verification;
- Flutter no-change verification;
- documentation created/modified;
- files created;
- files modified;
- files deleted;
- security review;
- final Git status;
- unresolved issues.

Never include:

- real passwords;
- backend/.env contents;
- MONGODB_URI;
- MongoDB credentials;
- real user password hashes.

======================================================================
STEP 34 — FINAL VERIFICATION AFTER REPORT
======================================================================

From backend/ run again:

dart analyze
dart test
dart_frog list

From repository root:

git status --short
git diff -- project/
git check-ignore -v backend/.env

Final routes must remain:

/
/api/v1/health
/api/v1/ready

All tests must pass.

======================================================================
STEP 35 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 009 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond with exactly these top-level sections:

# TASK 009 RESULT

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
- routes
- backend/.env ignore state

## Dependency Added

Report:

hashlib requested version
hashlib resolved version

Confirm no unrelated direct dependency.

## Password Policy

Report:

- minimum length
- maximum length
- Unicode counting method
- whitespace behavior
- case behavior
- composition-rule behavior

## Password Hasher

Describe:

- algorithm
- m/t/p
- hash length
- salt length
- secure RNG source
- UTF-8 conversion
- encoded output

## Verification Behavior

Report:

- correct-password behavior
- wrong-password behavior
- malformed-hash behavior

## Rehash Detection

Describe needsRehash behavior.

## Performance Measurement

Report only timing/latency summary.

Do not report password, salt, or generated hashes.

## Tests

List new/modified test files.

Report final:

dart test

result and exact test count.

Confirm tests do not use Atlas.

## Static Analysis

Report:

dart analyze

result.

## API Routes

Provide final dart_frog list.

Confirm no auth route was added.

## Database Safety

Confirm no MongoDB document or index mutation occurred.

## Files Created

List TASK 009-created files.

## Files Modified

List TASK 009-modified files.

## Files Deleted

List TASK 009-deleted files.

## Documentation

Confirm creation of:

documentation/architecture/password-security.md
documentation/decisions/ADR-007-password-hashing-and-policy.md
documentation/cursor/009_password_security_foundation.md

## Flutter Verification

Report:

git diff -- project/

## Security Verification

Confirm:

- no password logged;
- no real password used;
- no plaintext password persisted;
- random salts used;
- direct hash-string comparison not used for authentication;
- UserAccount public serialization still excludes password fields;
- backend/.env remains ignored;
- no secret exposed.

## Git Status

Provide final:

git status --short

## Issues / Warnings

Report relevant warnings.

If none:

None.

## Final Statement

State whether password-security foundation is complete and ready for ChatGPT
review.

Do NOT implement signup.

Do NOT implement login.

Do NOT begin TASK 010.

Start TASK 009 now.
````

## Pre-Task Repository State

- Git root: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- Working tree: clean (`backend/.env` present and ignored)
- Latest commit: `99180d8` `user_account_persistence_foundation` (TASK 008)
- `git check-ignore -v backend/.env` → `gitignore:8:.env`
- Required TASK 008 files present (`UserAccount`, repositories, health/ready routes, TASK 008 report)

Pre-task backend baseline from `backend/`:

- `dart pub get` succeeded
- `dart analyze` → No issues found
- `dart test` → 59 tests passed
- `dart_frog list` → `/`, `/api/v1/health`, `/api/v1/ready`

## Work Performed

1. Verified the TASK 008 checkpoint and ignored `backend/.env`.
2. Confirmed pre-task analyze/test/routes.
3. Installed only `hashlib:^2.4.2` (`dart pub add`; no `dart pub upgrade`).
4. Inspected hashlib 2.4.2 API: `Argon2Security`, `argon2id`, `encoded()`, `argon2Verify`, and `randomBytes` from `package:hashlib/random.dart`.
5. Created `lib/src/features/auth/security/` with `PasswordPolicy`, `PasswordHasher`, and `Argon2idPasswordHasher`.
6. Implemented UTF-8 encoding, unique secure salts, encoded Argon2id output, safe verify, and `needsRehash`.
7. Added policy and hasher tests plus `tool/benchmark_password_hashing.dart`.
8. Formatted, analyzed, and tested. Benchmarked approved parameters. Did not lower cost.
9. Optional live health/ready check. No auth requests. No Atlas user mutations.
10. Documented password security, ADR-007, and index updates. Created this report.
11. Left all TASK 009 work uncommitted.

## Files Created

- `backend/lib/src/features/auth/security/password_policy.dart`
- `backend/lib/src/features/auth/security/password_hasher.dart`
- `backend/lib/src/features/auth/security/argon2id_password_hasher.dart`
- `backend/test/src/features/auth/security/password_policy_test.dart`
- `backend/test/src/features/auth/security/argon2id_password_hasher_test.dart`
- `backend/tool/benchmark_password_hashing.dart`
- `documentation/architecture/password-security.md`
- `documentation/decisions/ADR-007-password-hashing-and-policy.md`
- `documentation/cursor/009_password_security_foundation.md`

## Files Modified

- `backend/pubspec.yaml`
- `backend/pubspec.lock`
- `backend/README.md`
- `documentation/README.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/decisions/README.md`
- `documentation/database/users-collection.md`

## Files Deleted

None.

## Commands Executed

From repository root:

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status --short`
- `git status`
- `git log -8 --oneline`
- `git check-ignore -v backend/.env`
- `git diff -- project/`
- `git diff -- backend/pubspec.yaml`
- `git diff -- backend/pubspec.lock`
- `git diff -- backend/lib/`
- `git diff -- backend/test/`
- `git diff -- backend/tool/`
- `git diff -- backend/routes/`
- `git diff -- documentation/`
- `git diff -- backend/README.md`

From `backend/`:

- `dart pub get`
- `dart analyze`
- `dart test`
- `dart_frog list`
- `dart pub add "hashlib:^2.4.2"`
- `dart format .`
- `dart run tool/benchmark_password_hashing.dart`
- `dart_frog dev` (non-TTY)

Sanitized HTTP checks:

- `GET /api/v1/health`
- `GET /api/v1/ready`

Stopped leftover listeners on port 8080.

Hashlib package sources were inspected in the pub cache only as needed. Dependency source was not modified.

Never printed `backend/.env`. Never ran `git add`, `git commit`, or `git push`. Never ran `dart pub upgrade`.

## Implementation Details

Password security lives under `lib/src/features/auth/security/` with no HTTP routes.

`PasswordPolicy` counts Unicode code points with `String.runes.length`. Bounds are 15–128. It does not trim, case-fold, Unicode-normalize, or hash. Issues are only `tooShort` and `tooLong`.

`PasswordHasher` is a small synchronous interface (`hash`, `verify`, `needsRehash`) matching hashlib's synchronous Argon2 API so future auth tests can fake it.

`Argon2idPasswordHasher` uses:

- algorithm: Argon2id
- `Argon2Security('approved', m: 19456, t: 2, p: 1)`
- hash length: 32 bytes
- salt length: 16 bytes from hashlib `randomBytes` (secure RNG by default)
- password bytes: `utf8.encode(password)` exactly as supplied
- encoded output: hashlib `Argon2HashDigest.encoded()` PHC string

Verification calls `argon2Verify`. `FormatException` and `ArgumentError` from malformed input return `false`. Other errors are rethrown.

`needsRehash` uses a small Argon2id PHC parser (not a generic PHC framework). Current approved hashes return false. Weaker/different cost, different algorithm (`argon2i`), or malformed strings return true. Nothing is rehashed in TASK 009.

`UserAccount` shape is unchanged. Encoded hashes are intended for existing `password_hash`. No `password_salt` field was added. `toPublicJson` still omits password fields.

No MongoDB repository create/update/delete was called. No indexes were added. No Dart Frog routes were added.

## Technical Decisions

- hashlib 2.4.2 is the only new direct dependency.
- `randomBytes` is imported from `package:hashlib/random.dart` because it is not exported by `package:hashlib/hashlib.dart`.
- Custom `Argon2Security` constants are used so approved m/t/p cannot silently track a future library preset change.
- An optional `saltBytes` constructor seam exists for tests; production omits it and always uses secure randomness. Hasher tests rely on behavioral uniqueness rather than injecting salts.
- `verify` does not use `on ArgumentError` because the analyzer forbids catching `Error` types; malformed `ArgumentError` is detected with `catch` + `is ArgumentError`.
- Cost parameters were not lowered after local timing measurement.

## Verification Performed

- Clean checkpoint and secret ignore checks
- Pre-task analyze/test/routes
- Hashlib API inspection
- Format, analyze, tests
- Local Argon2id timing measurement (timing only)
- Live health/ready
- Password/hash/salt source review
- Flutter diff empty
- Route list unchanged
- No Atlas user document or index mutation
- No secrets staged

## Verification Results

- Pre-task: analyze clean; 59 tests; routes `/`, `/api/v1/health`, `/api/v1/ready`
- hashlib requested: `^2.4.2`; resolved: `2.4.2` (`direct main` in lockfile)
- No unrelated direct package added
- `dart analyze` — No issues found
- `dart test` — 80 tests passed
- `dart_frog list` unchanged; no `/auth`, `/login`, `/signup`, `/register`, `/refresh`, `/logout`, `/users`
- Benchmark (3 hash + 3 verify rounds, fake password only): hash average 41.7 ms; verify average 31.0 ms
- Live health HTTP 200 `ok`; ready HTTP 200 `ready`
- `git diff -- project/` empty
- Tests do not contact Atlas

## Errors / Warnings

`dart_frog dev` again raised `StdinException: Error setting terminal echo mode` in this non-interactive shell (errno 6). Health/ready still returned HTTP 200. A subsequent CLI restart attempt also reported a Dart VM service socket conflict on 127.0.0.1:8181 before the leftover listener was stopped. This is the known non-TTY Dart Frog limitation from earlier tasks, not an application defect.

Local hashing latency on the development machine was acceptable at the approved OWASP-minimum Argon2id parameters. Parameters were not lowered.

## Security / Secrets Check

- `backend/.env` was not printed, staged, or committed.
- `MONGODB_URI` was not changed.
- No MongoDB URI, hostname, or credentials were added to tracked files.
- No real user passwords were used. Tests and the benchmark use fake strings only.
- Application code does not log passwords, salts, or encoded hashes.
- The benchmark prints timing only.
- Documentation does not include real passwords or generated hashes.
- Salts are unique per hash via hashlib secure `randomBytes`.
- Verification uses `argon2Verify`, not encoded-string equality.
- Malformed hashes return `false` from `verify` and `true` from `needsRehash`.
- `UserAccount.toPublicJson` still excludes `password_hash` / `passwordHash`.
- TASK 009 did not persist hashes or plaintext passwords to Atlas.
- No pepper, JWT, session, or breach-check API was added.

## Git Diff Summary

Backend gained hashlib 2.4.2, password policy/hasher implementations, tests, and a timing tool. Documentation gained password-security architecture, ADR-007, this report, and index updates. Users persistence model and Flutter were not changed. Routes were not changed. Changes remain uncommitted.

## Final Repository State

Branch `main`, TASK 009 files unstaged/untracked. `backend/.env` ignored. No commit created.

## Unresolved Issues

- Signup, login, logout, refresh, JWT, sessions, pepper, MFA, rate limiting, and compromised-password screening remain unimplemented by design.
- Dart Frog CLI still has the non-TTY `StdinException` limitation.

## Suggested Next Step

A later authentication task may add signup/login routes that call `PasswordPolicy` and `PasswordHasher`. Do not implement that as part of TASK 009.
