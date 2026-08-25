# Cursor Task 014 — Service Catalog, Availability, and Cleaner Discovery Vertical Slice

## Metadata

- Task ID: 014
- Task title: Cleaner Service Catalog, Availability, Customer Discovery, and Comparison Vertical Slice
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Make approved cleaners configurable and discoverable: platform service catalog with canonical Home Cleaning; cleaner hourly offerings and UTC availability; customer discovery, detail, and local max-three comparison. Do not implement booking, payment, chat, reviews, maps, geocoding, admin catalog UI, or TASK 015. Do not commit.

## Exact Cursor Prompt

```text
# TASK 014 — Cleaner Service Catalog, Availability, Customer Discovery, and Comparison Vertical Slice

Repository:

D:\freelance\erfankhan_cse489\final

TASK 013 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

TASK 014 is another LARGE product vertical slice.

TASK 013 completed:

CUSTOMER
- customer profile;
- address CRUD;
- default address;

CLEANER
- onboarding profile;
- draft/pending/approved/rejected lifecycle;
- submission/resubmission;

ADMIN
- persisted-role authorization;
- cleaner approval queue;
- approve/reject;

FLUTTER
- role-aware customer/cleaner/admin dashboards.

TASK 014 must make APPROVED cleaners discoverable and configurable.

Implement:

PLATFORM
- canonical service catalog;
- initial Home Cleaning service definition;

CLEANER
- service offering configuration;
- hourly pricing;
- activation/deactivation;
- future availability management;
- overlap prevention;
- approved-cleaner enforcement;

CUSTOMER
- service catalog browsing;
- cleaner discovery;
- filtering;
- cursor pagination;
- cleaner public details;
- future availability display;
- local cleaner comparison;

FLUTTER
- cleaner service-management UI;
- cleaner availability-management UI;
- customer discovery UI;
- cleaner detail UI;
- comparison UI;
- Riverpod state/controllers;
- route integration;
- comprehensive testing.

Do NOT implement booking yet.

Do NOT implement:

- booking creation;
- payment;
- booking status;
- chat;
- notifications;
- reviews;
- payouts;
- earnings;
- admin service-catalog UI;
- maps;
- geocoding;
- AI features.

Booking will consume this TASK 014 service + availability foundation later.

======================================================================
NO NEW DEPENDENCY POLICY
======================================================================

Expected new direct dependencies:

BACKEND:
none

FLUTTER:
none

Reuse existing:

Backend:
- dart_frog
- mongo_dart
- existing configuration/auth/authorization architecture

Flutter:
- flutter_riverpod
- go_router
- dio
- flutter_secure_storage

Use Dart/Flutter SDK facilities for:

- JSON;
- dates;
- currency-code validation;
- forms;
- date/time pickers.

Do NOT add:

intl
retrofit
freezed
json_serializable
build_runner
another HTTP client
another state-management package
another router
another storage package

unless a genuine blocker exists.

If a new package is genuinely required:

STOP and report before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
CURRENT EXPECTED BASELINE
======================================================================

After TASK 013 checkpoint:

Backend:

dart analyze:
clean

dart test:
283 passed

Flutter:

flutter analyze:
clean

flutter test:
131 passed

TASK 014 must verify these exact baselines before implementation.

======================================================================
SERVICE CATALOG DESIGN
======================================================================

Create MongoDB collection:

services

Purpose:

platform-owned service/category definitions.

Initial platform service:

slug:
home-cleaning

name:
Home Cleaning

billing_model:
hourly

active:
true

The architecture must allow additional services later without changing
authentication, cleaner profile, discovery, or booking ownership models.

======================================================================
SERVICE DOCUMENT
======================================================================

Service document:

{
  "_id": ObjectId,
  "slug": String,
  "name": String,
  "description": String,
  "billing_model": String,
  "active": bool,
  "created_at": DateTime,
  "updated_at": DateTime
}

Initial allowed billing model:

hourly

Create an enum/domain representation even though only hourly exists today.

Explicit wire value:

hourly

Do not scatter raw billing-model strings through business logic.

======================================================================
SERVICE VALIDATION
======================================================================

slug:

- lowercase ASCII;
- 2–60 chars;
- letters/numbers separated by single hyphens;
- no leading/trailing hyphen.

name:

- 2–100 Unicode code points;
- trim;
- reject control characters.

description:

- 10–500 Unicode code points;
- trim;
- plain text;
- reject HTML.

active:

backend-owned catalog state.

Clients cannot create or edit the platform service catalog in TASK 014.

======================================================================
CANONICAL CATALOG SEED
======================================================================

Create a CONTROLLED idempotent backend tool for the canonical service catalog.

Suggested path:

backend/tool/ensure_service_catalog.dart

It may create/update ONLY the canonical:

home-cleaning

platform service.

Required canonical values:

slug:
home-cleaning

name:
Home Cleaning

billing_model:
hourly

active:
true

Use a sensible plain-text description.

The tool must be:

- idempotent;
- explicit;
- manually runnable;
- not request middleware;
- not run at server startup.

Do not silently seed data when API requests occur.

======================================================================
LIVE DATABASE PERMISSION
======================================================================

TASK 014 may perform ONLY these live Atlas mutations:

1. ensure approved TASK 014 index definitions;
2. ensure the canonical `home-cleaning` platform service through the controlled
   catalog tool.

This service is platform configuration data, not private user data.

TASK 014 MUST NOT live-mutate:

- users;
- customer_profiles;
- cleaner_profiles;
- addresses;
- cleaner_services belonging to actual cleaners;
- availability slots belonging to actual cleaners;
- sessions;
- bookings.

Do NOT create a fake approved cleaner.

Do NOT create customer fixtures.

Do NOT enumerate or dump private application documents.

Catalog verification may inspect ONLY the canonical service document fields
necessary to verify the tool result.

Never dump unrelated services/documents.

======================================================================
CLEANER SERVICE OFFERING COLLECTION
======================================================================

Create MongoDB collection:

cleaner_services

Document:

{
  "_id": ObjectId,
  "cleaner_user_id": ObjectId,
  "service_id": ObjectId,
  "hourly_rate_minor": int,
  "currency_code": String,
  "is_active": bool,
  "created_at": DateTime,
  "updated_at": DateTime
}

Do NOT duplicate:

cleaner full name
cleaner bio
cleaner phone
cleaner email
service name
service slug

Those come from their authoritative collections.

======================================================================
MONEY REPRESENTATION
======================================================================

Never store hourly price as floating point.

Use:

hourly_rate_minor

Example conceptually:

250000
could represent
2500.00

depending on currency minor-unit conventions.

TASK 014 does NOT need to implement a complete ISO-4217 decimal-place table.

The backend treats hourly_rate_minor as an integer amount in the selected
currency's minor unit.

Validation:

integer only
minimum 1
maximum 100000000

No negative values.

No doubles.

No string numbers.

======================================================================
CURRENCY CODE
======================================================================

currency_code:

exactly three ASCII letters.

Normalize:

uppercase.

Examples:

BDT
USD
GBP

Do not hard-code one production currency.

Do not perform exchange-rate conversion.

Do not add currency APIs.

Customer rate filtering is within one currency only.

======================================================================
CLEANER OFFERING LIFECYCLE
======================================================================

A cleaner may configure a service offering ONLY when:

UserAccount:
role == cleaner
account_status == active

AND:

CleanerProfile.onboarding_status == approved

If cleaner onboarding is:

missing
draft
pending
rejected

service offering mutation must fail:

403

code:

cleaner_not_approved

Safe message:

Your cleaner account must be approved before managing services.

GET cleaner services may return an empty list before approval if useful, but
mutation must remain blocked.

Prefer consistent policy:

management routes require approved cleaner.

======================================================================
CLEANER SERVICE UPSERT
======================================================================

One cleaner may have at most one cleaner_services document for each service.

PUT service offering:

upserts:

hourly_rate_minor
currency_code
is_active
updated_at

Preserve:

_id
cleaner_user_id
service_id
created_at

Service must:

exist
and
active == true

Otherwise:

404
service_not_found

Do not allow request body to set:

cleaner_user_id
service_id different from route
created_at
updated_at

======================================================================
SERVICE DEACTIVATION
======================================================================

Do NOT physically delete cleaner service offering history.

DELETE cleaner service endpoint should perform logical deactivation:

is_active = false

Return safe success/current offering.

PUT may reactivate it later.

Reason:

future booking history should be able to reference the offering/service
relationship.

No bookings exist yet, but preserve that architecture now.

======================================================================
AVAILABILITY COLLECTION
======================================================================

Use the existing conceptual collection:

availability_slots

Document:

{
  "_id": ObjectId,
  "cleaner_user_id": ObjectId,
  "service_id": ObjectId,
  "start_at": DateTime,
  "end_at": DateTime,
  "created_at": DateTime,
  "updated_at": DateTime
}

All timestamps:

UTC in persistence.

No customer id.

No booking id.

No payment information.

No status field yet because a TASK 014 availability slot simply represents an
open future bookable window.

TASK 015 booking will extend reservation semantics.

======================================================================
AVAILABILITY SLOT RULES
======================================================================

Cleaner may create slots only when:

- cleaner account active;
- persisted role cleaner;
- cleaner onboarding approved;
- cleaner has an ACTIVE offering for the supplied service_id;
- service itself is active.

start_at:

required ISO-8601 timestamp with explicit timezone/offset.

end_at:

required ISO-8601 timestamp with explicit timezone/offset.

Normalize both to UTC.

Reject timestamps with no timezone/offset.

Require:

start_at < end_at

Require slot start:

strictly in the future.

Slot duration:

minimum:
60 minutes

maximum:
8 hours

Require duration to be a multiple of:

30 minutes.

Examples allowed:

60
90
120
150
...
480 minutes

This keeps future hourly booking duration logic manageable.

======================================================================
AVAILABILITY OVERLAP
======================================================================

One cleaner cannot have overlapping slots, even across different services.

Overlap condition:

existing.start_at < proposed.end_at
AND
existing.end_at > proposed.start_at

For update:

exclude the current slot id.

If overlap:

409
availability_overlap

Exact adjacent boundaries are allowed:

existing.end_at == new.start_at

is NOT overlap.

Example:

09:00–11:00
11:00–13:00

allowed.

======================================================================
OVERLAP CONCURRENCY NOTE
======================================================================

MongoDB cannot enforce arbitrary interval overlap with a simple unique index.

TASK 014 must:

- perform a repository overlap query;
- use a unique cleaner/start index to reject exact-start duplicates;
- document that two concurrent partially-overlapping inserts can theoretically
  race because no distributed interval lock exists yet.

This limitation is acceptable for TASK 014 because slots are not yet being
claimed by customers.

TASK 015 booking must introduce stronger reservation concurrency controls.

Do NOT pretend the interval constraint is database-perfect.

======================================================================
AVAILABILITY LIMIT
======================================================================

Maximum future slots per cleaner:

180

Before creation:

count future slots.

At limit:

409
availability_limit_reached

This is an application-level product limit.

======================================================================
EDIT / DELETE AVAILABILITY
======================================================================

Cleaner may update/delete only:

their own slot
AND
slot.start_at > now

Unknown / not-owned / already-started slot:

404
availability_not_found

Do not reveal whether another cleaner owns the supplied ObjectId.

PUT:

may edit:

service_id
start_at
end_at

All normal approval/offering/overlap rules apply.

DELETE:

physically deletes the future open slot in TASK 014.

Booking-aware deletion rules will be introduced once bookings exist.

======================================================================
DATABASE INDEXES
======================================================================

Add deliberate TASK 014 indexes.

services:

1.
name:
services_slug_unique

key:
slug: 1

unique:
true

2.
name:
services_active_slug

key:
active: 1
slug: 1

cleaner_services:

1.
name:
cleaner_services_cleaner_service_unique

key:
cleaner_user_id: 1
service_id: 1

unique:
true

2.
name:
cleaner_services_service_active_id

key:
service_id: 1
is_active: 1
_id: 1

3.
name:
cleaner_services_service_currency_rate_id

key:
service_id: 1
currency_code: 1
is_active: 1
hourly_rate_minor: 1
_id: 1

availability_slots:

1.
name:
availability_slots_cleaner_start_unique

key:
cleaner_user_id: 1
start_at: 1

unique:
true

2.
name:
availability_slots_cleaner_start

If the unique index above already satisfies the same prefix, DO NOT create a
redundant second identical-prefix index merely to satisfy this textual name.

Prefer the minimal useful index set.

3.
name:
availability_slots_service_start

key:
service_id: 1
start_at: 1

4.
name:
availability_slots_cleaner_service_start

key:
cleaner_user_id: 1
service_id: 1
start_at: 1

Before implementation, evaluate index redundancy.

Create only indexes with a concrete query purpose.

If an index above is redundant because another compound index fully satisfies
the intended query prefix, document the decision and omit the redundant index.

Do not blindly create redundant indexes.

======================================================================
COLLECTION NAMES
======================================================================

Extend central collection-name definitions with:

services
cleaner_services
availability_slots

No string literals scattered through repositories.

======================================================================
SERVICE REPOSITORY
======================================================================

Create narrow:

ServiceRepository

Responsibilities:

findById
findBySlug
listActive

No arbitrary update API exposed to normal request application services.

Catalog mutation belongs only to the controlled seed/tool boundary.

======================================================================
CLEANER SERVICE REPOSITORY
======================================================================

Create narrow:

CleanerServiceRepository

Responsibilities:

findByCleanerAndService
listForCleaner
upsertOffering
deactivateOffering
findActiveOffering
discoveryPage / query operations as appropriate

Use selectors containing cleaner identity where ownership is relevant.

Do not accept cleaner_user_id from HTTP body.

======================================================================
AVAILABILITY REPOSITORY
======================================================================

Create narrow:

AvailabilityRepository

Responsibilities:

countFutureForCleaner
listForCleaner
findOwnedFutureById
findOverlap
create
updateOwnedFuture
deleteOwnedFuture
listFutureForCleanerAndService
discovery availability operations as appropriate

Ownership update/delete selectors must include:

_id
cleaner_user_id

Do not:

find by id
then trust a separate authorization comparison

when Mongo can include owner in selector.

======================================================================
DOMAIN / DATA TEST SEAMS
======================================================================

Use the TASK 013:

CollectionDocumentStore

style test seam where practical.

Unlike the minor TASK 013 testing note, TASK 014 should include focused
repository behavior tests for the important query/state behavior.

Add dedicated repository tests where valuable for:

CleanerServiceRepository
AvailabilityRepository

especially:

- owner selectors;
- overlap query behavior;
- logical deactivation;
- future-slot handling.

No Atlas in automated tests.

======================================================================
APPROVED CLEANER POLICY
======================================================================

Create a reusable application/domain policy rather than copying status checks
into every handler.

Possible:

ApprovedCleanerPolicy
ApprovedCleanerGuard
CleanerEligibilityService

or equivalent.

Responsibilities:

- resolve cleaner profile;
- require onboarding_status == approved;
- map non-approved state safely.

Service/availability application services reuse it.

Do not alter role authorization middleware itself to hard-code cleaner
onboarding behavior globally.

Cleaner profile routes from TASK 013 still need to work before approval.

======================================================================
SERVICE CATALOG HTTP API
======================================================================

Add:

GET /api/v1/services

This endpoint may be PUBLIC because:

- service definitions are intentionally public marketplace metadata;
- no user information is returned.

Return ACTIVE services only.

Response conceptually:

{
  "success": true,
  "data": {
    "items": [
      {
        "id": "...",
        "slug": "home-cleaning",
        "name": "Home Cleaning",
        "description": "...",
        "billing_model": "hourly"
      }
    ]
  }
}

Do not expose:

internal Mongo metadata
inactive services
timestamps unless genuinely useful

Wrong method:

405

======================================================================
CLEANER SERVICE API
======================================================================

Add cleaner-role routes:

GET /api/v1/cleaner/services

PUT /api/v1/cleaner/services/[serviceId]

DELETE /api/v1/cleaner/services/[serviceId]

Dart Frog dynamic route naming must follow framework conventions already
learned during TASK 013.

Do not create rogue sibling route files.

GET:

approved cleaner only.

Return cleaner's offerings joined with safe service catalog information.

PUT body:

{
  "hourly_rate_minor": 250000,
  "currency_code": "BDT",
  "is_active": true
}

Validate exact types.

DELETE:

logical deactivation.

======================================================================
CLEANER AVAILABILITY API
======================================================================

Add:

GET /api/v1/cleaner/availability

POST /api/v1/cleaner/availability

GET /api/v1/cleaner/availability/[slotId]

PUT /api/v1/cleaner/availability/[slotId]

DELETE /api/v1/cleaner/availability/[slotId]

Approved cleaner only.

GET collection query parameters:

from
to
service_id

Optional.

Defaults:

from = now
to = now + 90 days

Maximum query range:

180 days

Sort:

start_at ascending.

Return only authenticated cleaner's slots.

POST body:

{
  "service_id": "...",
  "start_at": "2026-09-01T09:00:00+06:00",
  "end_at": "2026-09-01T11:00:00+06:00"
}

Use obviously fake examples in docs/tests.

Do not use these sample dates as runtime assumptions.

======================================================================
DISCOVERY SECURITY / PRIVACY
======================================================================

Customer discovery MUST NOT expose cleaner:

email
phone_e164
reviewed_by
rejection_reason
account internals
password fields
email_normalized
tokens
sessions

Even though admin can view appropriate onboarding data, customers cannot.

Public cleaner discovery profile fields:

cleaner_user_id
full_name
bio
years_experience
service_area
service offering price/currency
future availability summary

The customer's view may know:

approved

implicitly because ONLY approved cleaners are discoverable.

It does not need review metadata.

======================================================================
CUSTOMER DISCOVERY ROUTES
======================================================================

Add customer-role routes:

GET /api/v1/discovery/cleaners

GET /api/v1/discovery/cleaners/[cleanerUserId]

Customer role only in TASK 014.

Do NOT make cleaner identity/contact information publicly browseable without
authentication yet.

======================================================================
DISCOVERY LIST FILTERS
======================================================================

GET /api/v1/discovery/cleaners

Supported query parameters:

service
currency
max_rate_minor
min_experience
available_from
available_to
limit
after

service:

service slug

Default:

home-cleaning

currency:

optional three-letter uppercase-compatible code.

Normalize uppercase.

max_rate_minor:

optional positive integer.

min_experience:

optional integer 0–50.

available_from / available_to:

optional pair.

If one supplied:

require both.

Explicit timezone/offset required.

Normalize UTC.

Require:

available_from < available_to

Maximum discovery availability window:

31 days.

Interpretation:

cleaner qualifies when at least one future availability slot for the requested
service overlaps the requested interval.

Do NOT implement geospatial service_area search yet.

service_area is display metadata only in TASK 014.

======================================================================
DISCOVERY PAGINATION
======================================================================

Use keyset/cursor pagination.

Default limit:

20

Minimum:

1

Maximum:

50

`after` may be an ObjectId cursor for cleaner_services._id.

Default stable order:

cleaner_services._id ascending

This is intentionally simple and deterministic.

Do NOT claim it is final marketplace ranking.

Return:

{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "..." | null
  }
}

Do not use offset/skip pagination for the primary implementation.

======================================================================
DISCOVERY LIST ITEM
======================================================================

Each item returns safe fields conceptually:

{
  "cleaner_user_id": "...",
  "full_name": "...",
  "bio_excerpt": "...",
  "years_experience": 3,
  "service_area": "...",
  "service": {
    "id": "...",
    "slug": "home-cleaning",
    "name": "Home Cleaning"
  },
  "hourly_rate_minor": 250000,
  "currency_code": "BDT",
  "next_available_at": "..." | null
}

No contact/security/review metadata.

bio_excerpt:

may be complete bio if implementation simplicity is preferable.

Do not invent ratings.

Reviews do not exist yet.

======================================================================
DISCOVERY ELIGIBILITY
======================================================================

A cleaner appears ONLY if all are true:

users:
- role == cleaner;
- account_status == active.

cleaner_profiles:
- onboarding_status == approved.

services:
- active == true.

cleaner_services:
- is_active == true;
- matches requested service.

When availability range is supplied:

- matching availability slot must exist.

When no range supplied:

cleaner may still appear even if no immediate slot exists;
`next_available_at` may be null.

This allows customers to discover approved cleaners before schedule selection.

======================================================================
DISCOVERY QUERY EFFICIENCY
======================================================================

Avoid N+1 queries.

Acceptable patterns:

- aggregation pipeline;
- page cleaner_services then batch-fetch profiles/users/availability;
- another deliberate bounded batch strategy.

Do NOT query:

one cleaner
then one profile
then one user
then one slot

inside a loop.

Document exact query strategy.

Because page size <=50, a bounded constant number of batch queries is
acceptable.

======================================================================
DISCOVERY DETAIL
======================================================================

GET /api/v1/discovery/cleaners/[cleanerUserId]

Query:

service=home-cleaning

default if omitted.

Return:

safe cleaner profile:
- cleaner_user_id
- full_name
- bio
- years_experience
- service_area

service offering:
- service id
- slug
- name
- billing_model
- hourly_rate_minor
- currency_code

availability:
future slots for this service

Default availability horizon:

30 days

Maximum returned slots:

60

Sort:

start_at ascending.

Do NOT expose:

phone
email
review metadata
account metadata
password/security fields.

If cleaner does not meet discovery eligibility:

404
cleaner_not_found

Do not distinguish:

nonexistent cleaner
unapproved cleaner
inactive cleaner
inactive offering

to customer.

======================================================================
DISCOVERY APPLICATION SERVICE
======================================================================

Create HTTP-independent:

CleanerDiscoveryService

Responsibilities:

listCleaners
getCleanerDetail

It composes repositories.

HTTP handlers do not construct Mongo joins.

Keep privacy shaping explicit.

Prefer separate customer-facing DTO/result models so a full CleanerProfile is
not accidentally serialized to customers.

======================================================================
CLEANER SERVICE APPLICATION SERVICE
======================================================================

Create:

CleanerServiceManagementService

Responsibilities:

list
upsert
deactivate

It:

- receives current cleaner user;
- applies approved-cleaner policy;
- validates service availability;
- validates pricing/currency;
- calls repositories.

======================================================================
CLEANER AVAILABILITY APPLICATION SERVICE
======================================================================

Create:

CleanerAvailabilityService

Responsibilities:

list
get
create
update
delete

It:

- applies approved-cleaner policy;
- checks active offering;
- validates dates/duration;
- checks slot count;
- checks overlap;
- enforces ownership.

HTTP handlers stay thin.

======================================================================
DATE PARSING POLICY
======================================================================

Create a centralized helper for API timestamps if one does not already exist.

Requirements:

- input must be String;
- explicit timezone/offset required;
- parse ISO-8601;
- normalize to UTC;
- reject malformed values;
- reject timezone-less values.

Do not rely on client local timezone assumptions.

Never store local-time strings in Mongo.

======================================================================
BACKEND ERROR CODES
======================================================================

Add safe mappings as needed:

service_not_found
cleaner_not_approved
cleaner_service_not_found
invalid_hourly_rate
invalid_currency_code
availability_not_found
availability_overlap
availability_limit_reached
invalid_availability_window
cleaner_not_found

Use:

400
for validation errors

403
for cleaner_not_approved

404
for not-found resources

409
for overlap/limit/conflict

Do not expose raw Mongo errors.

======================================================================
BACKEND TESTS — SERVICE CATALOG
======================================================================

Test:

- active catalog list;
- inactive service excluded;
- public GET works without JWT;
- wrong method 405;
- safe JSON fields;
- billing enum;
- slug validation where relevant;
- canonical seed logic idempotence using fake store where practical.

Do not use Atlas in tests.

======================================================================
BACKEND TESTS — APPROVED CLEANER POLICY
======================================================================

Test:

- approved allowed;
- draft blocked;
- pending blocked;
- rejected blocked;
- missing profile blocked;
- customer/admin cannot enter cleaner role route through existing role
  middleware;
- suspended account remains blocked by persisted-user authorization.

======================================================================
BACKEND TESTS — CLEANER SERVICES
======================================================================

Test:

- list;
- first upsert;
- update rate;
- normalize currency uppercase;
- bad rate;
- double/string rate rejected;
- bad currency;
- inactive/nonexistent platform service;
- deactivate;
- reactivate;
- one offering per cleaner/service;
- cannot body-override cleaner id;
- unapproved cleaner blocked;
- wrong role.

Add focused repository tests for:

- cleaner+service ownership selector;
- unique relationship semantics;
- logical deactivation.

No Atlas.

======================================================================
BACKEND TESTS — AVAILABILITY
======================================================================

Test:

- create valid slot;
- timezone normalization to UTC;
- timezone-less rejected;
- start >= end rejected;
- past start rejected;
- <60 min rejected;
- >8h rejected;
- non-30-minute increment rejected;
- adjacent windows allowed;
- overlap rejected;
- overlap across different services rejected;
- exact-start duplicate maps safely;
- future-slot limit 180;
- service must have active offering;
- list sorting;
- date range filtering;
- get owned;
- foreign get 404;
- update owned;
- update overlap excludes current slot itself;
- foreign update 404;
- delete;
- foreign delete 404;
- started/past slot cannot be mutated;
- unapproved cleaner blocked.

Add focused repository tests for overlap selector behavior and owner selectors.

No Atlas.

======================================================================
BACKEND TESTS — DISCOVERY
======================================================================

Test eligibility:

- approved + active account + active offering appears;
- draft cleaner hidden;
- pending cleaner hidden;
- rejected cleaner hidden;
- suspended cleaner hidden;
- deactivated cleaner hidden;
- inactive offering hidden;
- inactive platform service hidden.

Filters:

- service slug;
- currency;
- max rate;
- minimum experience;
- availability interval;
- invalid range;
- limit;
- cursor.

Pagination:

- deterministic _id ordering;
- next cursor;
- second page.

Privacy:

list/detail MUST NOT contain:

- phone_e164;
- email;
- reviewed_by;
- rejection_reason;
- account status internals;
- password/security/session fields.

Detail:

- eligible cleaner returns safe detail;
- nonexistent/unapproved/inactive → same 404 cleaner_not_found;
- availability sorted;
- only future slots;
- only requested service;
- max 60.

Query efficiency:

test application/repository behavior so list processing does not perform N+1
user/profile calls when using fakes with invocation counters.

======================================================================
BACKEND ROUTE SECURITY
======================================================================

Regression-test that:

customer discovery:
customer allowed
cleaner forbidden
admin forbidden

cleaner service/availability:
cleaner role + approved allowed

Customer cannot mutate cleaner service/availability.

Admin cannot impersonate cleaner through these endpoints.

JWT stale-role protections from TASK 013 must remain green.

======================================================================
FLUTTER SERVICE MODEL
======================================================================

Create Flutter model:

MarketplaceService

Fields:

id
slug
name
description
billingModel

Billing model client enum:

hourly

Unknown server values:

must fail safely through API mapping, not crash application startup.

======================================================================
FLUTTER CLEANER OFFERING MODEL
======================================================================

Create:

CleanerServiceOffering

Fields:

id
service
hourlyRateMinor
currencyCode
isActive
createdAt
updatedAt

Do not use double for money.

======================================================================
FLUTTER AVAILABILITY MODEL
======================================================================

Create:

AvailabilitySlot

Fields:

id
serviceId
startAt
endAt
createdAt
updatedAt

Parse server UTC timestamps as DateTime.

UI may display local time using:

DateTime.toLocal()

No extra timezone package.

Do not persist duplicated timezone state.

======================================================================
FLUTTER DISCOVERY MODELS
======================================================================

Create:

CleanerDiscoverySummary

CleanerDiscoveryDetail

Required safe fields matching backend.

Do not include:

cleaner email
cleaner phone
admin review information.

======================================================================
FLUTTER SERVICE CATALOG API
======================================================================

Create a focused API/repository/provider for:

GET /api/v1/services

Catalog is public and may use plain Dio.

Do not attach auth unnecessarily.

However cleaner/customer feature requests remain authenticated.

Cache catalog in Riverpod state for the active app session if useful.

Do not persist catalog to secure storage.

======================================================================
FLUTTER CLEANER SERVICE API
======================================================================

Use existing authenticated Dio.

Operations:

list offerings
upsert offering
deactivate offering

No new token/interceptor implementation.

All session expiry behavior comes from TASK 012 authenticated Dio.

======================================================================
FLUTTER AVAILABILITY API
======================================================================

Use existing authenticated Dio.

Operations:

list
create
get
update
delete

Map safe backend errors.

Do not expose DioException.toString() to UI.

======================================================================
FLUTTER DISCOVERY API
======================================================================

Use existing authenticated Dio.

Operations:

listCleaners
getCleanerDetail

Support filter query values and cursor.

No real network in tests.

======================================================================
FLUTTER CLEANER SERVICE CONTROLLER
======================================================================

Create focused Riverpod controller/state.

State:

loading
loaded
saving
safe error

Operations:

load
save/update offering
deactivate/reactivate

After mutation:

state must update coherently.

Do not place this into AuthController.

======================================================================
FLUTTER AVAILABILITY CONTROLLER
======================================================================

Create focused Riverpod controller/state.

Operations:

load
create
update
delete

Keep list coherent after mutations.

May reload bounded future slots after mutation.

Do not over-engineer optimistic updates.

======================================================================
FLUTTER DISCOVERY CONTROLLER
======================================================================

State must support:

loading first page
loaded results
loading more
filtering
safe error
next cursor

Filters:

service
currency
maximum rate
minimum experience
optional availability range

Changing filters:

clears current page
loads from beginning.

Load More:

only when nextCursor != null.

Prevent duplicate concurrent load-more requests.

======================================================================
FLUTTER COMPARISON STATE
======================================================================

Create local/app-session comparison state with Riverpod.

Customer may select up to:

3 cleaners

for comparison.

No backend compare endpoint is needed.

Do not persist comparison across app reinstall/session.

Prevent duplicate cleaner selection.

At 3:

trying to add another should show/return safe max comparison state.

Comparison should contain only safe discovery data.

======================================================================
ROUTES — CLEANER
======================================================================

Add Flutter routes:

/cleaner/services

/cleaner/availability

/cleaner/availability/new

/cleaner/availability/:slotId/edit

Preserve cleaner role guard.

If cleaner is not approved:

home may still show onboarding lifecycle.

Service/availability screens should gracefully show:

Approval required

rather than attempting unauthorized mutations repeatedly.

Do not bypass backend policy.

======================================================================
ROUTES — CUSTOMER
======================================================================

Add:

/customer/discover

/customer/cleaners/:cleanerUserId

/customer/compare

Preserve customer role guard.

Customer cannot navigate to cleaner management routes.

======================================================================
CLEANER HOME UPDATE
======================================================================

Existing CleanerHomeScreen remains lifecycle-aware.

When status:

approved

show:

Manage Services
Manage Availability

When not approved:

do NOT show active service-management actions.

Pending/rejected/draft onboarding UI from TASK 013 must remain functional.

======================================================================
CLEANER SERVICE MANAGEMENT SCREEN
======================================================================

Create:

CleanerServiceManagementScreen

Load:

active platform service catalog
+
cleaner's current offerings.

For Home Cleaning show:

service name
billing model
hourly rate input
currency-code input
active/inactive state

Actions:

Save
Deactivate

If inactive existing offering:

allow Reactivate / Save.

Use integer minor-unit input.

For UX, explain briefly:

"Enter the hourly price in the smallest currency unit."

Do not create floating-point money calculations.

Do not implement formatted money library.

======================================================================
CLEANER AVAILABILITY LIST SCREEN
======================================================================

Create:

CleanerAvailabilityScreen

Display:

service
start local date/time
end local date/time
duration

Sort ascending.

Actions:

Add Availability
Edit
Delete

Delete requires confirmation.

Only future slots appear from default API query.

No calendar dependency.

A simple list is sufficient.

======================================================================
AVAILABILITY FORM SCREEN
======================================================================

Create:

CleanerAvailabilityFormScreen

Fields/controls:

Service
Start date
Start time
End date
End time

Use Flutter built-in:

showDatePicker
showTimePicker

Convert selected local DateTime to ISO-8601 with timezone offset or UTC in a
way accepted by backend explicit-timezone validation.

Do not send timezone-less strings.

Show backend errors safely:

overlap
limit
inactive service
approval required

Do not silently alter overlapping times.

======================================================================
CUSTOMER HOME UPDATE
======================================================================

Existing CustomerHomeScreen:

add:

Find Cleaners

Keep:

profile
addresses
logout actions.

No fake featured cleaners.

No fake promotions.

======================================================================
CUSTOMER DISCOVERY SCREEN
======================================================================

Create:

CleanerDiscoveryScreen

Functional Material 3.

Display list cards:

full name
experience
service area
hourly rate minor value + currency
next available time when present

Filters UI:

Service
Currency optional
Maximum Rate optional
Minimum Experience optional
Availability date/time optional

Keep UX simple.

Do not implement map/radius/location search.

Load More button:

only when next_cursor exists.

Each card:

View Details

Comparison toggle/action:

Add to Compare / Remove from Compare

Show current compare count:

0–3

======================================================================
CLEANER DETAIL SCREEN
======================================================================

Create:

CleanerDiscoveryDetailScreen

Display:

full name
bio
years experience
service area
service name
billing model
hourly rate
currency
future availability slots

Do NOT display:

email
phone
review metadata
fake ratings
fake completed jobs
fake badges

Actions:

Add/Remove Compare

No Book button yet.

A small non-interactive note may state that booking will use available slots
in a later workflow, but do not create a fake booking action.

======================================================================
COMPARISON SCREEN
======================================================================

Create:

CleanerComparisonScreen

Allow up to 3 selected cleaners.

Compare:

full name
years experience
service area
service
hourly rate
currency
next availability

Do not fabricate:

ratings
reviews
job count
response time.

If cleaners use different currencies:

show values exactly as stored.

Do NOT convert currency.

Display a note that prices in different currencies are not automatically
comparable.

======================================================================
CLIENT PRICE DISPLAY
======================================================================

Because TASK 014 does not implement currency decimal metadata:

do not pretend hourly_rate_minor is universally cents/paisa.

For portfolio UI:

display a clear technical representation such as:

BDT 250000 minor units / hour

or implement a helper that explicitly labels it as minor units.

Do not divide by 100 globally because not every currency has two decimal
minor units.

A later money-formatting decision can add ISO currency metadata.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Map new backend error codes into safe messages:

service_not_found
cleaner_not_approved
cleaner_service_not_found
invalid_hourly_rate
invalid_currency_code
availability_not_found
availability_overlap
availability_limit_reached
invalid_availability_window
cleaner_not_found

Do not display:

DioException.toString()
stack traces
Mongo messages
raw server exception data.

======================================================================
EXISTING AUTH INTEGRATION
======================================================================

All protected TASK 014 APIs MUST use existing authenticated Dio.

Do NOT create:

another token store
another refresh coordinator
another Bearer interceptor
another session-expiry stream

At least one TASK 014 protected API test must prove the existing single-flight
refresh path remains usable.

Do not duplicate TASK 012's extensive concurrency tests unnecessarily.

======================================================================
FLUTTER TESTS — SERVICE MANAGEMENT
======================================================================

Models/API:

catalog parse
offering parse
safe failures

Controller:

load
save
deactivate
reactivate
approval failure
safe error

Widget:

approved cleaner sees service form
rate validation
currency validation
save loading state
inactive/reactivation state

No real network.

======================================================================
FLUTTER TESTS — AVAILABILITY
======================================================================

Controller:

load
create
update
delete
overlap error
limit error

Widget:

slot list
local-time rendering
add navigation
edit navigation
delete confirmation
date/time form
service selector
safe validation/error display

No real network.

======================================================================
FLUTTER TESTS — DISCOVERY
======================================================================

API/models:

list parse
detail parse
next cursor
privacy shape assumptions
safe errors

Controller:

first page
filters
filter reset
load more
no duplicate concurrent load more
error
empty result

Widgets:

customer discovery list
filters
load more
detail
no phone/email displayed
comparison selection
comparison max 3
comparison screen
different-currency note

No real network.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Add regression coverage:

customer:
can open discovery/detail/compare

cleaner:
can open cleaner services/availability

customer trying cleaner route:
redirect to customer home

cleaner trying customer discovery:
redirect to cleaner home

admin:
cannot use customer/cleaner feature routes through UX routing

logout/session expiry behavior remains correct.

======================================================================
SECURITY AUDIT
======================================================================

Backend confirm:

- cleaner service owner comes from authenticated persisted user;
- request body cannot override cleaner id;
- only approved cleaners can mutate offerings/availability;
- inactive service cannot receive new offering;
- availability owner selectors contain _id + cleaner_user_id;
- discovery returns approved active cleaners only;
- customer discovery does not expose phone/email/review metadata;
- raw Mongo errors not exposed;
- user/session/password fields not serialized;
- existing stale JWT authorization behavior remains enforced;
- service catalog seed cannot mutate users/profile/session data.

Flutter confirm:

- protected APIs use authenticated Dio;
- catalog may use plain Dio;
- no extra auth implementation;
- no token/password logging;
- no MONGODB_URI;
- no ACCESS_TOKEN_SECRET;
- no cleaner private phone/email shown in customer discovery;
- no floating-point money storage.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/services-collection.md

documentation/database/cleaner-services-collection.md

documentation/database/availability-slots-collection.md

Document:

fields
indexes
ownership
money representation
currency code
approved-cleaner requirement
availability duration/overlap rules
180-slot limit
UTC storage
partial-overlap concurrency limitation
future booking relationship

======================================================================
DOCUMENTATION — API
======================================================================

Create:

documentation/api/services-availability-discovery-api.md

Document:

GET /api/v1/services

cleaner service routes

cleaner availability routes

customer discovery routes

Include:

request examples with fake data
query parameters
pagination
errors
privacy guarantees
date/time rules

No real user data.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/service-availability-and-discovery.md

Document flows:

Cleaner approved
    ↓
Service offering
    ↓
Availability
    ↓
Customer discovery
    ↓
Cleaner detail

Authorization boundary:

JWT
→ persisted user
→ role
→ approved-cleaner policy
→ application service
→ repository

Discovery:

customer request
→ filter validation
→ discovery service
→ bounded batch/aggregation query
→ safe customer DTO
→ Flutter discovery

Document:

- why price uses integer minor units;
- why currency conversion is deferred;
- why availability is stored UTC;
- interval-overlap limitation;
- why customer-facing DTO excludes contact/review metadata;
- why discovery uses cursor pagination;
- why no ranking algorithm is claimed yet.

======================================================================
ADR-012
======================================================================

Create:

documentation/decisions/ADR-012-service-offerings-availability-and-discovery.md

Required sections:

# ADR-012 — Service Offerings, Availability, and Cleaner Discovery

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must cover:

- platform-owned services collection;
- canonical Home Cleaning catalog seed;
- cleaner_services relation;
- integer minor-unit pricing;
- explicit currency code;
- logical offering deactivation;
- approved-cleaner policy;
- UTC availability slots;
- 60min–8h slots in 30min increments;
- overlap query;
- 180 future-slot limit;
- keyset discovery pagination;
- bounded batch/aggregation discovery;
- customer-facing privacy DTO;
- local max-three cleaner comparison.

Alternatives:

### Price as double
Rejected due money precision.

### Put service price directly on cleaner_profiles
Rejected because cleaner may later offer multiple services.

### Delete offering row when disabled
Rejected because future booking/history needs stable relationship.

### Store availability in local time
Rejected because backend scheduling requires unambiguous timestamps.

### Offset pagination
Not selected because keyset pagination scales better.

### Expose cleaner phone/email during discovery
Rejected for privacy and because contact should be controlled by later booking
workflow.

### Currency conversion in client
Deferred because exchange-rate and currency metadata systems do not exist.

### Database-perfect interval exclusion
Deferred because MongoDB has no simple exclusion constraint for arbitrary
time ranges; application overlap checks are documented until booking
reservation architecture is introduced.

Deferred:

- booking;
- slot reservation;
- payment;
- cancellation;
- cleaner service-specific duration rules;
- ratings/reviews;
- geospatial filtering;
- service-area normalization;
- ranking/recommendations;
- currency conversion;
- admin catalog editor;
- recurring availability rules.

======================================================================
DOCUMENTATION INDEXES
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

Do not claim booking/payment exists.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From repository root:

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

Latest commit:
TASK 013 checkpoint

Verify TASK 013 report:

documentation/cursor/013_profiles_addresses_cleaner_onboarding_admin_approval.md

status:
SUCCESS

Verify:

backend/.env

ignored:

git check-ignore -v backend/.env

Do not print it.

If tree is not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

283 passed
0 failed

If not:

STOP.

Record route list.

======================================================================
STEP 3 — FLUTTER BASELINE

From project/:

flutter pub get
flutter analyze
flutter test

Expected:

131 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Inspect backend/project pubspec files.

Expected:

no new direct dependency.

If genuinely blocked:

STOP before adding anything.

======================================================================
STEP 5 — SERVICE DOMAIN / CATALOG

Implement:

Service
ServiceBillingModel
validation
repository
indexes
safe JSON
controlled catalog seed abstraction/tool

Add automated tests.

Do NOT run live catalog seed yet.

======================================================================
STEP 6 — CLEANER SERVICE OFFERINGS

Implement:

CleanerServiceOffering
validation
repository
approved-cleaner policy
CleanerServiceManagementService
indexes

Add focused repository/service tests.

======================================================================
STEP 7 — AVAILABILITY

Implement:

AvailabilitySlot
date parsing/validation
repository
CleanerAvailabilityService
indexes

Add focused repository/service tests.

======================================================================
STEP 8 — DISCOVERY

Implement:

customer-safe discovery DTOs
CleanerDiscoveryService
bounded batch/aggregation strategy
filters
cursor pagination
privacy shaping

Add comprehensive service/repository tests.

======================================================================
STEP 9 — BACKEND ROUTES

Implement:

GET /api/v1/services

Cleaner service routes.

Cleaner availability routes.

Customer discovery routes.

Follow Dart Frog index.dart dynamic-route conventions.

Add route tests.

No Atlas.

======================================================================
STEP 10 — BACKEND VERIFICATION BEFORE LIVE MUTATION

Run:

dart format .
dart analyze
dart test
dart_frog list

Everything must be green.

Record exact backend test count.

Only then continue.

======================================================================
STEP 11 — LIVE INDEX ENSURE

Run existing controlled index-management tooling.

Ensure TASK 014 indexes only in addition to existing indexes.

Verify index metadata.

Do not inspect private documents.

======================================================================
STEP 12 — LIVE CATALOG ENSURE

Run controlled canonical service tool.

Ensure only:

home-cleaning

Verify only its canonical public/configuration fields.

Do not dump service collection.

Do not mutate user/profile/address/session data.

======================================================================
STEP 13 — FLUTTER DATA LAYER

Implement:

MarketplaceService
CleanerServiceOffering
AvailabilitySlot
CleanerDiscoverySummary
CleanerDiscoveryDetail

APIs/repositories using existing Dio architecture.

======================================================================
STEP 14 — FLUTTER STATE

Implement focused Riverpod controllers/providers:

service catalog
cleaner service management
availability
discovery
comparison

Do not grow AuthController into feature state.

======================================================================
STEP 15 — ROUTER

Add customer/cleaner TASK 014 routes and role guards.

Preserve all TASK 012/013 auth/session routing.

======================================================================
STEP 16 — CLEANER UI

Implement:

CleanerServiceManagementScreen
CleanerAvailabilityScreen
CleanerAvailabilityFormScreen

Update approved CleanerHomeScreen.

======================================================================
STEP 17 — CUSTOMER UI

Implement:

CleanerDiscoveryScreen
CleanerDiscoveryDetailScreen
CleanerComparisonScreen

Update CustomerHomeScreen.

======================================================================
STEP 18 — FLUTTER TESTS

Add model/API/controller/router/widget tests.

No real network.

Run:

dart format lib test
flutter analyze
flutter test

Record exact count.

======================================================================
STEP 19 — ANDROID BUILD

Run:

flutter build apk --debug

Must succeed.

Do not change signing.

Do not weaken release HTTP security.

======================================================================
STEP 20 — SAFE LIVE BACKEND REGRESSION

Start backend only long enough for:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

The service catalog route may be invoked live because it returns only public
platform catalog metadata.

Expected:

all succeed.

Do NOT invoke live:

cleaner service-management routes
cleaner availability routes
customer discovery routes

because they could read/mutate real account data.

Do NOT create real cleaner availability.

Stop server afterward.

Known non-TTY StdinException may be reported if HTTP checks succeeded.

======================================================================
STEP 21 — LIVE DATA SAFETY CHECK

Confirm live mutations were ONLY:

- index metadata;
- canonical home-cleaning platform catalog ensure.

No live:

cleaner_services
availability_slots
profiles
addresses
users
sessions

were created/updated/deleted.

Do not enumerate private documents to prove this.

Use operation knowledge / controlled tool scope.

======================================================================
STEP 22 — SECURITY AUDIT

Perform all backend/Flutter security checks described above.

Run regression test suite including TASK 013 stale-role authorization test.

======================================================================
STEP 23 — DOCUMENTATION

Create:

documentation/database/services-collection.md
documentation/database/cleaner-services-collection.md
documentation/database/availability-slots-collection.md

documentation/api/services-availability-discovery-api.md

documentation/architecture/service-availability-and-discovery.md

documentation/decisions/ADR-012-service-offerings-availability-and-discovery.md

Update documentation indexes.

======================================================================
STEP 24 — FINAL BACKEND VERIFICATION

From backend/:

dart analyze
dart test
dart_frog list

All green.

Record exact test count and complete route list.

======================================================================
STEP 25 — FINAL FLUTTER VERIFICATION

From project/:

flutter analyze
flutter test
flutter build apk --debug

All green.

Record test count.

======================================================================
STEP 26 — FINAL GIT / SECRET REVIEW

From repository root:

git status --short
git check-ignore -v backend/.env

Inspect:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm no:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
tokens
passwords
APK
build directory
SDK junction
private live fixture data
unrelated feature

is tracked.

Do NOT stage.

======================================================================
STEP 27 — TASK REPORT

Create:

documentation/cursor/014_service_availability_and_discovery.md

Use the existing task report template.

The report MUST contain the COMPLETE EXACT TASK 014 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 013 checkpoint;
- baseline counts;
- dependency audit;
- service catalog model;
- canonical catalog tool;
- cleaner service model;
- money representation;
- availability model;
- overlap policy;
- overlap concurrency limitation;
- approved-cleaner policy;
- repositories;
- indexes and redundancy decisions;
- live index ensure;
- live catalog ensure;
- service API;
- cleaner service API;
- availability API;
- discovery API;
- discovery filters;
- pagination;
- query-efficiency design;
- privacy design;
- Flutter models/APIs;
- controllers;
- cleaner screens;
- customer discovery/detail/comparison;
- role routing;
- backend test count;
- Flutter test count;
- debug APK;
- live public health/catalog checks;
- live data safety;
- files created;
- files modified;
- files deleted;
- security audit;
- final Git status;
- warnings/issues.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
passwords
JWTs
refresh tokens
token hashes
real users
real customer profiles
real cleaner profiles
real addresses
real cleaner offerings
real availability documents
Atlas private-data dumps

======================================================================
STEP 28 — DO NOT COMMIT

Do NOT run:

git add
git commit
git push

Leave TASK 014 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 014 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report:

repository root
branch
clean starting tree
TASK 013 checkpoint commit
backend baseline
Flutter baseline
.env ignored

## Dependencies

Confirm no new direct dependency.

## Service Catalog

Describe:

Service model
billing model
canonical home-cleaning service
controlled catalog ensure

## Cleaner Service Offerings

Describe:

pricing
currency
active/inactive lifecycle
approved-cleaner enforcement

## Availability

Describe:

UTC slots
duration rules
overlap behavior
180-slot limit
ownership

## Overlap Concurrency

Explain application overlap protection and the documented concurrent partial
overlap limitation.

## MongoDB Indexes

List actual TASK 014 indexes.

Explain any index requested in the prompt that was deliberately omitted as
redundant.

Report live ensure result.

## Approved Cleaner Policy

Describe eligibility enforcement.

## Service API

Report GET /api/v1/services.

## Cleaner Service API

Report routes and behavior.

## Cleaner Availability API

Report routes and behavior.

## Customer Discovery API

Describe:

eligibility
filters
cursor
privacy
query strategy

## Discovery Privacy

Explicitly confirm customer responses exclude:

email
phone
review metadata
security fields

## Backend Tests

Report:

dart analyze
exact passing test count
Atlas-free automated-test status

## Backend Routes

Provide complete dart_frog list.

## Flutter Cleaner Experience

Describe:

service management
availability management
approved-state home integration

## Flutter Customer Experience

Describe:

discovery
filters
detail
comparison

## Flutter State

Describe focused Riverpod controllers and max-three comparison.

## Flutter Routing

Describe TASK 014 role guards.

## Flutter Tests

Report exact passing count and major coverage.

## Flutter Static Analysis

Report result.

## Android Debug Build

Report result.

## Live Backend Verification

Report:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Confirm no protected feature routes were invoked live.

## Live Data Safety

Confirm only:

index metadata
canonical home-cleaning service configuration

were live-mutated.

Confirm no user cleaner/customer/application data was mutated.

## Files Created

List.

## Files Modified

List.

## Files Deleted

List.

## Documentation

Confirm:

documentation/database/services-collection.md
documentation/database/cleaner-services-collection.md
documentation/database/availability-slots-collection.md
documentation/api/services-availability-discovery-api.md
documentation/architecture/service-availability-and-discovery.md
documentation/decisions/ADR-012-service-offerings-availability-and-discovery.md
documentation/cursor/014_service_availability_and_discovery.md

## Security Verification

Confirm:

- authenticated ownership;
- persisted role enforcement;
- approved-cleaner enforcement;
- no owner override;
- no private contact data in discovery;
- no raw database errors;
- no password/token logging;
- no backend secret in Flutter;
- .env ignored.

## Git Status

Provide final git status --short.

## Issues / Warnings

List every remaining issue.

## Final Statement

State whether service catalog + cleaner offerings + availability + customer
discovery/comparison are complete and ready for ChatGPT review.

Do NOT implement booking.

Do NOT implement payment.

Do NOT implement reviews.

Do NOT implement chat.

Do NOT begin TASK 015.

Start TASK 014 now.
```

