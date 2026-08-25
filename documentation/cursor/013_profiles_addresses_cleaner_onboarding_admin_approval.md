# Cursor Task 013 — Customer Profiles, Addresses, Cleaner Onboarding, and Admin Approval Vertical Slice

## Metadata

- Task ID: 013
- Task title: Customer Profiles, Addresses, Cleaner Onboarding, and Admin Approval Vertical Slice
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Implement a large vertical slice for all three marketplace roles: customer profile and service-address CRUD with a profile-owned default pointer; cleaner onboarding lifecycle (draft/pending/approved/rejected) with atomic submit; administrator cleaner-approval queue with cursor pagination, detail, approve, and reject; persisted-user role authorization that does not trust a stale JWT role claim; Flutter role-aware dashboards and focused Riverpod controllers using the existing authenticated Dio. Do not implement bookings, payments, chat, reviews, cleaner services, availability, earnings, or discovery. Do not commit.

## Exact Cursor Prompt

```text
# TASK 013 — Customer Profiles, Addresses, Cleaner Onboarding, and Admin Approval Vertical Slice

Repository:

D:\freelance\erfankhan_cse489\final

TASK 012 must be committed before starting this task.

Current architecture:

Flutter
    ↓ HTTPS / REST
Dart Frog backend
    ↓
MongoDB Atlas

Current completed functionality includes:

- users persistence;
- Argon2id password security;
- signup/login/refresh/logout;
- rotating refresh sessions;
- access JWTs;
- protected Bearer authentication;
- GET /api/v1/account/me;
- DELETE /api/v1/account/sessions;
- Flutter secure token storage;
- automatic Bearer attachment;
- concurrency-safe single-flight token refresh;
- auth restoration;
- Riverpod auth state;
- role information in AuthUser;
- go_router authentication guards;
- login/signup/session UI.

Current backend baseline after TASK 012:

dart analyze:
clean

dart test:
217 passed

Current Flutter baseline after TASK 012:

flutter analyze:
clean

flutter test:
65 passed

TASK 013 is intentionally a LARGE vertical slice.

It must implement real marketplace account/profile behavior for all three
platform roles:

CUSTOMER:
- customer profile;
- service-address CRUD;
- default service address;
- customer dashboard/navigation.

CLEANER:
- cleaner profile;
- onboarding application;
- onboarding submission;
- onboarding lifecycle;
- rejected-application correction/resubmission;
- cleaner dashboard/navigation.

ADMIN:
- admin authorization;
- cleaner approval queue;
- cleaner application detail;
- approve;
- reject;
- admin dashboard/navigation.

Do NOT implement bookings, payments, chat, reviews, cleaner services, cleaner
availability, earnings, or service discovery yet.

======================================================================
NO NEW DEPENDENCY POLICY
======================================================================

TASK 013 should require:

NO new backend package
NO new Flutter package

Reuse existing:

BACKEND:
dart_frog
mongo_dart
hashlib
dart_jsonwebtoken

FLUTTER:
flutter_riverpod
go_router
dio
flutter_secure_storage

If a new package appears genuinely necessary:

STOP and report the blocker before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
DATA MODEL — CUSTOMER PROFILE
======================================================================

Create Mongo collection:

customer_profiles

Document shape:

{
  "_id": ObjectId,
  "user_id": ObjectId,
  "full_name": String,
  "phone_e164": String?,
  "default_address_id": ObjectId?,
  "created_at": DateTime,
  "updated_at": DateTime
}

Rules:

- exactly one customer profile per customer user;
- user_id references users._id conceptually;
- backend owns validation;
- timestamps UTC;
- phone optional;
- no password/token/session information;
- no email duplication in this collection.

Do NOT automatically create customer profile during signup.

GET profile may legitimately return:

profile: null

until user creates it.

======================================================================
DATA MODEL — ADDRESS
======================================================================

Create Mongo collection:

addresses

Document:

{
  "_id": ObjectId,
  "user_id": ObjectId,
  "label": String,
  "line1": String,
  "line2": String?,
  "city": String,
  "region": String,
  "postal_code": String,
  "country_code": String,
  "created_at": DateTime,
  "updated_at": DateTime
}

Do NOT store:

latitude
longitude
geocoding data
cleaner coordinates
booking information

yet.

Address ownership is always based on:

user_id

Never trust a user_id from Flutter.

Use authenticated user's persisted identity.

======================================================================
DEFAULT ADDRESS DESIGN
======================================================================

Do NOT put an is_default Boolean on every address.

The customer profile owns:

default_address_id

Reasons:

- one authoritative pointer;
- avoids multiple addresses becoming simultaneously default;
- no need for mass update when selecting another address.

Setting default:

1. verify address exists;
2. verify it belongs to authenticated customer;
3. set customer_profiles.default_address_id.

Deleting an address:

if it is currently the default:

1. clear default_address_id conditionally;
2. delete owned address.

Document that the clear + delete operation is not currently a MongoDB
multi-document transaction.

Do not leave a deliberately dangling default_address_id.

======================================================================
ADDRESS LIMIT
======================================================================

Maximum:

20 addresses per customer.

Before creation:

count owned addresses.

If already 20:

HTTP 409
address_limit_reached

This is an application-level product limit.

Do not claim it is a database-enforced limit.

======================================================================
DATA MODEL — CLEANER PROFILE / ONBOARDING
======================================================================

Create Mongo collection:

cleaner_profiles

Document:

{
  "_id": ObjectId,
  "user_id": ObjectId,
  "full_name": String,
  "phone_e164": String?,
  "bio": String,
  "years_experience": int,
  "service_area": String,
  "onboarding_status": String,
  "submitted_at": DateTime?,
  "reviewed_at": DateTime?,
  "reviewed_by": ObjectId?,
  "rejection_reason": String?,
  "created_at": DateTime,
  "updated_at": DateTime
}

Allowed onboarding_status values:

draft
pending
approved
rejected

Explicit wire values must be lowercase.

Create a proper enum/domain representation.

Do not scatter raw string literals throughout application logic.

======================================================================
CLEANER ONBOARDING LIFECYCLE
======================================================================

Initial profile creation:

draft

Allowed cleaner profile edit states:

draft
rejected

Locked from cleaner editing:

pending
approved

If pending:

cleaner waits for administrator decision.

If approved:

future service-profile management will be implemented later.

Do NOT silently downgrade approved cleaner to draft.

======================================================================
CLEANER SUBMISSION
======================================================================

Cleaner can submit onboarding when status is:

draft
rejected

Submission changes:

onboarding_status = pending
submitted_at = now UTC
updated_at = now UTC

On resubmission after rejection also clear:

rejection_reason
reviewed_at
reviewed_by

Do not create a second cleaner profile.

Do not create a second onboarding application document.

One cleaner profile owns the current onboarding lifecycle.

Submitting when:

pending
approved

must return:

409
invalid_onboarding_state

======================================================================
ADMIN REVIEW
======================================================================

Administrator may:

approve a pending cleaner

or:

reject a pending cleaner.

Approve:

onboarding_status = approved
reviewed_at = now UTC
reviewed_by = current admin user id
rejection_reason = null
updated_at = now UTC

Reject:

onboarding_status = rejected
reviewed_at = now UTC
reviewed_by = current admin user id
rejection_reason = supplied reason
updated_at = now UTC

Only:

pending

may be reviewed.

Attempting to approve/reject:

draft
approved
rejected

returns:

409
invalid_onboarding_state

Do NOT change users.role.

Cleaner remains role:

cleaner

before and after approval.

Do NOT suspend/deactivate user account when rejecting onboarding.

======================================================================
VALIDATION — FULL NAME
======================================================================

For customer and cleaner profiles:

- String required;
- trim leading/trailing whitespace;
- 2–100 Unicode code points;
- reject control characters;
- do not force ASCII;
- do not lowercase;
- do not uppercase.

Store trimmed human-readable value.

======================================================================
VALIDATION — PHONE
======================================================================

Phone is optional.

If supplied and non-empty:

require simplified E.164 form:

+ followed by 8–15 decimal digits total after +

Examples conceptually:

+8801...
+1415...

Do NOT:

- send OTP;
- verify ownership;
- strip country codes;
- invent a default country;
- store a second normalized phone field.

An empty/whitespace optional phone should become null.

======================================================================
VALIDATION — CLEANER BIO
======================================================================

Required.

After trimming:

20–1000 Unicode code points.

Do not accept HTML.

Treat it as plain text.

======================================================================
VALIDATION — EXPERIENCE
======================================================================

years_experience:

integer
0–50 inclusive

Do not accept:

string numbers
double values
negative values

======================================================================
VALIDATION — SERVICE AREA
======================================================================

Required String.

Trim.

2–120 Unicode code points.

This is currently human-readable service-area text.

Do NOT implement:

geofencing
maps
radius search
latitude/longitude
GIS

in TASK 013.

======================================================================
VALIDATION — ADDRESS
======================================================================

label:
1–40 Unicode code points after trim

line1:
1–120

line2:
optional, max 120

city:
1–80

region:
1–80

postal_code:
1–20

country_code:
exactly two ASCII alphabetic characters

Normalize country_code to uppercase.

Do not attempt complete international postal-code validation.

======================================================================
DATABASE INDEXES
======================================================================

Add deliberate index specifications.

customer_profiles:

1.
name:
customer_profiles_user_id_unique

key:
user_id: 1

unique:
true

cleaner_profiles:

1.
name:
cleaner_profiles_user_id_unique

key:
user_id: 1

unique:
true

2.
name:
cleaner_profiles_status_id

key:
onboarding_status: 1
_id: 1

addresses:

1.
name:
addresses_user_id

key:
user_id: 1

2.
name:
addresses_user_id_created_at

key:
user_id: 1
created_at: -1

Use the existing controlled index-management architecture.

Do not initialize indexes in request handlers.

======================================================================
LIVE DATABASE PERMISSION
======================================================================

TASK 013 MAY perform only this live Atlas mutation:

ensure the approved index definitions above.

It MAY inspect index metadata to verify them.

It MUST NOT:

insert customer profiles
insert cleaner profiles
insert addresses
update profiles
delete profiles
create test users
create test sessions
dump collections
enumerate private user documents

No live application-data mutation.

======================================================================
ROLE AUTHORIZATION PRINCIPLE
======================================================================

TASK 012 verifies Bearer JWTs.

TASK 013 must add reusable ROLE authorization.

Critical rule:

DO NOT authorize customer/cleaner/admin endpoints solely from the JWT's role
claim.

JWT role may be up to 15 minutes stale.

For a role-scoped request:

1. verify access token;
2. resolve authenticated user from users collection;
3. require account_status == active;
4. read CURRENT persisted user.role;
5. authorize against required role;
6. provide current authenticated user context to route.

This means persisted user state is authoritative for role authorization.

JWT principal remains authentication evidence.

======================================================================
ROLE FAILURE SEMANTICS
======================================================================

Invalid/missing token:

401
invalid_access_token

User missing:

401
invalid_access_token

Suspended/deactivated:

403
account_unavailable

Authenticated active user with wrong role:

403
forbidden

Safe body:

{
  "success": false,
  "error": {
    "code": "forbidden",
    "message": "You do not have permission to perform this action."
  }
}

Do not reveal unnecessary authorization internals.

======================================================================
BACKEND ROUTES — CUSTOMER
======================================================================

Add:

GET /api/v1/customer/profile
PUT /api/v1/customer/profile

GET /api/v1/customer/addresses
POST /api/v1/customer/addresses

GET /api/v1/customer/addresses/[addressId]
PUT /api/v1/customer/addresses/[addressId]
DELETE /api/v1/customer/addresses/[addressId]

PUT /api/v1/customer/addresses/[addressId]/default

Use Dart Frog's real dynamic-route convention after inspecting current
framework behavior.

Do not invent unsupported route syntax.

======================================================================
CUSTOMER PROFILE API
======================================================================

GET /api/v1/customer/profile

Customer role only.

If no profile:

200

{
  "success": true,
  "data": {
    "profile": null
  }
}

If profile exists:

return safe profile JSON.

PUT /api/v1/customer/profile

Body:

{
  "full_name": "...",
  "phone_e164": "..." | null
}

Upsert customer profile by authenticated user id.

Do not allow request body to provide:

user_id
default_address_id
created_at
updated_at

Those are backend-owned.

======================================================================
CUSTOMER ADDRESS API
======================================================================

GET /api/v1/customer/addresses

Return all owned addresses.

Sort:

created_at descending

This collection is capped by the 20-address product limit, so pagination is
not required yet.

Include:

is_default

in HTTP representation as a COMPUTED field by comparing each address id with
customer profile.default_address_id.

Do not persist is_default in address documents.

POST /api/v1/customer/addresses

Creates owned address.

If customer profile does not yet exist:

address creation may still succeed.

default address remains unset until explicitly selected.

Return:

201

GET individual:

ownership enforced.

Unknown/not-owned address:

404
address_not_found

Do not distinguish between nonexistent and belongs-to-another-user.

PUT individual:

replace editable address fields only.

Do not allow changing:

_id
user_id
timestamps

DELETE individual:

ownership enforced.

Return safe success.

PUT /default:

verify ownership.

If customer profile does not exist:

create minimal customer profile is NOT allowed because full_name is required.

Instead return:

409
customer_profile_required

User must create profile first.

Then update default_address_id.

======================================================================
BACKEND ROUTES — CLEANER
======================================================================

Add:

GET /api/v1/cleaner/profile
PUT /api/v1/cleaner/profile
POST /api/v1/cleaner/onboarding/submit

Cleaner role only.

GET:

profile may be null before onboarding begins.

PUT:

create/update draft onboarding information.

Allowed only when current status:

draft
rejected

If profile nonexistent:

create as draft.

Body:

{
  "full_name": "...",
  "phone_e164": "..." | null,
  "bio": "...",
  "years_experience": 3,
  "service_area": "..."
}

If status pending/approved:

409
cleaner_profile_locked

POST submit:

profile must exist.

If absent:

409
cleaner_profile_required

If valid state:

transition to pending.

Return updated safe profile.

======================================================================
BACKEND ROUTES — ADMIN
======================================================================

Add:

GET /api/v1/admin/cleaners

GET /api/v1/admin/cleaners/[userId]

POST /api/v1/admin/cleaners/[userId]/approve

POST /api/v1/admin/cleaners/[userId]/reject

Admin role only.

Do not expose these routes to customer or cleaner roles.

======================================================================
ADMIN CLEANER LIST
======================================================================

GET /api/v1/admin/cleaners

Query parameters:

status
limit
after

status:

optional

allowed:

draft
pending
approved
rejected

Default:

pending

limit:

default 20
minimum 1
maximum 50

after:

optional cleaner_profile ObjectId cursor

Sort:

onboarding_status filter
then _id ascending

Query conceptually:

onboarding_status == status
_id > after when cursor supplied

Response:

{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "..." | null
  }
}

Each item may include:

cleaner profile id
user id
full name
safe user email
onboarding status
submitted_at

Do NOT include:

password hash
email_normalized
session information

Avoid N+1 database queries if practical.

A repository/application batch lookup of user ids is preferred.

If mongo_dart limitations make a clean aggregate preferable, document the
choice.

======================================================================
ADMIN CLEANER DETAIL
======================================================================

GET /api/v1/admin/cleaners/[userId]

Return:

safe user account information
+
cleaner onboarding profile

Unknown user/profile:

404
cleaner_application_not_found

Do not expose password/security fields.

======================================================================
ADMIN APPROVE
======================================================================

POST /api/v1/admin/cleaners/[userId]/approve

No meaningful body required.

Approve only pending profile.

Return updated profile.

======================================================================
ADMIN REJECT
======================================================================

POST /api/v1/admin/cleaners/[userId]/reject

Body:

{
  "reason": "..."
}

Reason:

required
trim
5–500 Unicode code points

Reject only pending profile.

Return updated profile.

Do not expose reviewer security information beyond safe reviewer id if the
response needs it.

======================================================================
BACKEND ARCHITECTURE
======================================================================

Use domain-oriented implementation.

Suggested structure:

backend/lib/src/features/customer_profiles/
backend/lib/src/features/addresses/
backend/lib/src/features/cleaner_profiles/
backend/lib/src/features/authorization/

Each feature should contain only useful layers such as:

domain/
data/
application/
http/

Do not mechanically create empty folders.

Required repository abstractions should be narrow.

Examples:

CustomerProfileRepository
AddressRepository
CleanerProfileRepository

Do not expose arbitrary Mongo update maps to application services.

======================================================================
CUSTOMER PROFILE REPOSITORY
======================================================================

Support narrowly:

findByUserId
upsertProfile
setDefaultAddress
clearDefaultAddressIfMatches

Use atomic single-document operations where possible.

Duplicate profile creation must map safely from Mongo duplicate-key behavior.

======================================================================
ADDRESS REPOSITORY
======================================================================

Support:

countForUser
listForUser
findOwnedById
create
updateOwned
deleteOwned

Every read/update/delete ownership query must contain:

_id
AND
user_id

Do not:

find by id
then separately compare user id

when Mongo can enforce ownership in the selector.

This avoids authorization TOCTOU mistakes.

======================================================================
CLEANER PROFILE REPOSITORY
======================================================================

Support:

findByUserId
create/update editable profile
submit atomically
listByStatusPage
approvePendingAtomically
rejectPendingAtomically

Submission/review state transitions MUST use conditional Mongo selectors.

For example approve selector conceptually includes:

user_id == target
onboarding_status == pending

Do NOT:

read status
then unconditional update

for state transitions.

Avoid race conditions.

If conditional update matches no document:

resolve whether profile is missing vs invalid state safely through repository
or application logic.

======================================================================
CUSTOMER APPLICATION SERVICE
======================================================================

Create HTTP-independent customer application service.

Responsibilities:

get profile
upsert profile
list addresses
get address
create address
update address
delete address
set default address

It receives authenticated persisted user identity from the authorization
boundary.

Do not accept arbitrary userId from HTTP body.

======================================================================
CLEANER ONBOARDING SERVICE
======================================================================

Create HTTP-independent CleanerOnboardingService.

Responsibilities:

getProfile
saveProfile
submit

Enforce lifecycle centrally.

Do not duplicate state rules in route handlers.

======================================================================
ADMIN CLEANER REVIEW SERVICE
======================================================================

Create HTTP-independent AdminCleanerReviewService.

Responsibilities:

listApplications
getApplication
approve
reject

It receives:

currentAdminUserId

for review metadata.

Do not put Mongo queries directly in admin route handlers.

======================================================================
BACKEND HTTP HANDLERS
======================================================================

Keep handlers thin.

Responsibilities:

- method handling;
- query/body parsing;
- request DTO validation;
- call application service;
- map application errors;
- safe JSON serialization.

Do not put:

Mongo queries
state-transition rules
authorization policy
business validation

directly into handlers.

======================================================================
HTTP METHOD RULE
======================================================================

Unsupported method:

405

Keep Allow header if existing project convention supports it.

Malformed JSON:

400

Wrong data types:

400

No raw exceptions.

======================================================================
ROLE MIDDLEWARE
======================================================================

Create reusable role middleware/composition for:

customer
cleaner
admin

Do not copy/paste full Bearer authentication logic three times.

Possible architecture:

AccessAuthenticator
    ↓
CurrentAuthenticatedUserResolver
    ↓
RoleAuthorizer

or equivalent.

Provide a safe context object containing:

AuthenticatedPrincipal
UserAccount currentUser

Do not place passwordHash in a public principal DTO.

If the internal UserAccount object reaches context, make sure it is never
serialized implicitly.

======================================================================
BACKEND TESTS — AUTHORIZATION
======================================================================

Test:

- valid customer on customer route allowed;
- cleaner on customer route → 403;
- admin on customer route → 403;
- customer on cleaner route → 403;
- admin on cleaner route → 403;
- customer on admin route → 403;
- cleaner on admin route → 403;
- admin on admin route allowed;
- suspended current user → 403;
- deactivated current user → 403;
- user deleted after JWT issue → 401;
- stale JWT role does not override current persisted role.

That final stale-role test is mandatory.

======================================================================
BACKEND TESTS — CUSTOMER PROFILE
======================================================================

Test:

GET no profile
GET existing
PUT creates
PUT updates
validation failures
phone null handling
safe serialization
wrong role
unauthorized

No Atlas.

======================================================================
BACKEND TESTS — ADDRESS
======================================================================

Test:

create
20-address limit
list ordering
computed is_default
get owned
foreign address → 404
update owned
foreign update → 404
delete owned
foreign delete → 404
set default
foreign default → 404
set default without customer profile → 409
delete default clears customer profile pointer
country code normalization

No Atlas.

======================================================================
BACKEND TESTS — CLEANER ONBOARDING
======================================================================

Test:

no profile
create draft
update draft
rejected profile editable
pending locked
approved locked
submit draft → pending
submit rejected → pending and clears old review metadata
submit pending → 409
submit approved → 409
missing profile submit → 409
validation
wrong role

No Atlas.

======================================================================
BACKEND TESTS — ADMIN REVIEW
======================================================================

Test:

pending list default
status filter
limit validation
cursor parsing
pagination
safe list data
detail
missing application
approve pending
approve non-pending → 409
reject pending
rejection reason validation
reject non-pending → 409
reviewed_by current admin
atomic state transition behavior
wrong role

No Atlas.

======================================================================
BACKEND INDEX TESTS
======================================================================

Extend controlled index specifications.

Unit-test:

names
keys
unique options

for all four new index definitions.

No Atlas in automated tests.

======================================================================
LIVE INDEX ENSURE
======================================================================

Only after:

dart analyze
dart test

are completely green:

run the existing controlled index ensure tool.

Ensure only approved TASK 013 indexes.

Verify index metadata.

Do not enumerate documents.

Do not insert documents.

If live index ensure fails:

report exactly.

Do not drop unrelated indexes.

Do not retry destructive operations.

======================================================================
FLUTTER ROLE ROUTING
======================================================================

TASK 012 currently has authenticated:

/home

TASK 013 must establish role-aware authenticated destinations:

/customer/home
/cleaner/home
/admin/home

Keep:

/splash
/login
/signup

Root `/` may redirect.

`/home` may remain as a compatibility redirect to role-specific home.

Rules:

restoring:
→ /splash

unauthenticated:
→ /login

authenticated customer:
→ /customer/home

authenticated cleaner:
→ /cleaner/home

authenticated admin:
→ /admin/home

Authenticated user trying another role's route must be redirected to their
own home.

Backend authorization remains authoritative.

Router guard is UX/navigation protection only.

======================================================================
FLUTTER FEATURE STRUCTURE
======================================================================

Add focused feature areas such as:

project/lib/features/customer/
project/lib/features/addresses/
project/lib/features/cleaner/
project/lib/features/admin/

Reuse:

AuthUser
authenticated Dio
Riverpod
go_router

Do not create another networking layer.

Do not create another token system.

Do not duplicate authenticated Dio.

======================================================================
FLUTTER CUSTOMER API
======================================================================

Create typed API/repository boundaries for:

customer profile
addresses

Use authenticated Dio.

Models should mirror only safe client fields.

CustomerProfile:

id
userId
fullName
phoneE164
defaultAddressId
createdAt
updatedAt

Address:

id
label
line1
line2
city
region
postalCode
countryCode
isDefault
createdAt
updatedAt

Do not expose internal Mongo details.

======================================================================
FLUTTER CLEANER API
======================================================================

CleanerProfile model:

id
userId
fullName
phoneE164
bio
yearsExperience
serviceArea
onboardingStatus
submittedAt
reviewedAt
reviewedBy
rejectionReason
createdAt
updatedAt

Represent onboardingStatus with a client enum:

draft
pending
approved
rejected

Handle unknown server value safely.

Do not crash entire app on unexpected enum.

======================================================================
FLUTTER ADMIN API
======================================================================

Create:

AdminCleanerApplicationSummary
AdminCleanerApplicationDetail
paginated response model

Operations:

listCleaners
getCleaner
approve
reject

Use authenticated Dio.

Do not expose admin APIs through plain Dio.

======================================================================
CUSTOMER PROFILE STATE
======================================================================

Use Riverpod.

Create controller/state for:

loading profile
profile absent
profile available
saving
safe error

Do not mix address list state into one huge monolithic AuthController.

AuthController remains authentication/session state only.

======================================================================
ADDRESS STATE
======================================================================

Create a focused address controller.

Operations:

load
create
update
delete
setDefault

After successful changes:

state must remain coherent without requiring app restart.

You may reload the small <=20 item list after mutation.

Do not over-engineer optimistic updates unless clearly beneficial.

======================================================================
CLEANER ONBOARDING STATE
======================================================================

Create cleaner onboarding controller.

Operations:

load
save
submit

State should represent:

no profile
draft
pending
approved
rejected
loading
saving
submitting
safe error

Do not duplicate backend lifecycle rules unnecessarily.

Backend remains authoritative.

======================================================================
ADMIN APPROVAL STATE
======================================================================

Create admin cleaner-review controller/state.

Support:

pending page load
status filtering
load-more using next_cursor
application detail
approve
reject

After approve/reject:

remove/update item in current queue coherently.

Do not require full app restart.

======================================================================
CUSTOMER HOME SCREEN
======================================================================

Create real:

CustomerHomeScreen

Keep UI functional but not final-polish.

Show:

- marketplace title;
- signed-in customer email;
- profile completion state;
- default address summary if one exists.

Actions:

Manage Profile
Manage Addresses
Log out
Log out all devices

Do NOT show:

fake cleaner listings
fake bookings
fake promotions

yet.

======================================================================
CUSTOMER PROFILE SCREEN
======================================================================

Fields:

Full name
Phone (optional E.164)

Load existing values.

Save through customer profile controller.

Validation should mirror simple backend rules.

Backend remains authoritative.

Display safe errors.

======================================================================
CUSTOMER ADDRESS LIST SCREEN
======================================================================

Show owned addresses.

Each card:

label
line1
city/region
country code
Default indicator when computed is_default is true

Actions:

Add
Edit
Set Default
Delete

Require a simple confirmation before delete.

Do not implement maps.

======================================================================
ADDRESS FORM SCREEN
======================================================================

Fields:

Label
Address line 1
Address line 2 optional
City
Region
Postal code
Country code

Country code:

two letters

Normalize visually/server-side as appropriate.

No autocomplete dependency.

No geocoding.

======================================================================
CLEANER HOME SCREEN
======================================================================

Create:

CleanerHomeScreen

Show:

email
onboarding status

Behavior:

No profile:
→ "Start onboarding"

Draft:
→ "Continue onboarding"

Pending:
→ pending-review message

Rejected:
→ rejection reason + "Edit and resubmit"

Approved:
→ approval message

For approved:

state clearly that service/availability setup comes next.

Do NOT implement cleaner services yet.

Include:

logout
logout all devices

======================================================================
CLEANER ONBOARDING SCREEN
======================================================================

Fields:

Full name
Phone optional
Bio
Years of experience
Service area

If status:

draft/rejected:
editable

pending/approved:
read-only or route should not expose editing controls

For rejected:

show rejection reason clearly.

Actions in editable state:

Save
Submit for Review

Submission should require saved valid profile.

A reasonable implementation may save then submit only after explicit user
confirmation.

Do not auto-submit every edit.

======================================================================
ADMIN HOME SCREEN
======================================================================

Create:

AdminHomeScreen

Show:

Admin Dashboard
signed-in admin email

Primary functionality:

Cleaner Approvals

Show pending count only if already available without an extra expensive query;
otherwise simply show navigation to approvals.

Do NOT build:

full analytics
user management
booking disputes
payment oversight

yet.

======================================================================
ADMIN CLEANER APPROVAL LIST
======================================================================

Create:

CleanerApprovalListScreen

Default filter:

Pending

Support status filter:

Pending
Approved
Rejected

Draft may optionally be available to admin but should not be the default.

Load first page.

Support:

Load More

only when next_cursor exists.

Each item displays:

full name
email
status
submitted date

No password/security data.

======================================================================
ADMIN CLEANER DETAIL
======================================================================

Create:

CleanerApprovalDetailScreen

Display:

full name
email
phone
bio
experience
service area
status
submitted date
review information if available

If pending:

Approve
Reject

Reject requires a dialog/form with reason.

Confirm approve action.

After success:

update UI and return/refetch list coherently.

======================================================================
NO ADMIN SIGNUP
======================================================================

Do NOT change existing signup.

Admin remains prohibited from public registration.

TASK 013 only supports an already-provisioned admin account.

Automated tests may use fake admin AuthUser/UserAccount.

Do not create a real Atlas admin user.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Add feature-specific safe client failures only where useful.

Handle backend codes such as:

forbidden
account_unavailable
customer_profile_required
address_not_found
address_limit_reached
cleaner_profile_required
cleaner_profile_locked
invalid_onboarding_state
cleaner_application_not_found
invalid_input

Do not show:

DioException.toString()
stack trace
Mongo message
raw backend exception

to users.

======================================================================
AUTH SESSION INTEGRATION
======================================================================

All new authenticated API calls use TASK 012 authenticated Dio.

Therefore:

expired access token
→ existing single-flight refresh
→ retry once
→ continue feature request

Do not implement another refresh coordinator.

Add at least one integration-style Flutter test proving a new protected feature
API benefits from the existing authenticated Dio/refresh mechanism rather than
using plain Dio.

======================================================================
FLUTTER TESTS — ROLE ROUTER
======================================================================

Test:

customer login/session → customer home
cleaner → cleaner home
admin → admin home

customer opening cleaner/admin route:
→ customer home

cleaner opening customer/admin route:
→ cleaner home

admin opening customer/cleaner route:
→ admin home

logout:
→ login

session expiry:
→ login

======================================================================
FLUTTER TESTS — CUSTOMER
======================================================================

Profile:

load absent
load existing
save
safe error

Addresses:

load
create
edit
delete
set default
address limit error
foreign/not-found mapping
default UI indicator

Widget tests:

CustomerHome
CustomerProfile
AddressList
AddressForm

No real network.

======================================================================
FLUTTER TESTS — CLEANER
======================================================================

Controller:

load null
draft
pending
approved
rejected
save
submit
safe error

Widgets:

no-profile CTA
draft edit
pending read-only/status
rejected reason
approved state

No real backend.

======================================================================
FLUTTER TESTS — ADMIN
======================================================================

Controller:

pending list
filter
pagination
detail
approve
reject
safe error

Widgets:

approval list
status filter
detail
approve confirmation
reject reason validation

No real backend.

======================================================================
SECRET / PRIVACY RULES
======================================================================

Never print:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
password
access JWT
refresh token
token hashes
real Atlas documents

Do not store secret/backend credentials in Flutter.

Phone/profile/address values from fake tests are allowed but use obviously fake
data.

Do not put real user information into documentation.

======================================================================
STEP 1 — CLEAN CHECKPOINT
======================================================================

Before any implementation run:

git rev-parse --show-toplevel
git branch --show-current
git status --short
git status
git log -10 --oneline

Expected:

root:
D:\freelance\erfankhan_cse489\final

branch:
main

working tree:
clean

Latest commit must be the TASK 012 checkpoint.

Verify TASK 012 report status is SUCCESS.

Verify:

backend/.env

ignored:

git check-ignore -v backend/.env

Do not print it.

If working tree is not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE
======================================================================

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

217 tests pass
0 fail

If not:

STOP.

Record route list.

======================================================================
STEP 3 — FLUTTER BASELINE
======================================================================

From project/:

flutter pub get
flutter analyze
flutter test

Expected:

65 tests pass

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT
======================================================================

Inspect:

backend/pubspec.yaml
project/pubspec.yaml

Expected new direct dependencies:

none.

If implementation genuinely requires a new dependency:

STOP and report first.

======================================================================
STEP 5 — IMPLEMENT DOMAIN MODELS
======================================================================

Implement:

CustomerProfile
Address
CleanerProfile
CleanerOnboardingStatus

with:

explicit BSON conversion
explicit public JSON conversion
UTC dates
safe toString behavior

Do not allow security fields.

Add model tests.

======================================================================
STEP 6 — IMPLEMENT COLLECTION NAMES / INDEXES
======================================================================

Add:

customer_profiles
cleaner_profiles
addresses

to collection-name constants.

Add approved index specs to existing database index infrastructure.

Add unit tests.

Do not run live index ensure yet.

======================================================================
STEP 7 — IMPLEMENT REPOSITORIES
======================================================================

Implement narrow repository contracts and Mongo implementations for:

CustomerProfileRepository
AddressRepository
CleanerProfileRepository

Use test seams consistent with existing project architecture.

Add repository tests using fakes/in-memory document-store seams.

Do not contact Atlas.

======================================================================
STEP 8 — IMPLEMENT ROLE AUTHORIZATION
======================================================================

Implement reusable persisted-user role authorization.

Reuse TASK 012 Bearer authentication.

Ensure stale JWT role cannot grant access after persisted role changes.

Add authorization tests.

======================================================================
STEP 9 — IMPLEMENT APPLICATION SERVICES
======================================================================

Implement:

CustomerAccountService
CleanerOnboardingService
AdminCleanerReviewService

or equivalently clear names.

Keep HTTP independent.

Add comprehensive service tests.

======================================================================
STEP 10 — IMPLEMENT CUSTOMER ROUTES
======================================================================

Implement all approved customer routes.

Add route middleware and tests.

No real Atlas.

======================================================================
STEP 11 — IMPLEMENT CLEANER ROUTES
======================================================================

Implement all approved cleaner routes.

Add route middleware and tests.

No real Atlas.

======================================================================
STEP 12 — IMPLEMENT ADMIN ROUTES
======================================================================

Implement all approved admin routes.

Add route middleware and tests.

No real Atlas.

======================================================================
STEP 13 — BACKEND FORMAT / ANALYZE / TEST
======================================================================

Run:

dart format .
dart analyze
dart test
dart_frog list

Everything must pass before any Atlas index operation.

Record exact new backend test count.

======================================================================
STEP 14 — LIVE INDEX ENSURE
======================================================================

Run only existing controlled index-management tool.

Ensure new:

customer profile
cleaner profile
address

indexes.

Verify metadata.

Do not inspect application documents.

Do not insert application data.

Record success/failure.

======================================================================
STEP 15 — FLUTTER DATA LAYER
======================================================================

Implement:

customer profile API/repository
address API/repository
cleaner API/repository
admin cleaner-review API/repository

using existing authenticated Dio.

No new Dio instance for each feature unless current architecture requires a
lightweight wrapper over the shared authenticated client.

======================================================================
STEP 16 — FLUTTER CONTROLLERS
======================================================================

Implement focused Riverpod controllers for:

customer profile
addresses
cleaner onboarding
admin cleaner review

Keep AuthController focused on authentication.

======================================================================
STEP 17 — ROLE-AWARE ROUTER
======================================================================

Implement role destinations and guards.

Keep existing auth restoration/session behavior.

Add router tests.

======================================================================
STEP 18 — CUSTOMER UI
======================================================================

Implement:

CustomerHomeScreen
CustomerProfileScreen
CustomerAddressListScreen
CustomerAddressFormScreen

Functional low-fidelity Material 3 only.

======================================================================
STEP 19 — CLEANER UI
======================================================================

Implement:

CleanerHomeScreen
CleanerOnboardingScreen

Correct lifecycle-dependent UI.

======================================================================
STEP 20 — ADMIN UI
======================================================================

Implement:

AdminHomeScreen
CleanerApprovalListScreen
CleanerApprovalDetailScreen

Include approve/reject flows.

======================================================================
STEP 21 — FLUTTER TEST SUITE
======================================================================

Add:

model/API tests
repository tests
controller tests
router tests
widget tests
protected networking integration-style tests using fakes/adapters

No real network.

Run:

dart format lib test
flutter analyze
flutter test

Record exact final Flutter test count.

======================================================================
STEP 22 — ANDROID DEBUG BUILD
======================================================================

Run:

flutter build apk --debug

Must succeed.

Do not modify signing.

Do not weaken release network security.

======================================================================
STEP 23 — SAFE LIVE BACKEND REGRESSION
======================================================================

Start backend only long enough to verify:

GET /
GET /api/v1/health
GET /api/v1/ready

Expected:

200
200
200

Do NOT call customer/cleaner/admin feature routes against real Atlas.

Do NOT create live profile/address/onboarding fixtures.

Stop server afterward.

Known non-TTY StdinException may be reported if GET verification succeeds.

======================================================================
STEP 24 — DOCUMENT DATABASE COLLECTIONS
======================================================================

Create:

documentation/database/customer-profiles-collection.md
documentation/database/cleaner-profiles-collection.md
documentation/database/addresses-collection.md

Document:

fields
ownership
indexes
lifecycle
default-address pointer design
state-transition concurrency
no live fixture policy

======================================================================
STEP 25 — DOCUMENT API
======================================================================

Create:

documentation/api/profile-address-onboarding-admin-api.md

Document all TASK 013 endpoints:

customer
cleaner
admin

Include:

request examples with fake data
safe response shapes
status codes
role requirements
pagination
state conflicts

No secrets.

======================================================================
STEP 26 — DOCUMENT ARCHITECTURE
======================================================================

Create:

documentation/architecture/profile-address-and-cleaner-onboarding.md

Document:

authenticated request
→ JWT verification
→ persisted user resolution
→ role authorization
→ application service
→ repository
→ MongoDB

Customer flow.

Address flow.

Cleaner onboarding lifecycle.

Admin review flow.

Flutter role routing/state architecture.

======================================================================
STEP 27 — ADR-011
======================================================================

Create:

documentation/decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md

Sections:

# ADR-011 — Role-Scoped Profiles, Addresses, and Cleaner Onboarding

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must cover:

- separate customer_profiles and cleaner_profiles collections;
- separate addresses collection;
- one customer profile per customer;
- one cleaner profile per cleaner;
- default address pointer on customer profile;
- maximum 20 customer addresses;
- cleaner lifecycle draft/pending/approved/rejected;
- conditional atomic state transitions;
- persisted current UserAccount role used for authorization;
- JWT role not trusted as sole authorization source;
- admin review metadata;
- cursor-based admin approval listing;
- no admin public signup;
- Flutter role-aware dashboards.

Alternatives:

### Store profile fields directly on users
Rejected because role-specific data/lifecycle would overload security identity.

### Persist is_default on every address
Not selected because a profile pointer provides one authoritative default.

### Create one onboarding record per submission
Not selected for current workflow; one cleaner profile carries current lifecycle.

### Authorize only using JWT role
Rejected because claims can become stale before access-token expiry.

### Read status then perform unconditional onboarding update
Rejected due concurrency race.

### Allow cleaner edits while pending
Rejected for current review integrity.

Deferred:

- verification-document uploads;
- cleaner service catalog;
- cleaner availability;
- booking;
- payment;
- chat;
- review;
- admin user management;
- disputes;
- geospatial search;
- address geocoding;
- phone verification.

======================================================================
STEP 28 — UPDATE DOCUMENTATION INDEXES
======================================================================

Update only as necessary:

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

Do not claim deferred functionality exists.

======================================================================
STEP 29 — SECURITY AUDIT
======================================================================

Backend:

Confirm:

- body user_id values cannot override authenticated owner;
- address ownership enforced in Mongo selectors;
- current persisted role drives authorization;
- stale JWT role test passes;
- cleaner transitions conditional/atomic;
- no password/hash/token fields serialized;
- admin cannot be public-signup;
- admin review does not change users.role;
- no live application data mutated.

Flutter:

Confirm:

- feature calls use authenticated Dio;
- no extra refresh implementation;
- no token/password logging;
- no backend secret;
- no Mongo URI;
- role guard is UX only;
- backend remains authorization authority.

======================================================================
STEP 30 — FINAL BACKEND VERIFICATION
======================================================================

From backend/:

dart analyze
dart test
dart_frog list

All must pass.

Report exact final backend test count.

Report complete route list.

======================================================================
STEP 31 — FINAL FLUTTER VERIFICATION
======================================================================

From project/:

flutter analyze
flutter test
flutter build apk --debug

All must pass.

Report exact test count.

======================================================================
STEP 32 — FINAL GIT REVIEW
======================================================================

From repository root:

git status --short
git check-ignore -v backend/.env

Inspect:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm no:

.env
secret
SDK junction
APK
build directory
test fixture data
unrelated feature

is tracked.

Do NOT stage.

======================================================================
STEP 33 — TASK REPORT
======================================================================

Create:

documentation/cursor/013_profiles_addresses_cleaner_onboarding_admin_approval.md

Use the existing task report template.

The report MUST contain the COMPLETE EXACT TASK 013 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 012 checkpoint;
- baseline test counts;
- dependency audit;
- data models;
- repository design;
- indexes;
- role authorization;
- stale JWT role protection;
- customer profile API;
- address API;
- cleaner onboarding API;
- admin review API;
- onboarding lifecycle;
- atomic transitions;
- admin pagination;
- Flutter data layer;
- Riverpod controllers;
- role router;
- customer screens;
- cleaner screens;
- admin screens;
- backend tests and exact count;
- Flutter tests and exact count;
- index ensure result;
- debug APK result;
- safe live health results;
- security audit;
- files created;
- files modified;
- files deleted;
- documentation;
- final git status;
- issues/warnings.

Never include:

backend/.env contents
MONGODB_URI
ACCESS_TOKEN_SECRET
passwords
JWTs
refresh tokens
token hashes
real customer data
real cleaner data
real admin data
real addresses
Atlas document dumps

======================================================================
STEP 34 — DO NOT COMMIT
======================================================================

Do NOT run:

git add
git commit
git push

Leave TASK 013 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 013 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:

- repository root
- branch
- clean starting tree
- TASK 012 checkpoint commit
- backend baseline
- Flutter baseline
- .env ignored

## Dependencies

Confirm no new direct backend or Flutter package.

## Database Models

Summarize:

CustomerProfile
Address
CleanerProfile

## MongoDB Indexes

List exact TASK 013 indexes and live ensure result.

## Role Authorization

Describe:

Bearer authentication
persisted UserAccount resolution
active-state enforcement
current-role enforcement
stale-JWT-role protection

## Customer Profile

Describe API and behavior.

## Customer Addresses

Describe CRUD, ownership, limit, and default-address design.

## Cleaner Onboarding

Describe lifecycle and application behavior.

## Admin Cleaner Review

Describe:

list
pagination
detail
approve
reject

## Atomic State Transitions

Describe conditional submit/approve/reject behavior.

## Backend Tests

Report:

dart analyze
exact dart test count
Atlas-free automated tests

## Backend Routes

Provide complete dart_frog list.

## Flutter Customer Experience

Describe:

home
profile
addresses

## Flutter Cleaner Experience

Describe:

home
onboarding lifecycle UI

## Flutter Admin Experience

Describe:

dashboard
approval list
approval detail
approve/reject

## Flutter Role Routing

Describe customer/cleaner/admin guards.

## Flutter Tests

Report exact count and major coverage.

## Flutter Static Analysis

Report result.

## Android Debug Build

Report result.

## Live Backend Verification

Report only:

GET /
GET /api/v1/health
GET /api/v1/ready

Confirm no feature route was invoked live.

## Live Data Safety

Confirm:

no profile/address/onboarding/admin application documents were created,
updated, deleted, or dumped.

Only approved index metadata mutation was performed.

## Files Created

List.

## Files Modified

List.

## Files Deleted

List.

## Documentation

Confirm creation of:

documentation/database/customer-profiles-collection.md
documentation/database/cleaner-profiles-collection.md
documentation/database/addresses-collection.md
documentation/api/profile-address-onboarding-admin-api.md
documentation/architecture/profile-address-and-cleaner-onboarding.md
documentation/decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md
documentation/cursor/013_profiles_addresses_cleaner_onboarding_admin_approval.md

## Security Verification

Confirm:

- no body user_id ownership override;
- address selectors enforce ownership;
- persisted role drives authorization;
- stale JWT role cannot grant access;
- conditional onboarding transitions;
- no security fields exposed;
- no token/password logging;
- no secret in Flutter;
- backend/.env ignored.

## Git Status

Provide final git status --short.

## Issues / Warnings

List all remaining issues.

## Final Statement

State whether the customer profile + address + cleaner onboarding + admin
approval vertical slice is complete and ready for ChatGPT review.

Do NOT implement bookings.

Do NOT implement payments.

Do NOT implement chat.

Do NOT implement cleaner services/availability.

Do NOT begin TASK 014.

Start TASK 013 now.
```

