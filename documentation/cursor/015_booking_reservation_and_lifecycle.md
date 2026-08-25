# Cursor Task 015 — Atomic Booking Reservation, Booking Lifecycle, and Customer/Cleaner Job Management

## Metadata

- Task ID: 015
- Task title: Atomic Booking Reservation, Booking Lifecycle, and Customer/Cleaner Job Management
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Implement the marketplace's first real transaction workflow: customer complete-slot booking with idempotent retries, cleaner job lifecycle (accept/decline/cancel/start/complete), database-enforced same-slot reservation, immutable snapshots, role-aware Flutter management, and documentation. Do not implement payment, chat, reviews, or TASK 016. Do not commit.

## Exact Cursor Prompt

```text
# TASK 015 — Atomic Booking Reservation, Booking Lifecycle, and Customer/Cleaner Job Management

Repository:

D:\freelance\erfankhan_cse489\final

TASK 014 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

TASK 014 established:

- canonical services;
- cleaner service offerings;
- integer minor-unit hourly pricing;
- approved-cleaner policy;
- future availability slots;
- customer cleaner discovery;
- cleaner public detail;
- customer comparison.

TASK 015 must implement the marketplace's first real transaction workflow:

CUSTOMER
- choose an available cleaner slot;
- choose one owned service address;
- create a booking;
- safely retry booking creation;
- view booking list/detail;
- cancel eligible booking;
- see lifecycle/status history.

CLEANER
- see booking requests;
- view booking detail;
- accept;
- decline;
- cancel confirmed booking where allowed;
- start job;
- complete job;
- see lifecycle/status history.

BACKEND
- booking persistence;
- atomic double-booking protection for an availability slot;
- idempotent booking creation;
- immutable booking snapshots;
- conditional status transitions;
- reservation release on decline/cancellation;
- reserved availability protection;
- customer/cleaner privacy shaping;
- cursor pagination;
- comprehensive tests.

FLUTTER
- customer booking creation flow from cleaner detail;
- My Bookings;
- booking detail;
- cancellation;
- cleaner Booking Requests / Jobs;
- accept/decline/cancel/start/complete;
- lifecycle display;
- status history;
- role-aware routing;
- comprehensive tests.

Do NOT implement payment in TASK 015.

Do NOT implement:

payment collection
payment authorization
payout
refund
chat
notifications
reviews
ratings
disputes
rescheduling
recurring bookings
maps/geocoding
AI

Payment will consume the immutable booking quotation in a later task.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct dependency

FLUTTER:
no new direct dependency

Reuse existing packages and Dart SDK facilities.

Do NOT add:

uuid
intl
freezed
json_serializable
retrofit
another HTTP client
another router
another state-management package
another storage package

Use:

Random.secure()
base64Url
existing hashlib

where needed for idempotency support.

If a genuinely unavoidable new dependency is required:

STOP and report before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 014 checkpoint:

Backend:

dart analyze:
clean

dart test:
322 passed

Flutter:

flutter analyze:
clean

flutter test:
178 passed

Verify these baselines exactly before implementation.

======================================================================
CORE BOOKING PRODUCT DECISION
======================================================================

TASK 015 books ONE COMPLETE availability slot.

The customer does NOT select an arbitrary partial interval inside a slot.

Therefore:

booking.start_at
=
availability_slot.start_at

booking.end_at
=
availability_slot.end_at

booking.duration_minutes
=
slot duration

This is a deliberate first booking model.

Reason:

- availability slots already encode cleaner-approved bookable windows;
- exact-slot reservation enables strong database-level protection against two
  customers booking the same slot;
- partial-slot splitting/resizing would require a more complicated transactional
  availability allocator;
- the architecture can evolve later.

Do NOT silently split an availability slot.

Do NOT shorten it.

Do NOT create adjacent replacement slots during booking.

======================================================================
BOOKING COLLECTION
======================================================================

Create MongoDB collection:

bookings

Document shape:

{
  "_id": ObjectId,

  "customer_user_id": ObjectId,
  "cleaner_user_id": ObjectId,

  "availability_slot_id": ObjectId,
  "service_id": ObjectId,

  "status": String,
  "reservation_active": bool,

  "duration_minutes": int,

  "hourly_rate_minor": int,
  "quoted_total_minor": int,
  "currency_code": String,

  "service_snapshot": {
    "slug": String,
    "name": String,
    "billing_model": String
  },

  "address_snapshot": {
    "label": String,
    "line1": String,
    "line2": String?,
    "city": String,
    "region": String,
    "postal_code": String,
    "country_code": String
  },

  "customer_notes": String?,

  "idempotency_key": String,
  "request_fingerprint": String,

  "start_at": DateTime,
  "end_at": DateTime,

  "accepted_at": DateTime?,
  "declined_at": DateTime?,
  "started_at": DateTime?,
  "completed_at": DateTime?,
  "cancelled_at": DateTime?,

  "status_history": [
    {
      "from_status": String?,
      "to_status": String,
      "actor_user_id": ObjectId,
      "actor_role": String,
      "reason": String?,
      "created_at": DateTime
    }
  ],

  "created_at": DateTime,
  "updated_at": DateTime
}

All persisted DateTimes:

UTC.

======================================================================
WHY SNAPSHOTS ARE REQUIRED
======================================================================

A booking must preserve the agreement at creation time.

Therefore copy into booking:

- service slug;
- service name;
- billing model;
- hourly rate;
- currency;
- duration;
- quoted total;
- customer service address.

Do NOT rely on future reads from:

addresses
services
cleaner_services

for historical booking terms.

After booking creation:

customer may edit/delete the original address;
cleaner may change rate;
platform may rename a service;

but existing booking snapshot remains unchanged.

Document this explicitly.

======================================================================
DO NOT SNAPSHOT SECURITY IDENTITY
======================================================================

Do NOT store inside booking:

customer password
cleaner password
email_normalized
JWT
refresh token
session id
token hashes
Mongo URI
ACCESS_TOKEN_SECRET

Do NOT duplicate full UserAccount documents.

Persist only IDs and intentionally approved booking snapshots.

======================================================================
BOOKING STATUS ENUM
======================================================================

Create:

BookingStatus

Allowed lowercase wire values:

pending
confirmed
in_progress
completed
declined
cancelled

Use enum/domain representation.

Do not scatter raw status strings across application logic.

======================================================================
BOOKING STATUS LIFECYCLE
======================================================================

Creation:

none
→ pending

Cleaner accepts:

pending
→ confirmed

Cleaner declines:

pending
→ declined

Customer cancels:

pending
→ cancelled

confirmed
→ cancelled

Cleaner cancellation:

confirmed
→ cancelled

Cleaner starts:

confirmed
→ in_progress

Cleaner completes:

in_progress
→ completed

Forbidden transitions include:

pending → in_progress
pending → completed
confirmed → declined
confirmed → completed
in_progress → cancelled
completed → anything
declined → anything
cancelled → anything

Invalid transition:

409
invalid_booking_state

======================================================================
RESERVATION_ACTIVE
======================================================================

reservation_active is an explicit concurrency/index field.

Set:

pending:
true

confirmed:
true

in_progress:
true

completed:
false

declined:
false

cancelled:
false

The status transition and reservation_active update MUST occur in the SAME
atomic booking-document update.

Do not update these independently.

======================================================================
DATABASE-ENFORCED SLOT RESERVATION
======================================================================

Create a PARTIAL UNIQUE MongoDB index:

name:

bookings_active_availability_slot_unique

key:

availability_slot_id: 1

unique:

true

partial filter:

reservation_active == true

Purpose:

at most ONE active booking may reference an availability slot.

This is the authoritative same-slot double-booking guard.

Booking creation may perform a friendly pre-check, but correctness MUST rely on
the database unique constraint.

If two customers concurrently attempt the same open slot:

one may succeed.

the other must safely receive:

409
availability_unavailable

Do not expose duplicate-key details.

======================================================================
PARTIAL INDEX IMPLEMENTATION
======================================================================

Inspect existing index abstraction/tooling.

If mongo_dart's current convenience API cannot represent
partialFilterExpression cleanly:

extend the controlled index tool using db.runCommand/createIndexes similarly to
how TTL support was handled earlier.

Do NOT silently omit the partial filter.

Do NOT replace it with a normal globally unique availability_slot_id index,
because historical cancelled/declined bookings must be allowed to coexist with
a later booking of the same slot.

Metadata verification must confirm:

- key;
- unique;
- partial filter.

======================================================================
REUSING SLOT AFTER RELEASE
======================================================================

When a pending booking is:

declined
or
cancelled

reservation_active becomes false.

When a confirmed booking is cancelled before the slot starts:

reservation_active becomes false.

The original availability slot remains in availability_slots.

Therefore, if its start time is still future, it may become discoverable and
bookable again.

Do NOT create another availability slot.

Do NOT duplicate it.

======================================================================
COMPLETED BOOKING AND SLOT
======================================================================

completed:

reservation_active = false.

Normally the slot start is already in the past, so it naturally does not return
to future discovery.

Do not physically delete historical booking.

======================================================================
ACTIVE BOOKING OVERLAP DEFENCE
======================================================================

TASK 014 documented a theoretical race where two DIFFERENT availability slots
could be created with partial overlap.

TASK 015 must add a defensive booking-level overlap check:

for the target cleaner:

existing booking reservation_active == true
AND
existing.start_at < proposed.end_at
AND
existing.end_at > proposed.start_at

If found:

409
availability_unavailable

This catches anomalous overlapping availability slots under normal execution.

IMPORTANT:

The database partial unique index guarantees same-SLOT exclusivity.

The general interval overlap check remains application-enforced for distinct
slot IDs.

Document that complete database-level arbitrary interval exclusion is still not
available with a simple Mongo index.

Do NOT falsely claim arbitrary interval overlap is database-perfect.

TASK 015 nevertheless materially strengthens reservation concurrency because
same-slot double-booking is database-enforced.

======================================================================
BOOKING PRICE QUOTATION
======================================================================

At booking creation snapshot:

hourly_rate_minor
currency_code

from the CURRENT active CleanerServiceOffering.

Calculate:

duration_minutes =
(end_at - start_at).inMinutes

quoted_total_minor:

use integer round-half-up to the nearest minor unit.

Formula:

numerator =
hourly_rate_minor * duration_minutes

quoted_total_minor =
(numerator + 30) ~/ 60

because the hourly denominator is 60 minutes.

Examples should use fake numbers in tests/docs.

Do NOT use double.

Do NOT use floating-point currency arithmetic.

The rate has a maximum 100000000 and duration <=480, so this remains within
normal Dart integer capacity.

======================================================================
PAYMENT IS NOT YET AUTHORIZATION
======================================================================

quoted_total_minor is:

a booking quotation snapshot.

It is NOT:

a payment
a charge
an authorization
a captured amount

Do not create payment documents.

Do not call payment providers.

Later payment logic must use the immutable quote rather than recomputing from a
new cleaner rate.

======================================================================
BOOKING IDEMPOTENCY
======================================================================

POST booking creation must support:

Idempotency-Key

header.

Flutter MUST send it.

Purpose:

network retry must not accidentally create two booking records.

Requirements:

- required for booking creation;
- ASCII-safe;
- 16–128 characters;
- trim surrounding whitespace;
- reject control characters;
- do not lowercase;
- do not expose in customer UI.

Create unique index:

bookings_customer_idempotency_unique

key:

customer_user_id: 1
idempotency_key: 1

unique:
true

======================================================================
REQUEST FINGERPRINT
======================================================================

Store:

request_fingerprint

SHA-256 lowercase hexadecimal.

Fingerprint canonical booking-creation intent:

customer_user_id
availability_slot_id
address_id
trimmed customer_notes or null

Use an unambiguous deterministic representation.

Do NOT include:

timestamps
random values
JWT
refresh token
password

If the same customer sends the same Idempotency-Key again:

if fingerprint matches:
return existing booking safely.

if fingerprint differs:
409
idempotency_key_reused

Do not create another booking.

======================================================================
IDEMPOTENCY RACE
======================================================================

Correctness must rely on the unique customer+idempotency-key index.

Do not only:

find key
then insert

without duplicate-key handling.

On duplicate-key race:

load existing booking.

Compare fingerprint.

Return existing booking if same.

Otherwise safe 409.

======================================================================
BOOKING CREATION INPUT
======================================================================

Add customer route:

POST /api/v1/customer/bookings

Body:

{
  "availability_slot_id": "...",
  "address_id": "...",
  "customer_notes": "..." | null
}

Do NOT accept:

customer_user_id
cleaner_user_id
service_id
hourly rate
currency
quoted total
status
reservation_active
timestamps

These are backend-derived.

======================================================================
CUSTOMER NOTES
======================================================================

Optional.

If supplied:

trim.

Empty/whitespace:
null.

Maximum:

500 Unicode code points.

Reject control characters.

Plain text only.

Do not accept HTML.

======================================================================
BOOKING CREATION VALIDATION FLOW
======================================================================

The application service must resolve and verify:

1. authenticated user:
   active customer role via existing persisted-user authorization;

2. address:
   exists AND is owned by customer;

3. availability slot:
   exists;
   starts in future;
   exact target slot;

4. cleaner:
   current UserAccount active;
   persisted role cleaner;

5. cleaner profile:
   onboarding_status approved;

6. platform service:
   active;

7. cleaner offering:
   active;
   matches slot.service_id;

8. slot:
   service matches offering;

9. no active booking already overlaps cleaner interval under normal pre-check;

10. insert booking and rely on unique indexes for concurrency correctness.

Unknown/not-owned customer address:

404
address_not_found

Invalid/unavailable slot, inactive cleaner, unapproved cleaner, inactive
service/offering, existing reservation, or stale discovery result:

409
availability_unavailable

Do not disclose internal reason to customer.

======================================================================
BOOKING CREATION RESULT
======================================================================

First successful creation:

201

Idempotent replay of an already-created identical request:

200

Safe response contains customer-facing booking DTO.

You may include:

"idempotent_replay": true/false

if useful.

Do not expose request_fingerprint.

Do not expose internal idempotency key in normal booking DTO.

======================================================================
BOOKING STATUS HISTORY
======================================================================

Store status history embedded inside booking.

Reason:

booking status and history append can be updated atomically in one Mongo
document.

Do NOT create a separate booking_status_history collection in TASK 015.

Each status transition appends:

from_status
to_status
actor_user_id
actor_role
reason
created_at

Creation entry:

from_status = null
to_status = pending
actor = customer

History array is intentionally bounded by the small lifecycle.

Do not allow arbitrary client-supplied history.

======================================================================
ATOMIC STATUS TRANSITIONS
======================================================================

All state-changing booking repository operations must use conditional selectors.

Accept:

_id == bookingId
cleaner_user_id == authenticated cleaner
status == pending
reservation_active == true

Decline:

same expected pending state.

Cleaner cancel:

status == confirmed
reservation_active == true

Customer cancel:

customer ownership
status in pending/confirmed
reservation_active == true
start_at > now

Start:

cleaner ownership
status == confirmed
reservation_active == true

Complete:

cleaner ownership
status == in_progress
reservation_active == true

Do NOT:

read status
then perform unconditional update.

If conditional update matches zero:

resolve safely:

not found/foreign
vs
invalid state

without leaking ownership.

======================================================================
CUSTOMER CANCELLATION POLICY
======================================================================

Customer may cancel:

pending
confirmed

only when:

start_at > now

Cancellation reason:

optional
trim
max 500 Unicode code points
plain text
no control characters

After cancellation:

status = cancelled
reservation_active = false
cancelled_at = now
history append

If started/past/terminal:

409
invalid_booking_state

======================================================================
CLEANER DECLINE POLICY
======================================================================

Cleaner may decline only:

pending

Require reason:

5–500 Unicode code points after trim.

On decline:

status = declined
reservation_active = false
declined_at = now
history append

If slot still future it can become discoverable again.

======================================================================
CLEANER ACCEPT POLICY
======================================================================

Cleaner may accept only:

pending

On accept:

status = confirmed
reservation_active remains true
accepted_at = now
history append

No payment is created.

======================================================================
CLEANER CANCELLATION POLICY
======================================================================

Cleaner may cancel:

confirmed

only if:

start_at > now

Require reason:

5–500 Unicode code points.

Set:

status = cancelled
reservation_active = false
cancelled_at = now
history append

Do not model penalties/refunds yet.

======================================================================
START JOB POLICY
======================================================================

Cleaner may start only:

confirmed

and:

now >= start_at

and:

now < end_at

Otherwise:

409
invalid_booking_state

Set:

status = in_progress
started_at = now
reservation_active remains true
history append

Inject/test time rather than hard-coding DateTime.now throughout service logic.

======================================================================
COMPLETE JOB POLICY
======================================================================

Cleaner may complete only:

in_progress

No payment/payout is triggered.

Set:

status = completed
reservation_active = false
completed_at = now
history append

Do not require end_at to have passed; a cleaning job may legitimately finish
early.

======================================================================
BOOKING REPOSITORY
======================================================================

Create narrow:

BookingRepository

Responsibilities conceptually:

findCustomerBookingById
findCleanerBookingById

findByCustomerAndIdempotencyKey

listForCustomerPage
listForCleanerPage

findActiveByAvailabilitySlot

findActiveOverlapForCleaner

create

acceptPending
declinePending
cancelByCustomer
cancelByCleaner
startConfirmed
completeInProgress

Do not expose arbitrary update maps to application services.

======================================================================
BOOKING CREATION SERVICE
======================================================================

Create HTTP-independent:

CustomerBookingService

Responsibilities:

createBooking
listBookings
getBooking
cancelBooking

Compose:

AddressRepository
AvailabilityRepository
UserRepository
CleanerProfileRepository
ServiceRepository
CleanerServiceRepository
BookingRepository

Avoid Mongo queries inside route handler.

======================================================================
CLEANER BOOKING SERVICE
======================================================================

Create HTTP-independent:

CleanerBookingService

Responsibilities:

listBookings
getBooking
accept
decline
cancel
start
complete

HTTP handlers stay thin.

======================================================================
BOOKING DTO PRIVACY — CUSTOMER
======================================================================

Customer booking response may contain:

booking id
status
cleaner public name
service snapshot
pricing snapshot
full customer's own address snapshot
start/end
notes
timestamps
status history

Do NOT expose cleaner:

email
phone
review metadata
account status internals
password/security/session data.

======================================================================
BOOKING DTO PRIVACY — CLEANER
======================================================================

Cleaner booking response may contain:

booking id
status
customer display name if customer profile exists
service snapshot
pricing snapshot
schedule
customer notes
status history

Address privacy:

PENDING booking:
expose only:

city
region
country_code

Do NOT expose:

label
line1
line2
postal_code

before cleaner accepts.

CONFIRMED / IN_PROGRESS / COMPLETED:
full address snapshot may be exposed.

DECLINED:
coarse address only.

CANCELLED:
coarse address only.

This is a deliberate privacy boundary.

Do not expose customer:

email
phone
account internals
security fields.

======================================================================
CUSTOMER DISPLAY NAME
======================================================================

Cleaner-facing booking may batch/load:

CustomerProfile.full_name

If customer profile is absent:

use a neutral display label:

Customer

Do not fall back to customer email.

======================================================================
BOOKING LIST PAGINATION
======================================================================

Customer:

GET /api/v1/customer/bookings

Cleaner:

GET /api/v1/cleaner/bookings

Query:

status
limit
after

status optional.

Allowed statuses:

pending
confirmed
in_progress
completed
declined
cancelled

limit:

default 20
minimum 1
maximum 50

after:

booking ObjectId cursor.

Sort:

_id descending

For descending cursor:

_id < after

Return:

items
next_cursor

Do not use offset pagination.

======================================================================
CUSTOMER BOOKING ROUTES
======================================================================

Add:

GET /api/v1/customer/bookings

POST /api/v1/customer/bookings

GET /api/v1/customer/bookings/[bookingId]

POST /api/v1/customer/bookings/[bookingId]/cancel

Customer role only.

POST collection requires:

Idempotency-Key

Wrong role:

existing 403 forbidden.

Unknown foreign booking:

404
booking_not_found

Do not distinguish ownership.

======================================================================
CLEANER BOOKING ROUTES
======================================================================

Add:

GET /api/v1/cleaner/bookings

GET /api/v1/cleaner/bookings/[bookingId]

POST /api/v1/cleaner/bookings/[bookingId]/accept

POST /api/v1/cleaner/bookings/[bookingId]/decline

POST /api/v1/cleaner/bookings/[bookingId]/cancel

POST /api/v1/cleaner/bookings/[bookingId]/start

POST /api/v1/cleaner/bookings/[bookingId]/complete

Cleaner role only.

Do NOT require ApprovedCleanerPolicy for EXISTING booking management routes.

Reason:

existing assigned bookings must not become inaccessible merely because cleaner
onboarding state changes later.

However booking CREATION eligibility requires cleaner currently approved.

Persisted active UserAccount/role authorization still applies.

======================================================================
BOOKING HTTP ERROR CODES
======================================================================

Add safe mappings:

booking_not_found
availability_unavailable
invalid_booking_state
idempotency_key_required
invalid_idempotency_key
idempotency_key_reused
invalid_customer_notes

Use:

400
invalid input/idempotency syntax

404
booking/address not found where specified

409
reservation/state/idempotency conflict

Do not expose duplicate-key or Mongo internals.

======================================================================
AVAILABILITY INTEGRATION
======================================================================

TASK 014 availability management must become reservation-aware.

Cleaner availability UPDATE/DELETE:

before mutation:

if an active booking references slot:

409
availability_reserved

Do not allow cleaner to move/delete actively booked availability.

Cleaner may still READ the slot.

Add error mapping:

availability_reserved

======================================================================
CUSTOMER DISCOVERY INTEGRATION
======================================================================

TASK 014 discovery availability must exclude slots with:

an active booking reservation.

This applies to:

next_available_at
availability-range filtering
cleaner-detail future slots

Therefore customers must not be offered a slot that currently has:

pending
confirmed
in_progress

booking reservation.

When booking becomes:

declined
cancelled

and slot remains future:

the slot may reappear.

Avoid N+1 booking checks.

Use:

batch active-reservation lookup
or
bounded aggregation.

Document query strategy.

======================================================================
DISCOVERY DETAIL SLOT IDENTIFIER
======================================================================

Ensure customer cleaner-detail availability entries include:

availability slot id

in their safe DTO.

Flutter needs the selected availability_slot_id to create a booking.

Do not expose cleaner-private metadata with it.

======================================================================
BOOKING INDEXES
======================================================================

Add deliberate indexes:

1.

name:
bookings_active_availability_slot_unique

key:
availability_slot_id: 1

unique:
true

partial:
reservation_active == true

2.

name:
bookings_customer_idempotency_unique

key:
customer_user_id: 1
idempotency_key: 1

unique:
true

3.

name:
bookings_customer_id_desc

key:
customer_user_id: 1
_id: -1

4.

name:
bookings_cleaner_id_desc

key:
cleaner_user_id: 1
_id: -1

5.

name:
bookings_cleaner_active_start

key:
cleaner_user_id: 1
reservation_active: 1
start_at: 1

6.

name:
bookings_availability_active

Evaluate whether this is redundant with the partial unique index.

If redundant for actual query patterns:

omit and document.

As before:

do not create redundant indexes merely because a suggested name exists.

======================================================================
LIVE DATABASE PERMISSION
======================================================================

TASK 015 may perform ONLY:

- controlled booking index ensure;
- metadata verification for those indexes.

It MUST NOT create live:

bookings
customer fixtures
cleaner fixtures
availability fixtures
sessions
payments

Do NOT use real users to test booking.

Automated tests must use in-memory/fake stores.

Do not dump private documents.

======================================================================
COLLECTION NAMES / DOCUMENT HELPERS
======================================================================

Extend central collection names with:

bookings

Extend document field constants/helpers deliberately.

Do not scatter collection/field string constants where existing architecture
already centralizes them.

======================================================================
BOOKING DOMAIN TESTS
======================================================================

Test:

BookingStatus wire values
reservation-active mapping
snapshot BSON/public JSON
history parsing/serialization
customer/cleaner privacy DTO shaping
quoted-total calculation
notes validation
idempotency-key validation
fingerprint determinism

Use fake data only.

======================================================================
BOOKING REPOSITORY TESTS
======================================================================

Add focused tests for:

customer ownership selectors
cleaner ownership selectors
customer descending cursor
cleaner descending cursor
status filter
active slot lookup
active cleaner overlap query
idempotency lookup
conditional accept selector
conditional decline selector
conditional customer-cancel selector
conditional cleaner-cancel selector
conditional start selector
conditional complete selector
reservation_active update
history push
duplicate active-slot mapping
duplicate idempotency mapping

No Atlas.

======================================================================
BOOKING CREATION SERVICE TESTS
======================================================================

Test:

successful booking

snapshots:
- service
- pricing
- address

quoted total integer math

status pending
reservation_active true

creation history entry

customer id derived from authenticated user

address foreign → 404

slot missing → 409 availability_unavailable

slot past → unavailable

cleaner inactive → unavailable

cleaner unapproved → unavailable

service inactive → unavailable

offering inactive → unavailable

active booking same slot → unavailable

overlapping active booking on cleaner → unavailable

same idempotency key + same fingerprint → existing booking

same key + different fingerprint → 409

concurrent-style duplicate active slot exception → safe unavailable

duplicate idempotency exception → load/compare existing

no security data copied.

======================================================================
BOOKING TRANSITION TESTS
======================================================================

Customer:

pending cancel
confirmed cancel
past-start cancel rejected
foreign booking hidden
terminal cancellation rejected

Cleaner:

accept pending
decline pending with reason
cancel confirmed
start confirmed at valid time
start before time rejected
start after slot end rejected
complete in-progress
invalid state transitions
foreign booking hidden

Verify every successful transition:

status
reservation_active
timestamp
history append
actor role/id
reason handling

======================================================================
RESERVATION RELEASE TESTS
======================================================================

Test:

declined pending slot becomes available again if future.

customer-cancelled slot becomes available again if future.

cleaner-cancelled slot becomes available again if future.

confirmed/in-progress stays unavailable.

completed is terminal and past slot naturally does not return to discovery.

Use injected clock.

======================================================================
AVAILABILITY REGRESSION TESTS
======================================================================

Add tests:

reserved slot cannot update
reserved slot cannot delete
unreserved slot still editable/deletable under TASK 014 rules
foreign slot behavior unchanged

======================================================================
DISCOVERY REGRESSION TESTS
======================================================================

Test:

reserved slot excluded from next_available_at.

reserved slot does not satisfy availability filter.

reserved slot excluded from cleaner detail.

cancelled/declined reservation allows future slot back.

no N+1 active-booking lookup.

privacy guarantees remain.

======================================================================
IDEMPOTENCY ROUTE TESTS
======================================================================

Test POST booking:

missing header → 400 idempotency_key_required

invalid key → 400

first creation → 201

identical replay → 200

same key different request → 409

wrong role → 403

malformed body → 400

No real database.

======================================================================
ROLE / AUTHORIZATION REGRESSION
======================================================================

Customer booking routes:

customer allowed
cleaner forbidden
admin forbidden

Cleaner booking routes:

cleaner allowed
customer forbidden
admin forbidden

TASK 013 stale JWT role test must remain green.

TASK 014 approved cleaner mutations must remain green.

Existing booking-management cleaner route must not become dependent on
ApprovedCleanerPolicy.

======================================================================
FLUTTER BOOKING MODEL
======================================================================

Create:

BookingStatus enum

BookingStatusHistoryEntry

BookingServiceSnapshot

BookingAddressSnapshot

CustomerBooking

CleanerBooking

or another clear typed design.

Keep customer and cleaner privacy fields intentional.

Do not use one overly broad DTO that encourages leaking full address to cleaner
pending UI.

======================================================================
FLUTTER QUOTE DISPLAY
======================================================================

Booking API returns:

hourlyRateMinor
quotedTotalMinor
currencyCode
durationMinutes

Continue technical minor-unit display policy:

BDT 250000 minor units / hour

and:

Quoted total: BDT 500000 minor units

Do NOT globally divide by 100.

No currency conversion.

======================================================================
FLUTTER IDEMPOTENCY KEY
======================================================================

For each user booking-submit attempt create one key using:

Random.secure()

Generate at least 128 bits of entropy.

Base64url without padding is acceptable.

IMPORTANT:

One logical booking submission keeps the SAME key across network retry.

Do not generate a new key inside a Dio retry/interceptor.

Auth token refresh retry must resend the original Idempotency-Key.

If the user leaves the booking confirmation flow and starts a new booking
attempt:

generate a new key.

Do not store idempotency key in secure auth storage.

======================================================================
FLUTTER CUSTOMER BOOKING API
======================================================================

Use existing authenticated Dio.

Operations:

createBooking
listBookings
getBooking
cancelBooking

Creation sends:

Idempotency-Key

Do not manually implement token refresh.

Existing authenticated Dio handles it.

======================================================================
FLUTTER CLEANER BOOKING API
======================================================================

Use existing authenticated Dio.

Operations:

listBookings
getBooking
accept
decline
cancel
start
complete

Safe API failure mapping only.

Do not expose DioException.toString().

======================================================================
FLUTTER CUSTOMER BOOKING CONTROLLER
======================================================================

Focused Riverpod controller/state.

Responsibilities:

booking submit state
list first page
load more
status filtering
detail refresh
cancel
safe errors

Do not add booking state to AuthController.

Prevent duplicate submit-button presses.

One logical submit uses one idempotency key.

======================================================================
FLUTTER CLEANER BOOKING CONTROLLER
======================================================================

Support:

booking request/job list
status filter
load more
detail
accept
decline
cancel
start
complete

After mutation:

update/reload list/detail coherently.

No app restart required.

======================================================================
CUSTOMER BOOKING CREATION UX
======================================================================

Update:

CleanerDiscoveryDetailScreen

Each FUTURE UNRESERVED availability slot may now offer:

Book This Slot

Do not add a generic Book button detached from a slot.

Tap:

Book This Slot
→ booking confirmation screen.

======================================================================
BOOKING CONFIRMATION SCREEN
======================================================================

Add route:

/customer/book/:cleanerUserId/:slotId

Create:

BookingConfirmationScreen

Load/receive safe cleaner detail + selected slot as appropriate.

Allow customer to select from OWN addresses.

If no addresses:

show:

Add an address before booking

with navigation to existing address flow.

Display:

cleaner name
service
start/end local time
duration
hourly rate minor units
quoted estimate using the SAME documented integer formula client-side for
preview only
selected address summary

Optional:

customer notes

Final action:

Confirm Booking

Backend returned quotation remains authoritative.

Do not create payment input.

Do not collect card information.

======================================================================
CUSTOMER HOME
======================================================================

Add:

My Bookings

Keep:

Find Cleaners
Profile
Addresses
Logout

======================================================================
CUSTOMER BOOKING LIST SCREEN
======================================================================

Route:

/customer/bookings

Screen:

CustomerBookingListScreen

Default:

all statuses

Allow basic filter:

All
Pending
Confirmed
In Progress
Completed
Cancelled
Declined

Cards show:

cleaner name
service
date/time
status
quoted total

Support:

Load More

using cursor.

======================================================================
CUSTOMER BOOKING DETAIL SCREEN
======================================================================

Route:

/customer/bookings/:bookingId

Show:

status
cleaner name
service
schedule
duration
hourly rate
quoted total
full own address snapshot
customer notes
status history

If eligible:

Cancel Booking

Require confirmation.

Optional cancellation reason input.

Do not show:

payment status
chat
review button

yet.

======================================================================
CLEANER HOME
======================================================================

For cleaner dashboard add:

Booking Requests / Jobs

Do not remove:

Manage Services
Manage Availability
onboarding behavior.

======================================================================
CLEANER BOOKING LIST SCREEN
======================================================================

Route:

/cleaner/bookings

Show:

customer display name
service
schedule
status
coarse location city/region
quoted total

Filters:

All
Pending
Confirmed
In Progress
Completed
Cancelled
Declined

Load More.

Pending items should make request state obvious.

======================================================================
CLEANER BOOKING DETAIL SCREEN
======================================================================

Route:

/cleaner/bookings/:bookingId

Show:

customer display name
service
schedule
duration
quoted rate/total
notes
status/history

Address rendering MUST follow server privacy shape.

Pending:

coarse location only.

Confirmed/In Progress/Completed:

full supplied booking address.

Do NOT attempt to reconstruct hidden address fields client-side.

Actions by status:

pending:
Accept
Decline

confirmed before start:
Cancel

confirmed when start allowed:
Start Job

in_progress:
Complete Job

terminal:
no lifecycle mutation action

Decline/cancel requires reason input where backend requires it.

======================================================================
FLUTTER ROUTER
======================================================================

Add customer routes:

/customer/book/:cleanerUserId/:slotId
/customer/bookings
/customer/bookings/:bookingId

Add cleaner routes:

/cleaner/bookings
/cleaner/bookings/:bookingId

Preserve role guards.

Customer attempting cleaner booking route:

redirect customer home.

Cleaner attempting customer booking route:

redirect cleaner home.

Admin may not use either through UX routing.

Existing authentication/session-expiry routing must remain intact.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Add safe mappings:

booking_not_found
availability_unavailable
invalid_booking_state
idempotency_key_required
invalid_idempotency_key
idempotency_key_reused
invalid_customer_notes
availability_reserved

User-facing messages should be understandable.

Never display:

Mongo errors
stack traces
DioException.toString()
raw duplicate-key messages.

======================================================================
FLUTTER TESTS — CUSTOMER BOOKING
======================================================================

Models/API:

booking parse
history parse
status parse
privacy shape
create sends Idempotency-Key
authenticated refresh retry preserves Idempotency-Key
replay response
safe errors

Controller:

submit
duplicate press guard
list
pagination
filter
detail
cancel
safe error

Widgets:

slot Book This Slot CTA
confirmation
address requirement
address selection
notes
quote preview
loading state
My Bookings
list/filter/load-more
detail
cancel confirmation

No real network.

======================================================================
FLUTTER TESTS — CLEANER BOOKING
======================================================================

Models/API:

cleaner privacy parsing
pending coarse address
confirmed full address

Controller:

list
pagination
filter
detail
accept
decline
cancel
start
complete
safe error

Widgets:

booking requests list
detail pending actions
accept
decline reason
confirmed actions
cancel reason
start
in-progress complete
terminal state
privacy rendering

No real network.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Verify:

customer can access:
booking confirmation
customer booking list/detail

cleaner can access:
cleaner booking list/detail

foreign role redirect behavior.

admin redirected from customer/cleaner booking screens.

logout still goes login.

session expiry still goes login.

Existing discovery/onboarding/profile routes still work.

======================================================================
LIVE DATA POLICY
======================================================================

Do NOT make a real booking against Atlas.

Do NOT create:

real booking
real reservation
fake cleaner
fake customer
fake availability slot

Live database mutation in TASK 015 is index metadata only.

All booking lifecycle behavior is tested with fakes/in-memory seams.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/bookings-collection.md

Document:

fields
embedded snapshots
status enum
reservation_active
embedded status history
idempotency
indexes
partial unique slot reservation
quoted total calculation
privacy
reservation release
concurrency guarantees
remaining different-slot overlap limitation
future payment relationship

Explicitly explain why embedded status history was chosen instead of a separate
collection for TASK 015:

atomic booking transition + history append.

======================================================================
DOCUMENTATION — API
======================================================================

Create:

documentation/api/booking-api.md

Document:

customer routes
cleaner routes
Idempotency-Key
201 first creation
200 replay
filters
cursor pagination
status lifecycle
errors
customer privacy
cleaner address privacy
fake request/response examples

No real identities.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/booking-reservation-and-lifecycle.md

Document:

Customer discovery
→ selected availability slot
→ booking validation
→ idempotency
→ booking insert
→ partial unique reservation index

Document concurrent same-slot attempts.

Document:

reservation release
discovery filtering
availability edit/delete protection
conditional state updates
status history
privacy DTOs
Flutter flow

======================================================================
ADR-013
======================================================================

Create:

documentation/decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md

Required:

# ADR-013 — Booking Reservation, Idempotency, and Lifecycle

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision covers:

- complete-slot booking in TASK 015;
- immutable service/address/pricing snapshots;
- integer quoted total;
- embedded status history;
- reservation_active;
- partial unique active availability-slot index;
- customer idempotency key;
- request fingerprint;
- conditional booking transitions;
- release after decline/cancel;
- reserved-slot protection;
- discovery exclusion;
- cleaner/customer privacy DTOs;
- keyset pagination.

Alternatives:

### Book arbitrary sub-window
Deferred because safe split/remainder allocation needs more complex
transactional scheduling.

### Globally unique availability_slot_id on bookings
Rejected because terminal declined/cancelled history must coexist with future
rebooking of that slot.

### Client-only double-submit protection
Rejected because correctness requires database enforcement.

### Find idempotency key before insert only
Rejected due race.

### Separate booking status-history collection
Not selected because embedded history allows atomic status + history update.

### Recompute price from cleaner offering later
Rejected because rate may change after booking.

### Expose full customer address to pending cleaner
Rejected for privacy.

### Delete cancelled booking
Rejected because lifecycle/audit history must remain.

Deferred:

payment
refund
payout
rescheduling
chat
notifications
reviews
disputes
partial-slot allocation
distributed arbitrary-interval exclusion
cancellation policy/fees
tax
promotions
currency conversion

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
documentation/architecture/service-availability-and-discovery.md
backend/README.md
project/README.md
README.md

Do not claim payment/chat/reviews exist.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From root:

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

latest commit:
TASK 014 checkpoint

Verify:

documentation/cursor/014_service_availability_and_discovery.md

Status:
SUCCESS

Verify:

backend/.env ignored.

If not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend/:

dart pub get
dart analyze
dart test
dart_frog list

Expected:

322 passed
0 failed

If not:

STOP.

======================================================================
STEP 3 — FLUTTER BASELINE

From project/:

flutter pub get
flutter analyze
flutter test

Expected:

178 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Verify no new direct dependency is required.

STOP before adding one.

======================================================================
STEP 5 — BOOKING DOMAIN

Implement:

Booking
BookingStatus
status history
snapshots
validation
quotation
idempotency key/fingerprint
customer/cleaner DTOs

Add tests.

======================================================================
STEP 6 — BOOKING REPOSITORY / INDEXES

Implement:

BookingRepository
booking index specs
partial unique reservation index support

Add focused repository/index tests.

Do not live-ensure yet.

======================================================================
STEP 7 — CUSTOMER BOOKING SERVICE

Implement and comprehensively test:

create
idempotency
snapshots
list
detail
cancel
reservation conflicts.

======================================================================
STEP 8 — CLEANER BOOKING SERVICE

Implement and test:

list
detail
accept
decline
cancel
start
complete
conditional transitions.

======================================================================
STEP 9 — AVAILABILITY / DISCOVERY INTEGRATION

Make reserved slots:

non-editable/non-deletable
non-discoverable

without N+1 checks.

Add regressions.

======================================================================
STEP 10 — BACKEND ROUTES

Implement all customer/cleaner booking routes.

Use existing role middleware.

Thin handlers.

No Atlas.

======================================================================
STEP 11 — BACKEND PRE-LIVE VERIFICATION

Run:

dart format .
dart analyze
dart test
dart_frog list

All must pass before live index work.

Record count.

======================================================================
STEP 12 — LIVE BOOKING INDEX ENSURE

Ensure booking indexes including:

partial unique active-slot constraint.

Verify metadata including partialFilterExpression.

No documents created/read/dumped beyond index metadata.

======================================================================
STEP 13 — FLUTTER DATA / API

Implement customer/cleaner booking models and APIs.

Preserve authenticated Dio/session architecture.

======================================================================
STEP 14 — FLUTTER STATE

Implement customer and cleaner booking controllers.

Do not modify AuthController into feature state.

======================================================================
STEP 15 — FLUTTER ROUTES / CUSTOMER UI

Implement:

slot booking CTA
confirmation
My Bookings
customer list/detail/cancel

======================================================================
STEP 16 — CLEANER UI

Implement:

Booking Requests / Jobs
cleaner list/detail
accept/decline/cancel/start/complete

======================================================================
STEP 17 — FLUTTER TESTS

Run comprehensive new tests.

No real network.

Then:

dart format lib test
flutter analyze
flutter test

Record count.

======================================================================
STEP 18 — ANDROID DEBUG BUILD

Run:

flutter build apk --debug

Must succeed.

Do not alter release signing/security.

======================================================================
STEP 19 — SAFE LIVE BACKEND REGRESSION

May call live only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Do NOT invoke booking routes live.

Do NOT invoke discovery protected routes live.

Do NOT create booking fixtures.

Stop server afterward.

======================================================================
STEP 20 — SECURITY / PRIVACY AUDIT

Verify:

booking customer comes from auth
slot cleaner/service backend-derived
address ownership
same-slot partial unique reservation
idempotency uniqueness
fingerprint handling
conditional status transitions
reserved availability protections
discovery exclusion
customer DTO privacy
cleaner address privacy
no security fields
no raw database errors
no new auth implementation
no token/password logging
no secrets in Flutter
.env ignored.

======================================================================
STEP 21 — DOCUMENTATION

Create:

documentation/database/bookings-collection.md
documentation/api/booking-api.md
documentation/architecture/booking-reservation-and-lifecycle.md
documentation/decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md

Update indexes/docs.

======================================================================
STEP 22 — FINAL BACKEND VERIFICATION

Run:

dart analyze
dart test
dart_frog list

All green.

Record exact count/routes.

======================================================================
STEP 23 — FINAL FLUTTER VERIFICATION

Run:

flutter analyze
flutter test
flutter build apk --debug

All green.

Record exact count.

======================================================================
STEP 24 — FINAL GIT REVIEW

Run:

git status --short
git check-ignore -v backend/.env

Inspect backend/project/documentation/root diffs.

Confirm no:

.env
secret
password
JWT
refresh token
private live data
APK
build directory
SDK artifact
unrelated feature

tracked.

Do NOT stage.

======================================================================
STEP 25 — TASK REPORT

Create:

documentation/cursor/015_booking_reservation_and_lifecycle.md

Use task report template.

Must contain COMPLETE EXACT TASK 015 prompt under:

## Exact Cursor Prompt

Document:

clean TASK 014 checkpoint
baseline counts
dependency audit
booking schema
snapshots
status enum/lifecycle
status history design
reservation_active
partial unique index
partial index metadata verification
different-slot overlap defence
concurrency limitation
quotation calculation
idempotency key
fingerprint
idempotent replay
repositories
customer service
cleaner service
conditional transitions
reservation release
availability integration
discovery integration
privacy design
backend routes
backend test count
Flutter models/APIs
idempotency key client behavior
controllers
customer screens
cleaner screens
router
Flutter test count
APK
live safe GETs
live data safety
files created/modified/deleted
security audit
warnings
Git status.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
passwords
JWTs
refresh tokens
token hashes
real users
real addresses
real bookings
real availability
Atlas private-document dumps

======================================================================
STEP 26 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 015 completely uncommitted.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 015 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

Report clean checkpoint, baselines, .env ignore.

## Dependencies

Confirm no new direct dependency.

## Booking Model

Describe snapshots, status, reservation_active, history.

## Booking Quotation

Describe integer minor-unit calculation and immutable quote.

## Idempotency

Describe Idempotency-Key, fingerprint, replay, conflict behavior.

## Reservation Concurrency

Describe partial unique active-slot index, duplicate race handling, and
different-slot overlap defence/limitation.

## MongoDB Indexes

List actual indexes and partial-index metadata verification.

## Customer Booking API

Describe create/list/detail/cancel.

## Cleaner Booking API

Describe list/detail/accept/decline/cancel/start/complete.

## Booking Lifecycle

Describe allowed transitions and conditional updates.

## Reservation Release

Describe declined/cancelled future slot behavior.

## Availability Integration

Confirm actively reserved slots cannot be modified/deleted.

## Discovery Integration

Confirm active reservations are excluded from customer availability without
N+1 queries.

## Privacy

Describe customer DTO and cleaner coarse/full address boundary.

## Backend Tests

Report analyzer and exact test count.

## Backend Routes

Provide complete dart_frog list.

## Flutter Customer Experience

Describe slot booking, confirmation, My Bookings, detail/cancel.

## Flutter Cleaner Experience

Describe requests/jobs and lifecycle actions.

## Flutter State

Describe booking controllers.

## Flutter Routing

Describe new role-protected routes.

## Flutter Tests

Report exact count and coverage.

## Flutter Static Analysis

Report result.

## Android Debug Build

Report result.

## Live Backend Verification

Report only allowed safe GETs.

Confirm no booking route invoked live.

## Live Data Safety

Confirm only booking index metadata was live-mutated.

## Files Created

List.

## Files Modified

List.

## Files Deleted

List.

## Documentation

Confirm:

documentation/database/bookings-collection.md
documentation/api/booking-api.md
documentation/architecture/booking-reservation-and-lifecycle.md
documentation/decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md
documentation/cursor/015_booking_reservation_and_lifecycle.md

## Security Verification

Confirm ownership, concurrency, idempotency, privacy, no raw database/security
leaks, Flutter secrets absent, .env ignored.

## Git Status

Provide git status --short.

## Issues / Warnings

List every remaining issue.

## Final Statement

State whether atomic booking reservation + booking lifecycle + customer/cleaner
job-management are complete and ready for ChatGPT review.

Do NOT implement payment.

Do NOT implement chat.

Do NOT implement reviews.

Do NOT begin TASK 016.

Start TASK 015 now.
```