## Pre-Task Verification

- Repository root: D:\freelance\erfankhan_cse489\final
- Branch: main
- Starting tree: clean
- TASK 013 checkpoint commit: 659fef2 (TASK 013 profiles/addresses/onboarding/admin approval)
- TASK 013 report: documentation/cursor/013_profiles_addresses_cleaner_onboarding_admin_approval.md status SUCCESS
- backend/.env: ignored (git check-ignore -v backend/.env; contents never printed)
- Backend baseline: dart analyze clean; dart test 283 passed
- Flutter baseline: flutter analyze clean; flutter test 131 passed

## Dependency Audit

No new direct dependencies in backend/pubspec.yaml or project/pubspec.yaml. Did not run dart pub upgrade or flutter pub upgrade.

## Service Catalog

- Domain: MarketplaceService + ServiceBillingModel (hourly wire value only)
- Validation: slug/name/description/active rules as specified
- ServiceRepository: findById, findBySlug, listActive (no request-path catalog mutation)
- Canonical tool: backend/tool/ensure_service_catalog.dart — idempotent, manual, not middleware, not startup
- Canonical values: slug home-cleaning, name Home Cleaning, billing_model hourly, active true, plain-text description
- Live catalog ensure ran after tests were green; only canonical public/configuration fields were verified