## Pre-Task Repository State

- Repository root: D:\freelance\erfankhan_cse489\final
- Branch: main
- Working tree: clean before implementation
- Latest commit: 2777c9b protected_backend_and_flutter_auth_vertical_slice (TASK 012 checkpoint)
- TASK 012 report status: SUCCESS
- backend/.env ignored (git check-ignore -v backend/.env matched .gitignore)
- Backend baseline: dart analyze clean; dart test 217 passed
- Flutter baseline: flutter analyze clean; flutter test 65 passed
- Dependency audit: no new direct backend or Flutter packages; dart pub upgrade / flutter pub upgrade were not run

## Work Performed

Implemented domain models, collections, indexes, repositories, persisted-role authorization, application services, Dart Frog customer/cleaner/admin routes, Flutter authenticated APIs/controllers/screens/role routing, Atlas-free automated tests, live index ensure only, a debug APK, safe live health GETs, and documentation including ADR-011.

## Files Created

### Backend

- backend/lib/src/database/collection_document_store.dart
- backend/lib/src/database/document_fields.dart
- backend/lib/src/database/document_write_results.dart
- backend/lib/src/features/addresses/data/address_indexes.dart
- backend/lib/src/features/addresses/data/address_repository.dart
- backend/lib/src/features/addresses/domain/address.dart
- backend/lib/src/features/addresses/domain/address_exceptions.dart
- backend/lib/src/features/addresses/domain/address_validation.dart
- backend/lib/src/features/authorization/application/role_scoped_composition.dart
- backend/lib/src/features/authorization/authenticated_user_context.dart
- backend/lib/src/features/authorization/current_authenticated_user_resolver.dart
- backend/lib/src/features/authorization/forbidden_exception.dart
- backend/lib/src/features/authorization/http/role_http_errors.dart
- backend/lib/src/features/authorization/http/role_middleware.dart
- backend/lib/src/features/authorization/http/role_route_helpers.dart
- backend/lib/src/features/authorization/role_authorizer.dart
- backend/lib/src/features/authorization/role_request_authorizer.dart
- backend/lib/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart
- backend/lib/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart
- backend/lib/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart
- backend/lib/src/features/cleaner_profiles/data/cleaner_profile_repository.dart
- backend/lib/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart
- backend/lib/src/features/cleaner_profiles/domain/cleaner_profile.dart
- backend/lib/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart
- backend/lib/src/features/cleaner_profiles/domain/cleaner_profile_validation.dart
- backend/lib/src/features/customer_profiles/application/customer_account_service.dart
- backend/lib/src/features/customer_profiles/data/customer_profile_indexes.dart
- backend/lib/src/features/customer_profiles/data/customer_profile_repository.dart
- backend/lib/src/features/customer_profiles/domain/customer_profile.dart
- backend/lib/src/features/customer_profiles/domain/customer_profile_exceptions.dart
- backend/lib/src/features/customer_profiles/domain/profile_field_validation.dart
- backend/lib/src/features/customer_profiles/domain/profile_validation_exception.dart
- backend/routes/api/v1/admin/_middleware.dart
- backend/routes/api/v1/admin/cleaners/index.dart
- backend/routes/api/v1/admin/cleaners/[userId]/index.dart
- backend/routes/api/v1/admin/cleaners/[userId]/approve.dart
- backend/routes/api/v1/admin/cleaners/[userId]/reject.dart
- backend/routes/api/v1/cleaner/_middleware.dart
- backend/routes/api/v1/cleaner/profile.dart
- backend/routes/api/v1/cleaner/onboarding/submit.dart
- backend/routes/api/v1/customer/_middleware.dart
- backend/routes/api/v1/customer/profile.dart
- backend/routes/api/v1/customer/addresses/index.dart
- backend/routes/api/v1/customer/addresses/[addressId]/index.dart
- backend/routes/api/v1/customer/addresses/[addressId]/default.dart
- backend/test/helpers/memory_collection_store.dart
- backend/test/routes/api/v1/admin/cleaners_test.dart
- backend/test/routes/api/v1/cleaner/profile_and_submit_test.dart
- backend/test/routes/api/v1/customer/profile_and_addresses_test.dart
- backend/test/src/features/addresses/data/address_indexes_test.dart
- backend/test/src/features/auth/http/role_middleware_test.dart
- backend/test/src/features/cleaner_profiles/application/admin_cleaner_review_service_test.dart
- backend/test/src/features/cleaner_profiles/application/cleaner_onboarding_service_test.dart
- backend/test/src/features/cleaner_profiles/data/cleaner_profile_indexes_test.dart
- backend/test/src/features/customer_profiles/application/customer_account_service_test.dart
- backend/test/src/features/customer_profiles/data/customer_profile_indexes_test.dart
- backend/test/src/features/profiles/domain/profile_models_test.dart