## Pre-Task Repository State

- `git rev-parse --show-toplevel`: `D:/freelance/erfankhan_cse489/final`
- branch: `main`
- working tree: clean
- latest commit: TASK 014 checkpoint (`8a6bca0 service_availability_and_discovery`)
- `documentation/cursor/014_service_availability_and_discovery.md` Status: SUCCESS
- `backend/.env` ignored (`.gitignore:8:.env`)

## Work Performed

Implemented booking domain, repository (conditional updates, partial unique index via `createIndexes`), customer/cleaner application services, thin Dart Frog routes, availability reserved-slot protection, batched discovery exclusion, Flutter models/APIs/controllers/screens/routes/tests, live index metadata ensure only, Android debug APK, and documentation/ADR-013.

## Files Created

### Backend

- backend/lib/src/features/bookings/application/cleaner_booking_service.dart
- backend/lib/src/features/bookings/application/customer_booking_service.dart
- backend/lib/src/features/bookings/data/booking_indexes.dart
- backend/lib/src/features/bookings/data/booking_repository.dart
- backend/lib/src/features/bookings/domain/booking.dart
- backend/lib/src/features/bookings/domain/booking_address_snapshot.dart
- backend/lib/src/features/bookings/domain/booking_exceptions.dart
- backend/lib/src/features/bookings/domain/booking_quotation.dart
- backend/lib/src/features/bookings/domain/booking_service_snapshot.dart
- backend/lib/src/features/bookings/domain/booking_status.dart
- backend/lib/src/features/bookings/domain/booking_status_history_entry.dart
- backend/lib/src/features/bookings/domain/booking_validation.dart
- backend/routes/api/v1/customer/bookings/index.dart
- backend/routes/api/v1/customer/bookings/[bookingId]/index.dart
- backend/routes/api/v1/customer/bookings/[bookingId]/cancel.dart
- backend/routes/api/v1/cleaner/bookings/index.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/index.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/accept.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/decline.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/cancel.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/start.dart
- backend/routes/api/v1/cleaner/bookings/[bookingId]/complete.dart
- backend/test/src/features/bookings/booking_domain_test.dart
- backend/test/src/features/bookings/booking_repository_test.dart
- backend/test/src/features/bookings/booking_service_test.dart