## Cleaner Service Offerings

- Collection cleaner_services: cleaner_user_id, service_id, hourly_rate_minor (int 1–100000000), currency_code (3 ASCII letters, uppercase), is_active
- Money is never float; no currency conversion
- PUT upserts rate/currency/active; DELETE logically deactivates
- One offering per cleaner+service (unique index)
- Request body cannot override cleaner id, route service id, or timestamps
- Mutations require ApprovedCleanerPolicy; inactive/missing platform service → 404 service_not_found

## Availability

- UTC slots; ISO-8601 with explicit timezone required; timezone-less rejected
- Duration 60 minutes–8 hours, multiples of 30 minutes; start strictly in the future; start < end
- Requires approved cleaner, active platform service, and active offering
- Overlap: existing.start_at < proposed.end_at AND existing.end_at > proposed.start_at; adjacent boundaries allowed; overlap across services forbidden
- Unique cleaner_user_id + start_at rejects exact-start duplicates
- 180 future-slot application limit → 409 availability_limit_reached
- Ownership update/delete selectors include _id + cleaner_user_id; unknown/foreign/started → 404 availability_not_found
- DELETE physically removes future open slots

## Overlap Concurrency

Application overlap query plus unique cleaner/start index. MongoDB cannot enforce arbitrary interval exclusion. Two concurrent partially overlapping inserts can theoretically race. Documented as acceptable until TASK 015 reservation controls. Exact-start duplicates map to availability_overlap.

