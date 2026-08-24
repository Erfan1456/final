# Cursor Task 008 — User Account Persistence Foundation

## Metadata

- Task ID: 008
- Task title: User Account Persistence Foundation
- Date: 2026-08-24 23:02 +06:00
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Establish the first real persistence/domain boundary for users: collection naming, UserRole, AccountStatus, UserAccount, BSON and public serialization, email normalization, UserRepository/MongoUserRepository, unique email_normalized index, tests without Atlas user data, and a controlled live index ensure. Do not implement authentication endpoints or create real user accounts. Do not commit.

## Exact Cursor Prompt

````text
# TASK 008 — User Account Persistence Foundation

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

TASK 007 established and checkpointed MongoDB Atlas connectivity.

The backend currently has:

GET /
GET /api/v1/health
GET /api/v1/ready

MongoDB connectivity exists through the shared MongoDatabase lifecycle.

TASK 008 will establish the FIRST real persistence/domain boundary:

users

This task must NOT implement authentication endpoints or create actual user
accounts.

======================================================================
APPROVED USER ACCOUNT DATA MODEL
======================================================================

The conceptual users collection baseline is:

users
- _id
- role
- email
- email_normalized
- password_hash
- account_status
- email_verified
- created_at
- updated_at

Important:

The conceptual earlier schema used "id", but MongoDB implementation should use
MongoDB's native:

_id: ObjectId

unless a strong technical reason requires otherwise.

The public-facing application may later expose a string representation of _id.

======================================================================
APPROVED ROLE VALUES
======================================================================

Initial roles:

CUSTOMER
CLEANER
ADMIN

Inside Dart, prefer idiomatic enum names:

customer
cleaner
admin

Persist a stable explicit wire/database representation.

Use lowercase database strings unless the existing code conventions strongly
justify another format:

customer
cleaner
admin

Do not rely on Dart enum index/ordinal values.

ADMIN must be modeled because administrators exist in the system, but future
public signup must NOT be allowed to create admin accounts.

That signup authorization rule belongs to a later authentication task.

======================================================================
APPROVED ACCOUNT STATUS VALUES
======================================================================

Use an explicit account status model appropriate for this project.

Initial values:

active
suspended
deactivated

Do not add many speculative states.

Cleaner approval is NOT an account status.

Cleaner verification/onboarding belongs to cleaner profile/application data
later.

======================================================================
EMAIL INVARIANT
======================================================================

User email uniqueness must be enforced against a normalized representation.

Store both:

email
email_normalized

email:
- canonical user-facing form retained for communication/display

email_normalized:
- trimmed
- lowercase
- used for lookup and uniqueness

For now the normalization policy is:

trim whitespace
lowercase

Do NOT attempt provider-specific normalization such as:

- removing Gmail dots
- removing plus addressing
- rewriting domains

Those policies are unsafe to generalize.

Create a UNIQUE MongoDB index on:

email_normalized

This is a database-enforced invariant.

======================================================================
PASSWORD HASH SECURITY BOUNDARY
======================================================================

The persistence model contains:

password_hash

because authentication will require it later.

TASK 008 must NOT:

- hash passwords;
- accept passwords;
- compare passwords;
- install bcrypt/argon2;
- implement signup;
- implement login.

The persistence model may store/read an already-created password hash string,
but TASK 008 never generates a hash.

The password hash must NEVER appear in a public JSON representation.

======================================================================
PURPOSE OF TASK 008
======================================================================

TASK 008 must:

1. verify TASK 007 is committed and the repository begins clean;
2. verify MongoDB/backend baseline health;
3. establish collection-name conventions;
4. create UserRole;
5. create AccountStatus;
6. create the UserAccount persistence model;
7. establish safe BSON/document serialization;
8. establish safe public serialization that never leaks password_hash;
9. establish email normalization;
10. create a UserRepository abstraction;
11. create a MongoDB-backed UserRepository implementation;
12. implement only repository operations required for upcoming authentication;
13. create the users collection indexes;
14. safely verify the index against the real Atlas database;
15. add comprehensive unit/repository-contract tests without creating real
    Atlas user data;
16. document the users collection and repository design;
17. run formatting, analysis, tests, and routes;
18. verify existing health/readiness behavior remains correct;
19. verify Flutter remains unchanged;
20. create TASK 008 report;
21. leave everything uncommitted for ChatGPT review.

======================================================================
STRICT SAFETY RULES
======================================================================

For TASK 008:

1. Do NOT modify Flutter implementation.
2. Do NOT modify Flutter dependencies.
3. Do NOT implement signup.
4. Do NOT implement login.
5. Do NOT implement logout.
6. Do NOT implement password recovery.
7. Do NOT add auth API routes.
8. Do NOT implement JWT.
9. Do NOT implement refresh tokens.
10. Do NOT implement sessions.
11. Do NOT install password-hashing packages.
12. Do NOT accept plaintext passwords.
13. Do NOT create any real user document.
14. Do NOT seed users.
15. Do NOT insert test users into real Atlas.
16. Do NOT update existing Atlas documents.
17. Do NOT delete existing Atlas documents.
18. Do NOT enumerate or dump Atlas user documents.
19. Do NOT expose password_hash in public JSON.
20. Do NOT log password hashes.
21. Do NOT log MongoDB URI.
22. Do NOT print backend/.env.
23. Do NOT create customer profiles.
24. Do NOT create cleaner profiles.
25. Do NOT create addresses.
26. Do NOT create verification documents.
27. Do NOT create services.
28. Do NOT create bookings.
29. Do NOT create payments.
30. Do NOT create session collections yet.
31. Do NOT create password-reset collections yet.
32. Do NOT implement schema migration tooling.
33. Do NOT add an ODM/ORM.
34. Do NOT create speculative generic repository frameworks.
35. Do NOT add packages unless genuinely required.
36. Do NOT change native identifiers.
37. Do NOT stage.
38. Do NOT commit.
39. Do NOT push.
40. Do NOT modify historical TASK 001–007 reports.
41. Do NOT make unrelated changes.

The only permitted live Atlas mutation in TASK 008 is creation/verification of
the approved index on the users collection.

Do NOT insert application documents.

======================================================================
STEP 1 — VERIFY CLEAN CHECKPOINT
======================================================================

From repository root run:

git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -7 --oneline

Expected:

Git root:
D:\freelance\erfankhan_cse489\final

Branch:
main

Working tree:
clean

The ignored:

backend/.env

may exist but must not appear in git status.

Verify these exist:

backend/pubspec.yaml
backend/lib/src/database/mongo_database.dart
backend/lib/src/config/server_config.dart
backend/routes/_middleware.dart
backend/routes/api/v1/health.dart
backend/routes/api/v1/ready.dart
documentation/cursor/007_mongodb_atlas_integration_foundation.md

Verify backend/.env exists using file-existence only.

Verify:

git check-ignore -v backend/.env

Do NOT print backend/.env.

If repository changes exist:

STOP.

Do not modify anything.

======================================================================
STEP 2 — PRE-TASK BACKEND HEALTH
======================================================================

From backend/ run:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

dart analyze → no issues
dart test    → 31 tests pass

Expected routes:

/
/api/v1/health
/api/v1/ready

If baseline fails:

STOP.

Report it without attempting unrelated repairs.

======================================================================
STEP 3 — DEPENDENCY AUDIT
======================================================================

Inspect:

backend/pubspec.yaml

TASK 008 should normally require NO new package.

Use:

mongo_dart

for BSON/ObjectId/collection access.

Use standard Dart for:

- enums
- normalization
- date/time
- exceptions/value validation

Do NOT add a package merely for model serialization.

Do NOT add:

freezed
json_serializable
build_runner
equatable
uuid
bcrypt
argon2
crypto
JWT packages
ORM/ODM packages

If implementation truly cannot proceed without another dependency:

STOP and report the reason before installing anything.

======================================================================
STEP 4 — CENTRALIZE COLLECTION NAMES
======================================================================

Create:

backend/lib/src/database/collection_names.dart

Use a small non-instantiable/final utility containing:

users = 'users'

Do not add names for every future conceptual collection yet.

Only add real collections as they are implemented.

======================================================================
STEP 5 — CREATE USER ROLE TYPE
======================================================================

Create an appropriate user-account model area, for example:

backend/lib/src/features/users/domain/user_role.dart

or an equivalently clear backend feature-oriented location.

Use:

enum UserRole {
  customer,
  cleaner,
  admin,
}

Provide explicit database serialization/parsing.

Do not persist enum.index.

Required behavior:

customer ↔ "customer"
cleaner  ↔ "cleaner"
admin    ↔ "admin"

Unknown database values must fail predictably.

Do not silently convert an unknown role to customer.

======================================================================
STEP 6 — CREATE ACCOUNT STATUS TYPE
======================================================================

Create:

AccountStatus

with:

active
suspended
deactivated

Persist explicit strings:

active
suspended
deactivated