### Flutter

- project/lib/features/bookings/data/booking_api.dart
- project/lib/features/bookings/data/booking_idempotency.dart
- project/lib/features/bookings/data/booking_models.dart
- project/lib/features/bookings/presentation/booking_confirmation_screen.dart
- project/lib/features/bookings/presentation/booking_widgets.dart
- project/lib/features/bookings/presentation/cleaner_booking_controller.dart
- project/lib/features/bookings/presentation/cleaner_booking_detail_screen.dart
- project/lib/features/bookings/presentation/cleaner_booking_list_screen.dart
- project/lib/features/bookings/presentation/customer_booking_controller.dart
- project/lib/features/bookings/presentation/customer_booking_detail_screen.dart
- project/lib/features/bookings/presentation/customer_booking_list_screen.dart
- project/test/features/bookings/data/booking_api_test.dart
- project/test/features/bookings/presentation/cleaner_booking_controller_test.dart
- project/test/features/bookings/presentation/cleaner_booking_screens_test.dart
- project/test/features/bookings/presentation/customer_booking_controller_test.dart
- project/test/features/bookings/presentation/customer_booking_screens_test.dart

### Documentation

- documentation/database/bookings-collection.md
- documentation/api/booking-api.md
- documentation/architecture/booking-reservation-and-lifecycle.md
- documentation/decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md
- documentation/cursor/015_booking_reservation_and_lifecycle.md

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
- backend/lib/src/features/availability/application/cleaner_availability_service.dart
- backend/lib/src/features/availability/data/availability_repository.dart
- backend/lib/src/features/customer_profiles/data/customer_profile_repository.dart
- backend/lib/src/features/discovery/application/cleaner_discovery_service.dart
- backend/test/helpers/marketplace_test_fixtures.dart
- backend/test/helpers/memory_collection_store.dart
- backend/test/src/features/auth/http/role_middleware_test.dart
- backend/test/src/features/availability/availability_test.dart
- backend/test/src/features/discovery/discovery_test.dart
- backend/tool/ensure_database_indexes.dart
- documentation/README.md
- documentation/api/README.md
- documentation/api/services-availability-discovery-api.md
- documentation/architecture/README.md
- documentation/architecture/backend-api-architecture.md
- documentation/architecture/flutter-client-architecture.md
- documentation/architecture/service-availability-and-discovery.md
- documentation/database/README.md
- documentation/database/availability-slots-collection.md
- documentation/decisions/README.md
- project/README.md
- project/lib/app/router/app_router.dart
- project/lib/app/router/app_routes.dart
- project/lib/core/network/api_failure.dart
- project/lib/features/cleaner/presentation/cleaner_home_screen.dart
- project/lib/features/customer/presentation/customer_home_screen.dart
- project/lib/features/discovery/presentation/cleaner_discovery_detail_screen.dart
- project/test/app/router/app_router_test.dart
- project/test/core/network/api_failure_test.dart
- project/test/features/cleaner/presentation/cleaner_screens_test.dart
- project/test/features/customer/presentation/customer_screens_test.dart
- project/test/features/discovery/presentation/discovery_screens_test.dart
- project/test/helpers/feature_test_fakes.dart