## MongoDB Indexes

Created:

- services_slug_unique (slug unique)
- services_active_slug (active, slug)
- cleaner_services_cleaner_service_unique (cleaner_user_id, service_id unique)
- cleaner_services_service_active_id (service_id, is_active, _id)
- cleaner_services_service_currency_rate_id (service_id, currency_code, is_active, hourly_rate_minor, _id)
- availability_slots_cleaner_start_unique (cleaner_user_id, start_at unique)
- availability_slots_service_start (service_id, start_at)
- availability_slots_cleaner_service_start (cleaner_user_id, service_id, start_at)

Omitted as redundant: availability_slots_cleaner_start — the unique cleaner_user_id + start_at index already covers that prefix.

Live ensure: dart run tool/ensure_database_indexes.dart succeeded for TASK 014 index metadata. Canonical catalog ensure succeeded for home-cleaning only.

## Approved Cleaner Policy

ApprovedCleanerPolicy requires persisted role cleaner, account_status active, and onboarding_status approved. Used by offering and availability application services. Role middleware is unchanged for TASK 013 onboarding routes. Non-approved mutation → 403 cleaner_not_approved.

## Service API

GET /api/v1/services is public, active services only, no JWT, no Mongo metadata. Wrong method 405.

## Cleaner Service API

GET /api/v1/cleaner/services
PUT /api/v1/cleaner/services/<serviceId>
DELETE /api/v1/cleaner/services/<serviceId>