Unknown values must fail predictably.

Do not overload this status with cleaner approval state.

======================================================================
STEP 7 — EMAIL NORMALIZATION
======================================================================

Create a small reusable function/value helper inside the users feature for
email normalization.

Behavior:

input:
"  Example.User@Example.COM  "

normalized:
"example.user@example.com"

Rules:

- trim
- lowercase

Nothing else.

Do not perform full email validation here.

Email syntax validation belongs to the future authentication/input-validation
layer.

Unit test this helper.

======================================================================
STEP 8 — CREATE USERACCOUNT MODEL
======================================================================

Create:

UserAccount

The model should represent persisted account data.

Fields:

ObjectId id
UserRole role
String email
String emailNormalized
String passwordHash
AccountStatus accountStatus
bool emailVerified
DateTime createdAt
DateTime updatedAt

Use immutable/final fields unless mutation is genuinely required.

Do not use nullable id for a persisted UserAccount.

If an unpersisted create-input object is needed later, it should be a separate
type rather than weakening the persisted model.

TASK 008 may introduce a separate:

CreateUserAccountData

only if it materially improves the repository API.

If used, it may contain:

role
email
passwordHash
accountStatus
emailVerified

but must still never contain plaintext password.

Do not create UI DTOs.

======================================================================
STEP 9 — BSON / MONGODB SERIALIZATION
======================================================================

Implement explicit conversion between MongoDB documents and UserAccount.

Example conceptual document:

{
  "_id": ObjectId(...),
  "role": "customer",
  "email": "Person@example.com",
  "email_normalized": "person@example.com",
  "password_hash": "<already-generated-hash>",
  "account_status": "active",
  "email_verified": false,
  "created_at": <Mongo/Dart DateTime representation>,
  "updated_at": <Mongo/Dart DateTime representation>
}

Requirements:

- _id must be ObjectId;
- timestamps must be UTC;
- role/status parsed explicitly;
- required missing fields fail predictably;
- wrong critical BSON types fail predictably;
- password_hash stays internal.

Do not catch every parsing error and silently invent defaults.

======================================================================
STEP 10 — PUBLIC SERIALIZATION
======================================================================

Provide a safe public representation method such as:

toPublicJson()

It may expose:

id
role
email
accountStatus
emailVerified
createdAt
updatedAt

It MUST NOT expose:

passwordHash
password_hash
emailNormalized unless specifically justified

Prefer not to expose emailNormalized publicly.

Add a test explicitly proving the public map does not contain password fields.

======================================================================
STEP 11 — MODEL DEBUG-SAFETY
======================================================================

If UserAccount overrides:

toString()

it MUST NOT include passwordHash.

Prefer a concise safe representation or no custom toString at all.

Add a test if a custom toString exists.

Do not create generic model logging containing all fields.

======================================================================
STEP 12 — USER REPOSITORY ABSTRACTION
======================================================================

Create a feature-level repository abstraction.

Example location:

backend/lib/src/features/users/data/user_repository.dart

or equivalent.

It should expose only capabilities needed by near-future authentication.

Initial methods:

Future<UserAccount?> findById(ObjectId id)

Future<UserAccount?> findByNormalizedEmail(String emailNormalized)

Future<bool> emailExists(String emailNormalized)

Future<UserAccount> create(...)

Do NOT add:

updateProfile
deleteUser
listAllUsers
searchUsers
banUser
admin pagination
password reset
session operations

yet.

For repository ergonomics, it is acceptable for find/emailExists to normalize
the caller's email internally if the method is named findByEmail instead.

Choose ONE coherent API and document it.

Avoid having ambiguous methods with inconsistent normalization responsibility.

======================================================================
STEP 13 — CREATE INPUT CONTRACT
======================================================================

If repository.create needs a creation input object, create:

CreateUserAccountData

with explicit fields.

Recommended:

UserRole role
String email
String passwordHash
AccountStatus accountStatus = active
bool emailVerified = false

The repository should derive:

email_normalized
created_at
updated_at
_id

rather than requiring callers to create those persistence concerns.

No plaintext password.

No admin restriction belongs here; future auth service will enforce whether
the caller is permitted to request a role.

======================================================================
STEP 14 — MONGODB USER REPOSITORY IMPLEMENTATION
======================================================================

Create:

MongoUserRepository

It should receive:

Db

or an appropriately narrow MongoDB dependency.

Do NOT have the repository read environment variables.

Do NOT have it construct MongoDatabase itself.

It should access:

CollectionNames.users

Implement only:

- find by id
- find/exists by normalized email
- create account

Create must:

- normalize the email;
- generate ObjectId;
- use UTC timestamps;
- insert one document;
- return the resulting UserAccount.

IMPORTANT:

Repository code may contain insertOne because this repository is the future
application persistence implementation.

However TASK 008 tests and live verification must NOT call create against the
real Atlas database.

No live user insertion is authorized in TASK 008.

======================================================================
STEP 15 — DUPLICATE EMAIL BEHAVIOR
======================================================================

The database unique index is the final concurrency-safe email uniqueness
boundary.

Do not rely only on:

find → then insert

because two concurrent signups could race.

Repository create should permit MongoDB's unique index to enforce the
constraint.

Introduce a small feature-specific exception such as:

DuplicateUserEmailException

only if needed to convert MongoDB duplicate-key errors into a stable repository
contract.

Do not build a giant generic exception hierarchy.

Do not expose raw MongoDB duplicate-key errors to future route layers.

If mapping duplicate-key behavior cleanly requires identifying MongoDB error
code 11000, do so carefully.

Tests should verify this mapping without real Atlas.

======================================================================
STEP 16 — DATABASE INDEX DEFINITION
======================================================================

Create a users-specific index initializer in an appropriate location, such as:

backend/lib/src/features/users/data/user_indexes.dart

or:

backend/lib/src/database/indexes/user_indexes.dart

It must create/ensure:

UNIQUE index:
email_normalized: 1

Give the index a stable explicit name, for example:

users_email_normalized_unique

Do not create speculative indexes.

Do not create:

role index
created_at index
account_status index

until query requirements justify them.

======================================================================
STEP 17 — INDEX INITIALIZATION ARCHITECTURE
======================================================================

Do not run ensureIndex on every request.

Create a small database bootstrap/index initialization boundary that can be
called deliberately at application startup/deployment or by a scoped setup
workflow.

If integrating index creation into server startup, ensure:

- it executes once per process;
- failure is handled deliberately;
- liveness behavior is considered;
- no index loop occurs per request.

However, because TASK 008 should avoid complicating normal liveness startup,
prefer a deliberate database initialization function/service that can later be
called from application startup in a controlled way.

Do not build a migration framework.

======================================================================
STEP 18 — INDEX TESTS WITHOUT REAL ATLAS
======================================================================

Test index specification/initializer behavior through an injection seam,
mock/fake, or otherwise safe unit approach.

Verify:

- collection = users;
- key = email_normalized ascending;
- unique = true;
- stable index name.

Do not contact real Atlas in unit tests.

Use existing test/mocktail dependencies if useful.

Do not add another mocking library.

======================================================================
STEP 19 — USER MODEL TESTS
======================================================================

Add comprehensive tests covering:

UserRole:
- all string mappings
- unknown input fails

AccountStatus:
- all string mappings
- unknown input fails

email normalization:
- whitespace
- uppercase
- already-normalized values

UserAccount BSON parsing:
- valid document
- ObjectId
- timestamps
- role/status
- required field missing
- invalid critical type where useful

public serialization:
- expected public fields
- password hash absent
- normalized email absent

timestamps:
- converted/retained as UTC

Use clearly fake emails and fake password hashes only.

======================================================================
STEP 20 — REPOSITORY TESTS
======================================================================

Tests must NOT contact real Atlas.

Test MongoUserRepository through a small collection abstraction/factory,
mocktail, or equivalent seam.

Verify at minimum:

find-by-id:
- found
- not found

find/emailExists:
- normalization behavior
- found/not found

create:
- generates _id
- normalizes email
- stores role/status explicitly
- stores provided password hash internally
- uses email_verified
- uses UTC created_at/updated_at
- returns persisted model

duplicate:
- Mongo duplicate key maps to DuplicateUserEmailException if that exception
  was adopted

public:
- repository return object does not cause automatic password exposure

Do not add a huge fake MongoDB implementation.

======================================================================
STEP 21 — REAL ATLAS INDEX VERIFICATION
======================================================================

Only after all unit tests pass:

Use the real locally configured Atlas database to ensure the approved index.

IMPORTANT:

Permitted live mutation:

create/ensure the unique users.email_normalized index only.

No user document insertion.

No user document update.

No delete.

No data dump.

Do not print backend/.env.

Do not print connection information.

Implement/use a narrowly scoped safe command or temporary script from backend/
that calls the user index initializer.

Prefer a permanent developer script if useful, for example:

backend/tool/ensure_database_indexes.dart

This script may become the controlled future database-index setup command.