## Files Deleted

None.

## Commands Executed

- git rev-parse --show-toplevel; git branch --show-current; git status; git log -10 --oneline
- git check-ignore -v backend/.env
- backend: dart pub get; dart analyze; dart test; dart format .; dart pub global run dart_frog_cli:dart_frog list; dart run tool/ensure_database_indexes.dart; dart pub global run dart_frog_cli:dart_frog build; dart build\bin\server.dart (PORT 8098)
- project: flutter pub get (baseline); dart format lib test; flutter analyze; flutter test; flutter build apk --debug
- Safe live GET curl of `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services` only; server stopped afterward

Did not run dart pub upgrade / flutter pub upgrade. Did not git add / commit / push.

## Implementation Details

Complete-slot booking copies slot start/end/duration. Snapshots freeze service, pricing, and address. `quoted_total_minor = (hourly_rate_minor * duration_minutes + 30) ~/ 60`. `reservation_active` updates with status. Partial unique index `bookings_active_availability_slot_unique` is the same-slot guard. Customer+idempotency unique index plus fingerprint replay. Conditional repository selectors. Discovery batches `findActiveByAvailabilitySlotIds`. Flutter uses authenticated Dio; one Idempotency-Key per submit attempt via `Random.secure()` / base64url.

## Technical Decisions