Approved cleaner only. List joins safe catalog fields. PUT upserts integer rate, uppercase currency, is_active. DELETE logical deactivation.

## Cleaner Availability API

GET/POST /api/v1/cleaner/availability
GET/PUT/DELETE /api/v1/cleaner/availability/<slotId>

GET query from/to/service_id; default from=now, to=now+90 days; max range 180 days; sort start_at ascending. POST/PUT validate window/offering/overlap/limit.

## Customer Discovery API

Customer role only.

Eligibility: active cleaner account, approved profile, active service, active offering. Optional availability window requires an overlapping future slot. Without a window, next_available_at may be null.

Filters: service (default home-cleaning), currency, max_rate_minor, min_experience, available_from/available_to (pair, explicit TZ, max 31 days), limit 1–50 default 20, after ObjectId cursor on cleaner_services._id ascending.

Query strategy: page cleaner_services then batch-fetch users, profiles, and availability. No N+1 per-cleaner loops. Page size ≤ 50.

Detail: safe profile + offering + up to 60 future slots in 30 days for the requested service. Ineligible → 404 cleaner_not_found (same for missing/unapproved/inactive).

## Discovery Privacy

Customer list/detail exclude email, phone_e164, reviewed_by, rejection_reason, account internals, password/security/session fields.