### Flutter

- project/lib/core/network/api_envelope.dart
- project/lib/core/network/api_failure.dart
- project/lib/features/addresses/data/address.dart
- project/lib/features/addresses/data/address_api.dart
- project/lib/features/addresses/presentation/address_controller.dart
- project/lib/features/addresses/presentation/address_form_screen.dart
- project/lib/features/addresses/presentation/address_list_screen.dart
- project/lib/features/admin/data/admin_cleaner_api.dart
- project/lib/features/admin/data/admin_cleaner_models.dart
- project/lib/features/admin/presentation/admin_cleaner_review_controller.dart
- project/lib/features/admin/presentation/admin_home_screen.dart
- project/lib/features/admin/presentation/cleaner_approval_detail_screen.dart
- project/lib/features/admin/presentation/cleaner_approval_list_screen.dart
- project/lib/features/auth/presentation/logout_actions.dart
- project/lib/features/cleaner/data/cleaner_profile.dart
- project/lib/features/cleaner/data/cleaner_profile_api.dart
- project/lib/features/cleaner/presentation/cleaner_home_screen.dart
- project/lib/features/cleaner/presentation/cleaner_onboarding_controller.dart
- project/lib/features/cleaner/presentation/cleaner_onboarding_screen.dart
- project/lib/features/customer/data/customer_profile.dart
- project/lib/features/customer/data/customer_profile_api.dart
- project/lib/features/customer/presentation/customer_home_screen.dart
- project/lib/features/customer/presentation/customer_profile_controller.dart
- project/lib/features/customer/presentation/customer_profile_screen.dart
- project/test/core/network/api_failure_test.dart
- project/test/features/addresses/presentation/address_controller_test.dart
- project/test/features/addresses/presentation/address_screens_test.dart
- project/test/features/admin/presentation/admin_cleaner_review_controller_test.dart
- project/test/features/admin/presentation/admin_screens_test.dart
- project/test/features/cleaner/presentation/cleaner_onboarding_controller_test.dart
- project/test/features/cleaner/presentation/cleaner_screens_test.dart
- project/test/features/customer/data/customer_profile_api_test.dart
- project/test/features/customer/presentation/customer_profile_controller_test.dart
- project/test/features/customer/presentation/customer_screens_test.dart
- project/test/features/profiles/data/profile_models_test.dart
- project/test/helpers/feature_test_fakes.dart