See ADR-013: complete-slot first model; embedded history; partial unique rather than globally unique slot id; application-level different-slot overlap; omit redundant `bookings_availability_active`.

## Verification Performed

Baselines, analyze/test both projects, dart_frog list, live index metadata including partialFilterExpression, debug APK, safe live GETs, git ignore of `.env`.

## Verification Results

### Pre-Task Verification

Clean TASK 014 checkpoint on `main`. backend dart analyze clean, dart test 322 passed. flutter analyze clean, flutter test 178 passed. `.env` ignored.

### Dependencies

No new direct dependency. Reused hashlib, `Random.secure()`, `base64Url`, existing Dio/Riverpod/go_router.

### Booking Model

`BookingStatus` wire values pending/confirmed/in_progress/completed/declined/cancelled. Snapshots for service and address. Embedded `status_history`. `reservation_active` true for pending/confirmed/in_progress.

### Booking Quotation

Integer minor-unit formula; immutable quote; not a payment.

### Idempotency

Required `Idempotency-Key` 16–128 ASCII. Fingerprint SHA-256 of customer, slot, address, notes. Same key+fingerprint → 200 replay. Different fingerprint → 409 `idempotency_key_reused`. Duplicate-key race loads and compares.

### Reservation Concurrency

Partial unique active-slot index. Duplicate-key mapped to `availability_unavailable`. Different-slot overlap is application-only; not claimed database-perfect.