## Backend Tests

- dart analyze: No issues found
- dart test: 322 passed, 0 failed
- Atlas-free: in-memory CollectionDocumentStore fakes only

## Backend Routes

dart pub global run dart_frog_cli:dart_frog list:

/
/api/v1/health
/api/v1/ready
/api/v1/services
/api/v1/discovery/cleaners
/api/v1/discovery/cleaners/<cleanerUserId>
/api/v1/customer/profile
/api/v1/customer/addresses
/api/v1/customer/addresses/<addressId>/default
/api/v1/customer/addresses/<addressId>
/api/v1/cleaner/profile
/api/v1/cleaner/services
/api/v1/cleaner/services/<serviceId>
/api/v1/cleaner/onboarding/submit
/api/v1/cleaner/availability
/api/v1/cleaner/availability/<slotId>
/api/v1/auth/login
/api/v1/auth/logout
/api/v1/auth/refresh
/api/v1/auth/signup
/api/v1/admin/cleaners
/api/v1/admin/cleaners/<userId>/approve
/api/v1/admin/cleaners/<userId>/reject
/api/v1/admin/cleaners/<userId>
/api/v1/account/me
/api/v1/account/sessions

## Flutter Models / APIs

MarketplaceService, BillingModel (unknown-safe), CleanerServiceOffering, AvailabilitySlot, CleanerDiscoverySummary, CleanerDiscoveryDetail, CleanerDiscoveryPage.