If created, it must:

- use EnvironmentLoader;
- obtain ServerConfig;
- connect through MongoDatabase;
- ensure approved indexes;
- close the database;
- print only sanitized operational messages such as:
  "Database indexes ensured successfully."

It must NOT print:

- URI
- hostname
- credentials
- existing documents

Do NOT build a migration engine.

Run the command.

If Atlas index creation fails:

- do not weaken Atlas security;
- do not remove existing data;
- do not drop indexes automatically;
- do not delete documents;
- report a sanitized failure;
- mark task PARTIAL if necessary.

======================================================================
STEP 22 — SAFE INDEX VERIFICATION
======================================================================

Verify the expected index exists WITHOUT dumping user documents.

Using the driver, index metadata may be inspected if needed.

Do not enumerate application data.

Report only sanitized information such as:

users_email_normalized_unique exists
unique = true
key = email_normalized ascending

Do not report Atlas hostname or credentials.

If index verification requires listing indexes on the `users` collection,
that is permitted.

Do not list documents.

======================================================================
STEP 23 — VERIFY NO REAL USER DATA WAS CREATED
======================================================================

Verify TASK 008 live operations were index-management only.

Do not prove this by dumping documents.

Instead:

- inspect the executed live script/code;
- verify it contains no calls to repository.create;
- verify it invokes only index initialization and connection lifecycle.

Do not query/count user documents solely for this verification.

======================================================================
STEP 24 — DART FROG INTEGRATION
======================================================================

Do NOT add user routes in TASK 008.

Do NOT add UserRepository to every request context unless a real route needs it.

The repository architecture can exist without being wired globally yet.

Future authentication service/routes will compose it with MongoDatabase.

Preserve:

/
/api/v1/health
/api/v1/ready

No route changes are expected.

======================================================================
STEP 25 — DOCUMENT USERS COLLECTION
======================================================================

Create:

documentation/database/users-collection.md

Document:

## Purpose

Stores authentication/account identity records.

## Document Shape

Document safe field names/types:

_id
role
email
email_normalized
password_hash
account_status
email_verified
created_at
updated_at

Do NOT include a real hash.

## Roles

customer
cleaner
admin

Explain public registration of admin will be prohibited later.

## Account Status

active
suspended
deactivated

Explain cleaner approval is separate.

## Email Normalization

trim + lowercase.

## Indexes

users_email_normalized_unique

unique ascending email_normalized.

## Password Security

Only password hashes are stored.

No plaintext password.

Public serializers never expose password_hash.

## Current Operations

Repository supports only:

- lookup by id;
- lookup/existence by email;
- create account.

Clarify that no signup API exists yet.

## Deferred

- authentication service;
- password hashing;
- sessions;
- profiles;
- password reset;
- admin management;
- additional indexes.

======================================================================
STEP 26 — CREATE ADR-006
======================================================================

Create:

documentation/decisions/ADR-006-user-account-persistence-model.md

Use:

# ADR-006 — User Account Persistence Model

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

Authentication needs a stable MongoDB account model before HTTP signup/login
logic is implemented.

Decision:

- users collection;
- ObjectId _id;
- explicit UserRole strings;
- explicit AccountStatus strings;
- original + normalized email;
- unique email_normalized index;
- password hash persisted but never publicly serialized;
- repository abstraction + Mongo implementation;
- UTC timestamps.

Alternatives:

### Email uniqueness only in application code

Rejected because concurrent requests can race.

### Case-sensitive unique email only

Rejected because user lookup/registration should treat casing consistently.

### MongoDB case-insensitive collation instead of normalized field

Viable, but explicit normalized field is chosen for straightforward predictable
lookup/index behavior.

### Store role/status enum ordinal

Rejected because ordinal persistence is fragile when enum definitions change.

### One giant generic repository

Rejected because feature-specific repositories keep contracts explicit and
avoid speculative abstraction.

### Put customer/cleaner profile fields in users

Rejected/deferred because authentication identity and role-specific profile
data have different lifecycles.

Consequences:

- duplicate emails are database-enforced;
- future authentication has a clean persistence contract;
- password hashes remain sensitive internal data;
- profile collections will reference user _id later.

Deferred:

- password hashing algorithm;
- authentication service;
- signup/login routes;
- sessions/tokens;
- password resets;
- email verification mechanism;
- cleaner onboarding;
- customer/cleaner profiles;
- admin provisioning process.

======================================================================
STEP 27 — UPDATE DOCUMENTATION INDEXES
======================================================================

Update only as needed:

documentation/README.md
documentation/database/README.md
documentation/decisions/README.md
documentation/architecture/backend-api-architecture.md

Add links for:

database/users-collection.md
decisions/ADR-006-user-account-persistence-model.md

Do not document auth endpoints because they do not exist.

======================================================================
STEP 28 — UPDATE BACKEND README
======================================================================

Update:

backend/README.md

only enough to state:

- users persistence foundation now exists;
- unique normalized-email index exists;
- there are still no signup/login APIs;
- password hashing remains unimplemented;
- no real users were created by TASK 008.

Do not include secrets.

======================================================================
STEP 29 — FORMAT
======================================================================

From backend/:

dart format .

======================================================================
STEP 30 — ANALYZE
======================================================================

Run:

dart analyze

Must report no issues.

======================================================================
STEP 31 — TEST
======================================================================

Run:

dart test

All tests must pass.

Report exact test count.

No test may require real Atlas.

======================================================================
STEP 32 — ROUTE VERIFICATION
======================================================================

Run:

dart_frog list

Expected unchanged routes:

/
/api/v1/health
/api/v1/ready

There must be no:

/users
/auth
/signup
/login

routes.

======================================================================
STEP 33 — LIVE BACKEND HEALTH
======================================================================

If practical, start the backend only long enough to verify:

GET /api/v1/health → 200
GET /api/v1/ready  → 200

Do not invoke a user repository route because none exists.

Stop server afterward.

The existing non-TTY Dart Frog CLI warning may recur and should be reported
sanely.

======================================================================
STEP 34 — SECURITY AUDIT
======================================================================

Verify:

backend/.env remains ignored.

Do NOT print it.

Search new application source for accidental:

password
passwordHash
password_hash

Review each occurrence.

Expected legitimate locations include:

- persistence model;
- repository create input;
- BSON serialization;
- fake test data.

There must be no plaintext-password handling.

Search public serialization code to confirm password fields cannot escape.

Verify no real MongoDB URI/credential was introduced.

Verify no real user data was created by TASK 008.

======================================================================
STEP 35 — FLUTTER VERIFICATION
======================================================================

From repository root run:

git diff -- project/

Expected:

empty.

======================================================================
STEP 36 — REVIEW GIT CHANGES
======================================================================

Run:

git status --short
git diff -- backend/pubspec.yaml
git diff -- backend/pubspec.lock
git diff -- backend/lib/
git diff -- backend/routes/
git diff -- backend/test/
git diff -- backend/tool/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Expected areas:

backend/
documentation/

Root README only if genuinely required; otherwise leave it unchanged.

No Flutter implementation changes.

======================================================================
STEP 37 — CREATE TASK 008 REPORT
======================================================================

Create:

documentation/cursor/008_user_account_persistence_foundation.md

using:

documentation/cursor/task-report-template.md

The report MUST contain the COMPLETE EXACT TASK 008 prompt under:

## Exact Cursor Prompt

Document:

- clean starting checkpoint;
- pre-task tests/routes;
- no new dependency or any justified dependency;
- collection naming;
- UserRole;
- AccountStatus;
- email normalization;
- UserAccount;
- BSON serialization;
- safe public serialization;
- repository abstraction;
- MongoUserRepository;
- duplicate-email behavior;
- unique index definition;
- live index ensure/verification result;
- explicit confirmation that no real user was inserted;
- tests;
- analysis;
- route list;
- health/readiness verification;
- security checks;
- Flutter no-change verification;
- files created;
- files modified;
- files deleted;
- final Git status;
- unresolved issues.

Never include:

- backend/.env contents;
- MONGODB_URI;
- MongoDB credentials;
- real user documents;
- password hashes from real users.

======================================================================
STEP 38 — FINAL VERIFICATION
======================================================================

From backend/ run again:

dart analyze
dart test
dart_frog list

From repository root:

git status --short
git diff -- project/
git check-ignore -v backend/.env

Expected routes remain:

/
/api/v1/health
/api/v1/ready

All tests pass.

======================================================================
STEP 39 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 008 uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond with exactly these top-level sections:

# TASK 008 RESULT

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
- pre-task analyze result
- pre-task test count
- pre-task routes
- backend/.env ignore state

## Dependencies

State whether any new dependency was added.

If none:

None.

## User Account Model

Describe:

- UserRole
- AccountStatus
- UserAccount
- CreateUserAccountData if created
- email normalization
- ObjectId
- UTC timestamps

## Persistence Serialization

Describe BSON/document mapping and public JSON behavior.