### MongoDB Indexes

- bookings_active_availability_slot_unique (unique, availability_slot_id, partialFilterExpression.reservation_active = true) — metadata verified live
- bookings_customer_idempotency_unique
- bookings_customer_id_desc
- bookings_cleaner_id_desc
- bookings_cleaner_active_start

`bookings_availability_active` omitted as redundant with the partial unique index.

### Customer Booking API

POST create (201/200), GET list (keyset), GET detail, POST cancel. Customer role only.

### Cleaner Booking API

GET list/detail; POST accept/decline/cancel/start/complete. No ApprovedCleanerPolicy on these routes.

### Booking Lifecycle

Allowed transitions as specified; invalid → 409 `invalid_booking_state`. Conditional updates.

### Reservation Release

Decline/cancel sets reservation_active false; future slot may reappear. Confirmed/in_progress stay reserved. Completed is terminal.

### Availability Integration

Reserved slots cannot update/delete (409 `availability_reserved`). GET allowed.

### Discovery Integration

Active reservations excluded from next_available_at, availability filter, and detail slots via one batched lookup per pass.

### Privacy

Customer DTO: full own address, cleaner public name. Cleaner DTO: coarse address for pending/declined/cancelled; full for confirmed/in_progress/completed. Display name `Customer` if no profile. No emails/phones/security fields.