Catalog uses plain Dio. Offerings, availability, and discovery use authenticated Dio. Price display: "CURRENCY N minor units / hour". No float money. Protected availability API test proves existing single-flight refresh.

## Flutter State

CatalogController, CleanerServiceController, AvailabilityController, DiscoveryController (filter reset, load-more guard), ComparisonController (max 3, session-only, no persistence). AuthController unchanged.

## Flutter Cleaner Experience

Approved home shows Manage Services and Manage Availability. Unapproved home keeps TASK 013 onboarding CTAs and does not show management actions. Service screen: Home Cleaning, hourly billing, integer minor-unit rate, currency, Save/Deactivate/Reactivate, Approval required if not approved. Availability list: local times, duration, add/edit/delete with confirmation. Form: service, date/time pickers, ISO timestamps with offset.

## Flutter Customer Experience

Customer home adds Find Cleaners. Discovery list: cards, filters, Load More, compare 0–3. Detail: public profile, offering, future slots, booking-later note, no Book button, no contacts/ratings. Comparison: name, experience, area, service, minor-unit rate, next availability; mixed-currency note.

## Flutter Routing

/cleaner/services, /cleaner/availability, /cleaner/availability/new, /cleaner/availability/:slotId/edit
/customer/discover, /customer/cleaners/:cleanerUserId, /customer/compare

Role guards preserved. Customer/cleaner/admin cannot remain on foreign feature routes.

## Flutter Tests

flutter analyze: No issues found
flutter test: 178 passed

Coverage: catalog/offering/slot/discovery parse; catalog without auth; availability refresh path; offering/availability/discovery controllers; service/availability/discovery widgets; comparison max 3; mixed-currency note; router role guards.

## Android Debug Build

flutter build apk --debug succeeded. Signing unchanged.

## Live Backend Verification

Production server on port 8098 (dart_frog build + dart build/bin/server.dart). dart_frog dev hits known non-TTY StdinException.

GET / → 200
GET /api/v1/health → 200
GET /api/v1/ready → 200
GET /api/v1/services → 200 (public catalog; canonical home-cleaning slug/name/hourly)

Protected feature routes were not invoked live. Server stopped afterward.

## Live Data Safety

Live mutations were only:

- approved TASK 014 index metadata
- canonical home-cleaning platform catalog ensure

No live mutations of users, profiles, addresses, cleaner_services, availability_slots, sessions, or bookings. No fake approved cleaner. No private document dumps.