### Documentation

- documentation/database/customer-profiles-collection.md
- documentation/database/cleaner-profiles-collection.md
- documentation/database/addresses-collection.md
- documentation/api/profile-address-onboarding-admin-api.md
- documentation/architecture/profile-address-and-cleaner-onboarding.md
- documentation/decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md
- documentation/cursor/013_profiles_addresses_cleaner_onboarding_admin_approval.md

## Files Modified

- README.md
- backend/README.md
- backend/lib/src/database/collection_names.dart
- backend/lib/src/database/database_indexes.dart
- backend/lib/src/features/users/data/mongo_user_repository.dart
- backend/lib/src/features/users/data/user_document_store.dart
- backend/lib/src/features/users/data/user_repository.dart
- backend/test/src/features/users/data/mongo_user_repository_test.dart
- backend/tool/ensure_database_indexes.dart
- documentation/README.md
- documentation/api/README.md
- documentation/architecture/README.md
- documentation/architecture/backend-api-architecture.md
- documentation/architecture/flutter-client-architecture.md
- documentation/database/README.md
- documentation/decisions/README.md
- project/README.md
- project/lib/app/router/app_router.dart
- project/lib/app/router/app_routes.dart
- project/test/app/router/app_router_test.dart
- project/test/helpers/auth_test_fakes.dart