### Backend Tests

dart analyze: No issues found. dart test: **348 passed**, 0 failed.

### Backend Routes

```
/
/api/v1/health
/api/v1/ready
/api/v1/services
/api/v1/discovery/cleaners
/api/v1/discovery/cleaners/<cleanerUserId>
/api/v1/customer/profile
/api/v1/customer/bookings
/api/v1/customer/bookings/<bookingId>/cancel
/api/v1/customer/bookings/<bookingId>
/api/v1/customer/addresses
/api/v1/customer/addresses/<addressId>/default
/api/v1/customer/addresses/<addressId>
/api/v1/cleaner/profile
/api/v1/cleaner/services
/api/v1/cleaner/services/<serviceId>
/api/v1/cleaner/onboarding/submit
/api/v1/cleaner/bookings
/api/v1/cleaner/bookings/<bookingId>/accept
/api/v1/cleaner/bookings/<bookingId>/cancel
/api/v1/cleaner/bookings/<bookingId>/complete
/api/v1/cleaner/bookings/<bookingId>/decline
/api/v1/cleaner/bookings/<bookingId>/start
/api/v1/cleaner/bookings/<bookingId>
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
```

### Flutter Customer Experience

Book This Slot on cleaner detail → confirmation (addresses, integer quote preview, notes) → My Bookings list/filter/load-more → detail/cancel with confirmation.