## Files Created

### Backend

- backend/lib/src/features/authorization/approved_cleaner_policy.dart
- backend/lib/src/features/services/application/canonical_service_catalog.dart
- backend/lib/src/features/services/data/service_indexes.dart
- backend/lib/src/features/services/data/service_repository.dart
- backend/lib/src/features/services/domain/marketplace_service.dart
- backend/lib/src/features/services/domain/service_billing_model.dart
- backend/lib/src/features/services/domain/service_exceptions.dart
- backend/lib/src/features/services/domain/service_validation.dart
- backend/lib/src/features/cleaner_services/application/cleaner_service_management_service.dart
- backend/lib/src/features/cleaner_services/data/cleaner_service_indexes.dart
- backend/lib/src/features/cleaner_services/data/cleaner_service_repository.dart
- backend/lib/src/features/cleaner_services/domain/cleaner_service_exceptions.dart
- backend/lib/src/features/cleaner_services/domain/cleaner_service_offering.dart
- backend/lib/src/features/cleaner_services/domain/cleaner_service_validation.dart
- backend/lib/src/features/availability/application/cleaner_availability_service.dart
- backend/lib/src/features/availability/data/availability_indexes.dart
- backend/lib/src/features/availability/data/availability_repository.dart
- backend/lib/src/features/availability/domain/availability_exceptions.dart
- backend/lib/src/features/availability/domain/availability_slot.dart
- backend/lib/src/features/availability/domain/availability_validation.dart
- backend/lib/src/features/discovery/application/cleaner_discovery_service.dart
- backend/lib/src/features/discovery/domain/cleaner_discovery_models.dart
- backend/lib/src/http/api_date_time.dart
- backend/routes/api/v1/services.dart
- backend/routes/api/v1/cleaner/services/index.dart
- backend/routes/api/v1/cleaner/services/[serviceId]/index.dart
- backend/routes/api/v1/cleaner/availability/index.dart
- backend/routes/api/v1/cleaner/availability/[slotId]/index.dart
- backend/routes/api/v1/discovery/_middleware.dart
- backend/routes/api/v1/discovery/cleaners/index.dart
- backend/routes/api/v1/discovery/cleaners/[cleanerUserId]/index.dart
- backend/tool/ensure_service_catalog.dart
- backend/test/helpers/marketplace_test_fixtures.dart
- backend/test/src/features/authorization/approved_cleaner_policy_test.dart
- backend/test/src/features/services/service_catalog_test.dart
- backend/test/src/features/cleaner_services/cleaner_services_test.dart
- backend/test/src/features/availability/availability_test.dart
- backend/test/src/features/discovery/discovery_test.dart

### Flutter

- project/lib/features/catalog/data/marketplace_service.dart
- project/lib/features/catalog/data/service_catalog_api.dart
- project/lib/features/catalog/presentation/catalog_controller.dart
- project/lib/features/cleaner_services/data/cleaner_service_offering.dart
- project/lib/features/cleaner_services/data/cleaner_service_api.dart
- project/lib/features/cleaner_services/presentation/cleaner_service_controller.dart
- project/lib/features/cleaner_services/presentation/cleaner_service_management_screen.dart
- project/lib/features/availability/data/availability_slot.dart
- project/lib/features/availability/data/availability_api.dart
- project/lib/features/availability/presentation/availability_controller.dart
- project/lib/features/availability/presentation/cleaner_availability_screen.dart
- project/lib/features/availability/presentation/cleaner_availability_form_screen.dart
- project/lib/features/discovery/data/cleaner_discovery_models.dart
- project/lib/features/discovery/data/discovery_api.dart
- project/lib/features/discovery/presentation/discovery_controller.dart
- project/lib/features/discovery/presentation/comparison_controller.dart
- project/lib/features/discovery/presentation/cleaner_discovery_screen.dart
- project/lib/features/discovery/presentation/cleaner_discovery_detail_screen.dart
- project/lib/features/discovery/presentation/cleaner_comparison_screen.dart
- project/test/features/catalog/data/marketplace_models_test.dart
- project/test/features/availability/data/availability_api_test.dart
- project/test/features/availability/presentation/availability_controller_test.dart
- project/test/features/availability/presentation/availability_screens_test.dart
- project/test/features/cleaner_services/presentation/cleaner_service_controller_test.dart
- project/test/features/cleaner_services/presentation/cleaner_service_screens_test.dart
- project/test/features/discovery/presentation/discovery_controller_test.dart
- project/test/features/discovery/presentation/discovery_screens_test.dart

### Documentation

- documentation/database/services-collection.md
- documentation/database/cleaner-services-collection.md
- documentation/database/availability-slots-collection.md
- documentation/api/services-availability-discovery-api.md
- documentation/architecture/service-availability-and-discovery.md
- documentation/decisions/ADR-012-service-offerings-availability-and-discovery.md
- documentation/cursor/014_service_availability_and_discovery.md

## Files Modified

- README.md
- backend/README.md
- backend/lib/src/database/collection_names.dart
- backend/lib/src/database/database_indexes.dart
- backend/lib/src/database/document_fields.dart
- backend/lib/src/features/authorization/application/role_scoped_composition.dart
- backend/lib/src/features/authorization/http/role_http_errors.dart
- backend/lib/src/features/authorization/http/role_middleware.dart
- backend/lib/src/features/authorization/http/role_route_helpers.dart
- backend/lib/src/features/cleaner_profiles/data/cleaner_profile_repository.dart
- backend/test/helpers/memory_collection_store.dart
- backend/test/src/features/auth/http/role_middleware_test.dart
- backend/tool/ensure_database_indexes.dart
- documentation/README.md
- documentation/api/README.md
- documentation/api/profile-address-onboarding-admin-api.md
- documentation/architecture/README.md
- documentation/architecture/backend-api-architecture.md
- documentation/architecture/flutter-client-architecture.md
- documentation/database/README.md
- documentation/decisions/README.md
- project/README.md
- project/lib/app/router/app_router.dart
- project/lib/app/router/app_routes.dart
- project/lib/core/network/api_failure.dart
- project/lib/features/cleaner/presentation/cleaner_home_screen.dart
- project/lib/features/customer/presentation/customer_home_screen.dart
- project/test/app/router/app_router_test.dart
- project/test/core/network/api_failure_test.dart
- project/test/features/cleaner/presentation/cleaner_screens_test.dart
- project/test/features/customer/presentation/customer_screens_test.dart
- project/test/helpers/feature_test_fakes.dart

## Files Deleted

None.

## Documentation

Confirmed:

- documentation/database/services-collection.md
- documentation/database/cleaner-services-collection.md
- documentation/database/availability-slots-collection.md
- documentation/api/services-availability-discovery-api.md
- documentation/architecture/service-availability-and-discovery.md
- documentation/decisions/ADR-012-service-offerings-availability-and-discovery.md
- documentation/cursor/014_service_availability_and_discovery.md

## Security Audit

- Offering/slot owner comes from authenticated persisted user
- Request body cannot override cleaner id
- Only approved cleaners mutate offerings/availability
- Inactive platform services cannot receive new offerings
- Availability owner selectors include _id + cleaner_user_id
- Discovery returns approved active cleaners with active offerings only
- Customer discovery excludes phone/email/review/security fields
- Raw Mongo errors not exposed
- User/session/password fields not serialized
- TASK 013 stale JWT role tests remain in the suite
- Catalog seed cannot mutate users/profiles/sessions
- Flutter protected APIs use authenticated Dio; catalog uses plain Dio
- No extra auth/token store
- No token/password logging
- No MONGODB_URI or ACCESS_TOKEN_SECRET in Flutter
- No floating-point money storage
- backend/.env ignored

## Final Git Status

Uncommitted TASK 014 work. Not staged. Not committed. Not pushed.

Ignored: backend/.env, backend/build, backend/.dart_frog, Flutter APK/build outputs.

## Warnings / Issues

- dart_frog is not on PATH; used dart pub global run dart_frog_cli:dart_frog
- dart_frog dev on a non-TTY handle raises StdinException (terminal echo/line mode). Live GETs were performed against a production dart_frog build server on port 8098 instead, then stopped
- Concurrent partial-overlap slot inserts can theoretically race until TASK 015 reservation controls
- Discovery order by cleaner_services._id is deterministic, not marketplace ranking
- Hourly prices are displayed as minor units; no ISO decimal metadata
- Booking, payment, chat, reviews, maps, geocoding, admin catalog UI, and TASK 015 were not implemented

## Final Statement

Service catalog, cleaner offerings, UTC availability, customer discovery/detail, and local comparison are complete and ready for ChatGPT review. Uncommitted. Booking was not implemented.