## Files Deleted

None (no previously tracked files were deleted). Sibling Dart Frog route files were relocated to index.dart to match the framework convention when a directory of the same name exists.

## Commands Executed

- git rev-parse --show-toplevel
- git branch --show-current
- git status --short / git status / git log -10 --oneline
- git check-ignore -v backend/.env
- dart pub get (backend)
- dart analyze / dart test / dart format (backend)
- dart pub global run dart_frog_cli:dart_frog list
- dart run tool/ensure_database_indexes.dart (after backend tests were green; index metadata only)
- flutter pub get / flutter analyze / flutter test / dart format lib test (project)
- flutter build apk --debug
- Live dart_frog dev --port 8098 long enough for GET /, GET /api/v1/health, GET /api/v1/ready
- Final git status --short (no add/commit/push)

## Implementation Details

### Role authorization

Bearer JWT verification is reused from TASK 012 (AccessAuthenticator). Role-scoped routes then resolve the current UserAccount from users, require account_status == active, and authorize against the persisted role. JWT role is not sufficient. Missing user after token issue maps to 401 invalid_access_token. Suspended/deactivated maps to 403 account_unavailable. Wrong persisted role maps to 403 forbidden with a generic body. A mandatory stale-JWT-role test confirms a token claiming customer cannot access customer routes after the persisted role changes.