### Flutter Cleaner Experience

Booking Requests / Jobs list; pending request state; detail actions accept/decline/cancel/start/complete; coarse vs full address from server shape.

### Flutter State

`CustomerBookingController` and `CleanerBookingController`. AuthController unchanged. Duplicate submit guarded; one key per beginSubmitAttempt.

### Flutter Routing

`/customer/book/:cleanerUserId/:slotId`, `/customer/bookings`, `/customer/bookings/:bookingId`, `/cleaner/bookings`, `/cleaner/bookings/:bookingId`. Foreign role redirect. Session expiry/logout still login.

### Flutter Tests

flutter test: **214 passed**. Coverage: models/API including Idempotency-Key on refresh retry, controllers, customer/cleaner widgets, router.

### Flutter Static Analysis

flutter analyze: No issues found.

### Android Debug Build

`flutter build apk --debug` succeeded. Signing unchanged.

### Live Backend Verification

Production server PORT 8098 (`dart_frog build` + `dart build\bin\server.dart`).

GET / → 200
GET /api/v1/health → 200
GET /api/v1/ready → 200
GET /api/v1/services → 200 (public catalog; home-cleaning / hourly)

No booking routes invoked live. No protected discovery invoked live. Server stopped afterward.

### Live Data Safety

Live mutation was booking **index metadata only** (plus re-ensure of previously approved indexes). No live bookings, users, addresses, availability, sessions, or payments created/read/dumped.

## Security / Secrets Check

Ownership from auth; slot cleaner/service backend-derived; address ownership; partial unique reservation; idempotency uniqueness; fingerprint handling; conditional transitions; reserved availability; discovery exclusion; DTO privacy; no raw database errors; no new auth implementation; no token/password logging; no secrets in Flutter; `.env` ignored. No secret values recorded here.

## Git Diff Summary

Uncommitted TASK 015 backend booking feature, Flutter booking UX, tests, and documentation. No `.env`, APK, build dir, or secrets tracked.

## Final Repository State

Working tree dirty with TASK 015 changes. Not staged. Not committed.

## Unresolved Issues

None blocking TASK 015. Payment, chat, reviews, partial-slot allocation, and distributed arbitrary-interval exclusion remain deferred.

## Suggested Next Step

TASK 016 as prepared by ChatGPT (likely payment consuming the immutable quote). Do not begin it in this task.

## Errors / Warnings

- Flutter `RadioListTile` groupValue/onChanged is deprecated after v3.32; confirmation uses `ListTile` selection instead.
- `dart_frog dev` is avoided (known non-TTY StdinException); production `dart_frog build` + `dart build\bin\server.dart` used for live GETs, matching TASK 014.
- Different-slot overlap remains application-enforced, not a Mongo exclusion constraint.

## Security Verification

Confirmed: booking customer from auth; slot cleaner/service backend-derived; address ownership; same-slot partial unique reservation; idempotency uniqueness; fingerprint handling; conditional status transitions; reserved availability protections; discovery exclusion; customer DTO privacy; cleaner coarse/full address boundary; no security fields on bookings; no raw database errors; no new auth implementation; no token/password logging; Flutter secrets absent; `.env` ignored.

## Git Status

Uncommitted (not staged). `git check-ignore -v backend/.env` → `.gitignore:8:.env`.

## Issues / Warnings

See Errors / Warnings above. No payment/chat/reviews implemented.

## Final Statement

Atomic booking reservation, booking lifecycle, and customer/cleaner job-management are complete and ready for ChatGPT review. Payment, chat, and reviews are not implemented. TASK 016 was not started. TASK 015 is uncommitted.