Explicitly confirm password hash cannot appear in public JSON.

## Repository

Describe UserRepository and MongoUserRepository methods.

## Duplicate Email Protection

Describe application mapping and the database unique index.

## MongoDB Index

Report:

- collection
- index name
- field
- direction
- uniqueness
- live ensure result

Do not report cluster information.

## Live Data Safety

Confirm no real user document was inserted, modified, deleted, or dumped.

## Tests

List new/modified tests.

Report exact:

dart test

result and test count.

## Static Analysis

Report:

dart analyze

result.

## API Routes

Report final dart_frog list.

Confirm no user/auth route was added.

## Backend Health

Report sanitized health/readiness status if verified.

## Files Created

List TASK 008-created files.

## Files Modified

List TASK 008-modified files.

## Files Deleted

List TASK 008-deleted files.

## Documentation

Confirm creation of:

documentation/database/users-collection.md
documentation/decisions/ADR-006-user-account-persistence-model.md
documentation/cursor/008_user_account_persistence_foundation.md

## Flutter Verification

Report:

git diff -- project/

## Security Verification

Confirm:

- backend/.env remains ignored;
- no secret was exposed;
- no plaintext password handling exists;
- password_hash is persistence-only;
- public serialization excludes password fields;
- no real user data was created.

## Git Status

Provide final:

git status --short

## Issues / Warnings

Report relevant warnings.

If none:

None.

## Final Statement

State whether the user-account persistence foundation is complete and ready
for ChatGPT review.

Do NOT implement signup.

Do NOT implement login.

Do NOT begin TASK 009.

Start TASK 008 now.
````

## Pre-Task Repository State

Git root: `D:/freelance/erfankhan_cse489/final`

Branch: `main`

Latest commit: `7da3f6e mongodb_atlas_integration_foundation`

Working tree: clean

`backend/.env` existed (existence check only) and was ignored (`gitignore:8:.env`).

Required TASK 007 files existed.

Pre-task baseline from `backend/`:

- `dart analyze` — No issues found
- `dart test` — 31 tests passed
- `dart_frog list` — `/`, `/api/v1/health`, `/api/v1/ready`

## Work Performed

No new package was added.

Created `CollectionNames` with `users` only.

Created `UserRole` (`customer`, `cleaner`, `admin`) and `AccountStatus` (`active`, `suspended`, `deactivated`) with explicit lowercase wire strings. Unknown values fail.

Created `normalizeEmail` (trim + lowercase only).

Created persisted `UserAccount` (`ObjectId` `_id`, UTC timestamps) plus `CreateUserAccountData` for repository insert input. BSON mapping is explicit. `toPublicJson` omits `password_hash` and `email_normalized`. `toString` omits the hash.

Created `UserRepository` with `findById`, `findByEmail`, `emailExists`, and `create`. Email methods normalize internally.

Created `MongoUserRepository` over a `UserDocumentStore` seam. Duplicate MongoDB key code 11000 maps to `DuplicateUserEmailException`.

Created unique index spec `users_email_normalized_unique` on `email_normalized` and `tool/ensure_database_indexes.dart` for deliberate setup. Did not wire index creation per HTTP request.

Unit tests cover types, BSON, public JSON, repository, and index specification without contacting Atlas.

Live Atlas work created/verified the unique index only. No user documents were inserted.

Documentation: `users-collection.md`, ADR-006, indexes, backend README.

Flutter `project/` unchanged. Nothing staged or committed.

## Files Created

- `backend/lib/src/database/collection_names.dart`
- `backend/lib/src/database/database_indexes.dart`
- `backend/lib/src/features/users/domain/user_role.dart`
- `backend/lib/src/features/users/domain/account_status.dart`
- `backend/lib/src/features/users/domain/email_normalization.dart`
- `backend/lib/src/features/users/domain/user_account.dart`
- `backend/lib/src/features/users/domain/create_user_account_data.dart`
- `backend/lib/src/features/users/domain/user_account_exceptions.dart`
- `backend/lib/src/features/users/data/user_repository.dart`
- `backend/lib/src/features/users/data/user_document_store.dart`
- `backend/lib/src/features/users/data/mongo_user_repository.dart`
- `backend/lib/src/features/users/data/user_indexes.dart`
- `backend/tool/ensure_database_indexes.dart`
- `backend/test/src/features/users/domain/user_types_test.dart`
- `backend/test/src/features/users/domain/user_account_test.dart`
- `backend/test/src/features/users/data/user_indexes_test.dart`
- `backend/test/src/features/users/data/mongo_user_repository_test.dart`
- `documentation/database/users-collection.md`
- `documentation/decisions/ADR-006-user-account-persistence-model.md`
- `documentation/cursor/008_user_account_persistence_foundation.md`