Shared middleware: roleScopedMiddleware then RoleRequestAuthorizer then AuthenticatedUserContext (principal plus current user; password hash is never a public DTO field).

### Customer profile and addresses

CustomerAccountService upserts profile by authenticated user id. Body cannot set user_id, default_address_id, or timestamps. GET may return profile: null. Addresses are owned via Mongo selectors containing _id and user_id. HTTP is_default is computed from customer_profiles.default_address_id. Maximum 20 addresses is an application product limit (409 address_limit_reached). Setting default without a profile returns 409 customer_profile_required. Deleting the current default clears the pointer if it still matches, then deletes the address. That sequence is not a MongoDB multi-document transaction.

### Cleaner onboarding

One cleaner_profiles document owns draft | pending | approved | rejected. Cleaner edits are allowed only for missing/draft/rejected. Submit and admin review use conditional selectors (onboarding_status in the update filter). Resubmit after rejection clears review metadata. Approval/rejection does not change users.role and does not deactivate the account.

### Admin review

Default list filter is pending. limit 1-50 default 20. after is a cleaner_profile _id cursor (_id > after). Email is joined with UserRepository.findByIds (batch lookup, not N+1). Detail 404 is cleaner_application_not_found. Approve/reject require pending and record reviewed_by as the current admin id.