## Files Modified

- `backend/README.md`
- `documentation/README.md`
- `documentation/database/README.md`
- `documentation/decisions/README.md`
- `documentation/architecture/backend-api-architecture.md`

## Files Deleted

None.

## Commands Executed

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status --short`
- `git status`
- `git log -7 --oneline`
- file-existence checks and `git check-ignore -v backend/.env`
- `backend/`: `dart pub get`, `dart analyze`, `dart test`, `dart_frog list`
- `backend/`: `dart format .`, `dart analyze`, `dart test`
- `backend/`: `dart run tool/ensure_database_indexes.dart`
- `backend/`: `dart_frog list`, `dart_frog dev` (non-TTY)
- sanitized `GET /api/v1/health` and `GET /api/v1/ready`
- stopped leftover port 8080 listener
- `git diff -- project/`
- post-report: `dart analyze`, `dart test`, `dart_frog list`

Never printed `backend/.env`. Never ran `git add`, `git commit`, or `git push`.

## Implementation Details

Users live under `lib/src/features/users/` with domain types and a Mongo-backed repository. Collection name `users` is centralized.

`MongoUserRepository.create` derives `_id`, `email_normalized`, and UTC timestamps. Callers supply role, email, and an already-produced password hash.

Duplicate uniqueness is enforced by the unique index; the repository maps driver code 11000 to `DuplicateUserEmailException`.

Index initialization is a deliberate function plus `tool/ensure_database_indexes.dart`. It is not invoked from request middleware.

No Dart Frog user/auth routes were added.

## Technical Decisions

- No new packages; `mongo_dart` ObjectId/BSON/collection APIs are sufficient.
- Explicit lowercase wire strings instead of enum indexes.
- `findByEmail` / `emailExists` normalize internally rather than exposing a separate normalized-email API.
- `UserDocumentStore` is a small test seam, not a generic repository framework.
- Index ensure uses `createIndex` with verification via `getIndexes` (index metadata only).

## Verification Performed

- Clean checkpoint and secret ignore checks
- Pre-task analyze/test/routes
- Format, analyze, tests
- Live unique-index ensure and sanitized verification
- Live health/ready
- Source review: live tool has no `repository.create`
- Password-field review of new application source
- Flutter diff empty
- No secrets staged

## Verification Results

- Pre-task: analyze clean; 31 tests; routes `/`, `/api/v1/health`, `/api/v1/ready`
- New dependency: none
- `dart analyze` — No issues found
- `dart test` — 59 tests passed
- `dart_frog list` unchanged; no `/users`, `/auth`, `/signup`, `/login`
- Live index: `users_email_normalized_unique exists`; unique = true; key = email_normalized ascending
- Live health HTTP 200 `ok`; ready HTTP 200 `ready`
- `git diff -- project/` empty

## Errors / Warnings

The first live index run failed with a sanitized message after `db.ensureIndex` received `Map<String, int>` (not `Map<String, dynamic>`). The initializer was corrected to pass `Map<String, dynamic>` and use `createIndex` plus index-metadata verification. The retry succeeded.

`dart_frog dev` again raised `StdinException` in this non-interactive shell. The child server still served health/ready. The leftover listener was stopped.

## Security / Secrets Check

- `backend/.env` was not printed, staged, or committed.
- No MongoDB URI, hostname, or credentials were added to tracked files.
- Password occurrences in new source are persistence fields, BSON keys, comments, and fake test hashes only.
- No plaintext password handling.
- `toPublicJson` excludes password fields and `email_normalized`.
- Live Atlas mutation was index ensure/verify only. No user documents were inserted, updated, deleted, or dumped.

## Git Diff Summary

Backend gained the users domain/repository/index tooling and tests. Documentation gained the users collection guide and ADR-006. Root README and Flutter were not changed. Changes remain uncommitted.

## Final Repository State

Branch `main`, TASK 008 files unstaged/untracked. `backend/.env` ignored. No commit created.

## Unresolved Issues

- Authentication service, password hashing, signup/login routes, sessions, profiles, and admin provisioning remain unimplemented by design.
- Dart Frog CLI still has the non-TTY `StdinException` limitation.

## Suggested Next Step

A later authentication task may add password hashing and signup/login routes on top of this repository contract. Do not implement that as part of TASK 008.