### Flutter

Feature APIs wrap authenticatedDioProvider. Controllers are separate from AuthController. Role homes: /customer/home, /cleaner/home, /admin/home. /home redirects. Foreign role paths redirect to the user's home. Router guards are UX only. An integration-style test proves CustomerProfileApi on authenticated Dio refreshes once on 401, while the same API on plain Dio does not.

## Technical Decisions

- Separate customer_profiles and cleaner_profiles collections rather than overloading users.
- Default address pointer on the customer profile rather than is_default on every address.
- One cleaner profile carries the current onboarding lifecycle.
- Persisted UserAccount.role authorizes role-scoped routes.
- Conditional Mongo selectors for submit/approve/reject.
- Dart Frog index.dart under directories that also have child routes, to avoid rogue sibling files.
- Admin public signup remains prohibited.

## Verification Performed

- Backend dart analyze (clean) and dart test (283 passed), Atlas-free
- dart_frog list of all routes
- Live index ensure for TASK 013 indexes only; metadata verified; no application documents inspected or mutated
- Flutter dart format, flutter analyze (clean), flutter test (131 passed)
- flutter build apk --debug succeeded
- Live GET /, /api/v1/health, /api/v1/ready each HTTP 200; no customer/cleaner/admin feature routes invoked against Atlas

## Verification Results

- Backend tests: 283 passed, 0 failed
- Flutter tests: 131 passed, 0 failed
- Debug APK: project/build/app/outputs/flutter-apk/app-debug.apk
- Live health: 200 / 200 / 200
- Live data: no profile/address/onboarding/admin application documents created, updated, deleted, or dumped

## Errors / Warnings

- dart_frog dev on a non-TTY handle raises the known StdinException: Error setting terminal echo mode. Health GETs still returned 200 before the process exited.
- Dart Frog initially reported rogue sibling route files (addresses.dart next to addresses/, etc.). Those handlers were moved to index.dart. Final dart_frog list includes the intended paths.
- Default-address clear then delete is not a multi-document transaction (documented).
- Dedicated Mongo repository unit-test files for the new collections were not added as separate files; repositories are exercised through in-memory CollectionDocumentStore seams in service and route tests.

## Security / Secrets Check

- backend/.env remains ignored and was not printed or committed
- No MONGODB_URI, ACCESS_TOKEN_SECRET, passwords, JWTs, refresh tokens, or token hashes recorded
- No live Atlas application documents dumped
- Flutter contains no backend secrets
- Feature JSON omits password hashes and session fields
- Request-body user_id cannot override authenticated ownership

## Git Diff Summary

Uncommitted TASK 013 vertical slice: backend profile/address/onboarding/admin features and tests; Flutter role dashboards and tests; documentation and ADR-011. No .env, APK, build artifacts, or SDK junctions are tracked as source.

## Final Repository State

Working tree dirty with TASK 013 files. Not staged. Not committed. Not pushed. backend/.env ignored.

## Unresolved Issues

- Bookings, payments, chat, reviews, cleaner services, availability, earnings, geospatial search, phone verification, and admin user management remain deferred.
- Production rate limiting is still absent.

## Suggested Next Step

A later task may add cleaner service catalog and availability, or customer booking, after this slice is reviewed. Do not start TASK 014 in this worktree as part of TASK 013.
