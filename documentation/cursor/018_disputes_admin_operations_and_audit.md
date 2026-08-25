# Cursor Task 018 — Disputes, Administrative Operations, and Audit Trail

## Metadata

- Task ID: 018
- Task title: Disputes, Admin Operations, Account Moderation, Booking Oversight, and Audit Trail
- Date: 2026-08-26
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Implement booking-scoped disputes, admin user management, admin booking oversight with payment-aware cancellation, and an append-only best-effort audit trail. Do not implement payouts, password recovery, MFA, real payment providers, push, WebSockets, file evidence, chargebacks, legal adjudication, or AI. Do not commit.

## Exact Cursor Prompt

~~~~text
# TASK 018 — Disputes, Admin Operations, Account Moderation, Booking Oversight, and Audit Trail

Repository:

D:\freelance\erfankhan_cse489\final

TASK 017 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

The marketplace currently supports:

- authentication and secure refresh sessions;
- persisted-role authorization;
- customer profiles and addresses;
- cleaner onboarding/admin approval;
- cleaner services and availability;
- discovery/comparison;
- atomic booking reservation;
- booking lifecycle;
- sandbox payment architecture;
- signed payment webhooks;
- refunds;
- chat;
- in-app notifications;
- verified reviews;
- admin review moderation.

TASK 018 must implement the marketplace's operational/admin-support layer.

Implement:

DISPUTES
- booking-scoped disputes;
- customer or cleaner may open a dispute;
- one active dispute per booking;
- structured dispute lifecycle;
- participant evidence/statement text;
- admin review;
- admin resolution;
- dispute history;
- participant visibility;
- safe status notifications.

ADMIN USER MANAGEMENT
- paginated user listing;
- user detail;
- filter by role/status;
- suspend account;
- reactivate account;
- deactivate account;
- protect administrator accounts from unsafe operations;
- revoke sessions when account becomes unavailable.

ADMIN BOOKING OVERSIGHT
- paginated booking list;
- booking detail;
- filters;
- safe customer/cleaner information;
- payment summary;
- dispute summary;
- admin cancellation of eligible bookings;
- payment-aware refund-before-cancel behavior.

AUDIT LOG
- append-only admin audit records;
- account moderation audit;
- cleaner approval/rejection audit;
- review moderation audit;
- payment refund audit;
- dispute action audit;
- admin booking cancellation audit;
- safe admin audit viewer.

FLUTTER
- customer/cleaner dispute flow;
- dispute status/history;
- admin dispute queue/detail/resolution;
- admin Users UI;
- admin Booking Operations UI;
- admin Audit Log UI;
- route guards;
- tests.

Do NOT implement:

- payouts;
- cleaner earnings settlement;
- password recovery;
- email verification;
- MFA;
- real external payment gateway;
- push notifications;
- WebSockets;
- file uploads/evidence attachments;
- chargebacks;
- legal adjudication;
- AI moderation;
- AI fraud detection;
- AI dispute resolution.

No AI features.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct package

FLUTTER:
no new direct package

Reuse existing:

- Dart Frog;
- mongo_dart;
- hashlib;
- Dio;
- Riverpod;
- go_router;
- existing authentication;
- booking;
- payment;
- notification;
- admin architecture.

Do NOT add another state manager/router/networking package.

If a genuinely unavoidable dependency is required:

STOP before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 017 checkpoint:

Backend:

dart analyze:
clean

dart test:
416 passed

Flutter:

flutter analyze:
clean

flutter test:
302 passed

Verify these exact baselines before implementation.

Use Dart Frog CLI as:

dart pub global run dart_frog_cli:dart_frog list

Do NOT rely on plain:

dart_frog list

because the CLI is not currently directly available on PATH.

======================================================================
DISPUTES COLLECTION
======================================================================

Create:

disputes

Document:

{
  "_id": ObjectId,

  "booking_id": ObjectId,
  "customer_user_id": ObjectId,
  "cleaner_user_id": ObjectId,

  "opened_by_user_id": ObjectId,
  "opened_by_role": String,

  "category": String,
  "status": String,

  "subject": String,
  "description": String,

  "resolution": String?,
  "resolved_by": ObjectId?,
  "resolved_at": DateTime?,

  "created_at": DateTime,
  "updated_at": DateTime,

  "history": [
    {
      "from_status": String?,
      "to_status": String,
      "actor_user_id": ObjectId,
      "actor_role": String,
      "note": String?,
      "created_at": DateTime
    }
  ]
}

All timestamps:

UTC.

Do NOT store:

password
JWT
refresh token
payment credentials
full UserAccount
full address
webhook secret
Mongo URI

inside dispute.

======================================================================
DISPUTE STATUS
======================================================================

Create enum:

DisputeStatus

Wire values:

open
under_review
resolved
closed

Lifecycle:

creation:
none → open

admin starts review:
open → under_review

admin resolves:
open → resolved
under_review → resolved

participant/admin closes resolved dispute:
resolved → closed

No transition out of:

closed

Do NOT reopen in TASK 018.

Invalid transition:

409
invalid_dispute_state

======================================================================
DISPUTE CATEGORY
======================================================================

Create enum:

DisputeCategory

Allowed values:

service_quality
cleaner_no_show
customer_no_show
payment_issue
booking_issue
conduct
other

Do not allow arbitrary category strings.

======================================================================
DISPUTE ELIGIBILITY
======================================================================

Only:

booking.customer_user_id
booking.cleaner_user_id

may open a dispute.

Admin cannot create a dispute pretending to be a participant.

Eligible booking states:

confirmed
in_progress
completed
cancelled

Do NOT allow dispute for:

pending
declined

Reason:

no accepted/active service relationship was established.

If booking belongs to another user:

404
booking_not_found

If state invalid:

409
dispute_not_allowed

======================================================================
ONE ACTIVE DISPUTE PER BOOKING
======================================================================

At most one dispute with status:

open
under_review
resolved

may exist per booking.

A:

closed

historical dispute does not permit another dispute in TASK 018.

Therefore simpler policy:

ONE dispute document total per booking.

Create unique index:

disputes_booking_unique

booking_id: 1

unique:
true

If already exists:

409
dispute_already_exists

Do not create dispute threads per issue yet.

======================================================================
DISPUTE SUBJECT
======================================================================

Required String.

Trim.

5–120 Unicode code points.

Reject control characters.

Plain text.

======================================================================
DISPUTE DESCRIPTION
======================================================================

Required String.

Trim.

20–3000 Unicode code points.

Allow newline/tab.

Reject other control characters.

Plain text only.

No HTML rendering.

======================================================================
DISPUTE RESOLUTION
======================================================================

Admin resolution:

required.

Trim.

10–3000 Unicode code points.

Plain text.

Allow newline/tab.

Reject other controls.

This is an operational resolution note.

Do NOT claim:

legal judgment
financial chargeback
court finding

in product/domain terminology.

======================================================================
DISPUTE HISTORY
======================================================================

Embedded history is intentional.

Each lifecycle transition appends:

from_status
to_status
actor_user_id
actor_role
note
created_at

Creation:

from_status:
null

to_status:
open

actor:
participant.

Status update + history append MUST occur in the same atomic dispute-document
update.

Do not create a separate dispute history collection.

======================================================================
DISPUTE PARTICIPANT PRIVACY
======================================================================

Customer-facing dispute:

may contain:

booking id
category
subject
description
status
resolution
history
timestamps
cleaner public display name

Do NOT expose cleaner:

email
phone
account internals.

Cleaner-facing:

same operational dispute data.

Customer identity:

customer profile full name if available,
otherwise "Customer".

Do NOT expose customer:

email
phone
full booking address beyond what booking lifecycle already permits.

Admin may see:

customer_user_id
cleaner_user_id
booking information required for operations.

No password/security/session fields.

======================================================================
DISPUTE ROUTES — PARTICIPANTS
======================================================================

Shared authenticated:

POST /api/v1/bookings/[bookingId]/dispute

GET /api/v1/bookings/[bookingId]/dispute

POST /api/v1/bookings/[bookingId]/dispute/close

Allowed roles:

customer
cleaner

but ONLY if authenticated persisted user is booking participant.

Admin:

not through these participant routes.

POST create:

201.

GET no dispute:

200

{
  "success": true,
  "data": {
    "dispute": null
  }
}

Close:

only when status == resolved.

resolved → closed.

Actor must be booking participant.

Admin has separate route.

======================================================================
ADMIN DISPUTE API
======================================================================

Add:

GET /api/v1/admin/disputes

GET /api/v1/admin/disputes/[disputeId]

POST /api/v1/admin/disputes/[disputeId]/review

POST /api/v1/admin/disputes/[disputeId]/resolve

POST /api/v1/admin/disputes/[disputeId]/close

Admin role only.

======================================================================
ADMIN DISPUTE LIST
======================================================================

Query:

status
category
booking_id
customer_user_id
cleaner_user_id
limit
after

limit:

default 20
minimum 1
maximum 50

after:

ObjectId cursor.

Sort:

_id descending.

No offset pagination.

Default status:

open

unless implementation has a strong reason to default all.

Prefer:

open.

======================================================================
ADMIN START REVIEW
======================================================================

POST:

/api/v1/admin/disputes/[disputeId]/review

Allowed only:

open → under_review

Use conditional atomic selector.

If already under_review:

idempotent 200 acceptable.

Resolved/closed:

409 invalid_dispute_state.

======================================================================
ADMIN RESOLVE
======================================================================

POST:

/api/v1/admin/disputes/[disputeId]/resolve

Body:

{
  "resolution": "..."
}

Allowed:

open
under_review

→ resolved.

Set:

resolution
resolved_by
resolved_at
updated_at
history append.

Conditional atomic update.

======================================================================
ADMIN CLOSE
======================================================================

Admin may close:

resolved → closed.

Conditional update.

Do not erase resolution.

======================================================================
DISPUTE NOTIFICATIONS
======================================================================

Use existing NotificationService.

Dispute created:

notify OTHER booking participant.

Type:

dispute_opened

Admin starts review:

notify customer + cleaner:

dispute_under_review

Admin resolves:

notify customer + cleaner:

dispute_resolved

Closed:

notification optional.

If implemented:

dispute_closed.

Add explicit notification enums rather than raw strings.

Notification failure remains:

best-effort

as established TASK 017.

Do not weaken primary dispute operation.

======================================================================
USER ACCOUNT MANAGEMENT
======================================================================

Existing:

UserRole:
customer
cleaner
admin

Existing AccountStatus:

active
suspended
deactivated

TASK 018 adds admin operational management.

======================================================================
ADMIN USER ROUTES
======================================================================

Add:

GET /api/v1/admin/users

GET /api/v1/admin/users/[userId]

POST /api/v1/admin/users/[userId]/suspend

POST /api/v1/admin/users/[userId]/reactivate

POST /api/v1/admin/users/[userId]/deactivate

Admin only.

======================================================================
ADMIN USER LIST
======================================================================

Query:

role
status
email
limit
after

role optional:

customer
cleaner
admin

status optional:

active
suspended
deactivated

email:

optional search against normalized exact email only.

Do NOT implement regex/substring email database scanning yet.

Normalize using existing email normalization.

limit:

default 20
1–50

after:

user ObjectId cursor.

Sort:

_id descending.

Return SAFE fields:

id
role
email
account_status
email_verified
created_at
updated_at

Optional safe profile summary:

full_name
cleaner onboarding status

Do not expose:

password_hash
email_normalized
sessions
refresh-token hashes
password-reset data.

======================================================================
ADMIN USER DETAIL
======================================================================

Return safe:

UserAccount public fields

+
role-specific profile

+
operational summaries:

booking counts if practical
open dispute indicator/count
cleaner onboarding status
payment transaction count if practical

Avoid N+1.

Do not expose security credentials.

======================================================================
ACCOUNT SUSPEND
======================================================================

POST:

/api/v1/admin/users/[userId]/suspend

Body:

{
  "reason": "..."
}

Reason:

required
5–500 Unicode code points
trim
plain text
reject controls.

Allowed target:

customer
cleaner

active → suspended.

If already suspended:

idempotent 200 acceptable.

Do NOT suspend:

admin

through TASK 018 API.

Attempt:

403
protected_admin_account

Critical:

after successful suspension:

revoke ALL refresh sessions for target user.

Existing access JWT may still exist briefly, but persisted-user authorization must reject
the account immediately because account_status != active.

Do not change role.

======================================================================
ACCOUNT REACTIVATE
======================================================================

POST:

/api/v1/admin/users/[userId]/reactivate

Allowed target:

customer
cleaner.

suspended → active.

Do NOT reactivate:

deactivated

using this route.

If already active:

idempotent 200 acceptable.

Admin accounts:

protected from this operational endpoint.

======================================================================
ACCOUNT DEACTIVATE
======================================================================

POST:

/api/v1/admin/users/[userId]/deactivate

Body:

{
  "reason": "..."
}

Allowed target:

customer
cleaner.

active/suspended → deactivated.

Deactivation is not deletion.

After successful deactivation:

revoke all sessions.

Do not delete:

bookings
payments
reviews
messages
disputes

because they are historical marketplace records.

Deactivated → active is NOT supported in TASK 018.

No public admin restore route yet.

======================================================================
ACCOUNT MODERATION NOTES
======================================================================

Do NOT add moderation reason fields directly to users.

Reasons belong in:

audit_logs.

User remains identity/security entity.

======================================================================
SELF-TARGET PROTECTION
======================================================================

Current admin MUST NOT:

suspend themselves
deactivate themselves

Even if future admin-target operations are enabled.

For TASK 018 all admin targets are protected anyway.

Return:

403
protected_admin_account

======================================================================
SESSION REVOCATION
======================================================================

Reuse:

AuthSessionService

or existing equivalent.

Do not write directly to session collection from route handler.

Suspension/deactivation:

account status update succeeds
→ revoke all sessions.

If session revocation unexpectedly fails after account status changed:

account remains unavailable because persisted status is authoritative.

Report/log limitation.

Do not revert account status merely to restore sessions.

======================================================================
ADMIN BOOKING OPERATIONS
======================================================================

Add:

GET /api/v1/admin/bookings

GET /api/v1/admin/bookings/[bookingId]

POST /api/v1/admin/bookings/[bookingId]/cancel

Admin role only.

======================================================================
ADMIN BOOKING LIST
======================================================================

Query:

status
customer_user_id
cleaner_user_id
service_id
from
to
limit
after

status optional.

Dates:

explicit timezone/offset
normalize UTC.

Filter by:

booking.start_at

limit:

20 default
1–50

after:

booking ObjectId.

Sort:

_id descending.

No offset.

Return safe operational summary:

booking id
status
customer id
cleaner id
customer display name
cleaner display name
service name
start/end
quoted total
currency
payment summary
dispute summary.

Avoid N+1.

======================================================================
ADMIN BOOKING DETAIL
======================================================================

Return:

booking safe operational data
status history
service snapshot
pricing snapshot
address snapshot
payment summary/history
dispute summary
customer/cleaner ids and safe display/profile information

Because admin is operating booking support, full booking address may be visible.

Do NOT expose:

password
tokens
session information
payment secret
webhook secret
raw provider payload.

======================================================================
ADMIN BOOKING CANCELLATION
======================================================================

POST:

/api/v1/admin/bookings/[bookingId]/cancel

Body:

{
  "reason": "..."
}

Reason:

required
5–500 Unicode.

Admin may cancel only:

pending
confirmed

Do NOT cancel:

in_progress
completed
declined
cancelled

Pending:

use booking conditional cancellation.

Confirmed:

MUST use existing payment-aware cancellation orchestration.

If pending/authorized payment:

cancel payment first.

If paid/partially_refunded:

refund remaining amount first.

Only after payment state is safe:

cancel booking.

If refund fails:

booking remains unchanged/confirmed.

Do NOT bypass TASK 016 financial consistency.

Admin cancellation history actor:

admin user id
admin role.

If existing booking cancellation repository does not support admin actor cleanly:

extend it narrowly.

Do not impersonate customer/cleaner actor.

======================================================================
ADMIN BOOKING CANCELLATION NOTIFICATION
======================================================================

After successful admin cancellation:

notify:

customer
cleaner

booking_cancelled

Safe body:

"An administrator cancelled this booking."

Do not expose admin email.

======================================================================
AUDIT LOG COLLECTION
======================================================================

Create:

audit_logs

Document:

{
  "_id": ObjectId,

  "actor_user_id": ObjectId,
  "actor_role": String,

  "action": String,

  "target_type": String,
  "target_id": ObjectId,

  "reason": String?,

  "metadata": Map<String, safe scalar values>,

  "created_at": DateTime
}

Audit logs are:

append-only.

No update/delete repository method in TASK 018.

======================================================================
AUDIT ACTION ENUM
======================================================================

Create explicit audit actions:

user_suspended
user_reactivated
user_deactivated

cleaner_approved
cleaner_rejected

review_hidden
review_unhidden

payment_refund_requested

dispute_review_started
dispute_resolved
dispute_closed

booking_admin_cancelled

Do not scatter arbitrary strings.

======================================================================
AUDIT METADATA SAFETY
======================================================================

Metadata may contain safe operational identifiers/state such as:

previous_status
new_status
booking_id
payment_id
refund_amount_minor
currency_code

Do NOT place in metadata:

password
password hash
JWT
refresh token
idempotency key
request fingerprint
webhook signature
webhook secret
Mongo URI
full service address
private message body
full payment-provider response.

Keep audit metadata deliberately small.

======================================================================
AUDIT CONSISTENCY
======================================================================

Audit write occurs AFTER successful primary admin action.

There is no cross-document transaction/outbox yet.

Therefore:

primary admin action remains authoritative.

If audit insertion fails:

do NOT roll back a successful:

account moderation
review moderation
payment refund request
booking cancellation
dispute resolution

solely because audit log insert failed.

However:

audit failure should be surfaced to server diagnostics/logging where existing safe
logging allows, without exposing internals to client.

Document:

audit logging is best-effort cross-document in TASK 018,
not transactionally guaranteed.

Do NOT falsely claim compliance-grade exactly-once audit persistence.

Future outbox/transaction strategy is deferred.

======================================================================
AUDIT REPOSITORY
======================================================================

Create:

AuditLogRepository

Only:

append
listPage
findById

No update.

No delete.

======================================================================
AUDIT SERVICE
======================================================================

Create:

AuditLogService

or:

AuditSink

for integrations.

Keep admin services independent from Mongo audit implementation where practical.

======================================================================
AUDIT ADMIN API
======================================================================

Add:

GET /api/v1/admin/audit-logs

GET /api/v1/admin/audit-logs/[auditLogId]

Admin only.

Filters:

actor_user_id
action
target_type
target_id
from
to
limit
after

limit:

20 default
1–50

sort:

_id descending

cursor:

_id < after.

No offset.

======================================================================
AUDIT LOG PRIVACY
======================================================================

Admin may see:

actor id
action
target type/id
reason
safe metadata
time

Do not enrich logs with password/session/security data.

Do not expose audit API outside admin role.

======================================================================
EXISTING ADMIN ACTION AUDIT INTEGRATION
======================================================================

Integrate audit sink into existing admin operations where practical and safe:

CLEANER ONBOARDING

approve:
cleaner_approved

reject:
cleaner_rejected

REVIEW MODERATION

hide:
review_hidden

unhide:
review_unhidden

PAYMENT REFUND

after refund request accepted:
payment_refund_requested

Do not rewrite existing state machines.

Do not change existing behavior except audit side-effect injection.

Audit insertion failure must not corrupt primary action.

======================================================================
DISPUTE REPOSITORY
======================================================================

Create narrow:

DisputeRepository

Responsibilities:

findById
findByBookingId
create
adminPage
markUnderReview
resolve
close

Conditional status selectors mandatory.

No arbitrary update maps exposed.

======================================================================
ADMIN USER REPOSITORY EXTENSIONS
======================================================================

Extend UserRepository narrowly as needed:

adminPage
updateAccountStatusConditionally

Do NOT expose arbitrary security-field updates.

Possible operations:

setActiveToSuspended
setSuspendedToActive
setActiveOrSuspendedToDeactivated

or one domain-safe equivalent.

Use conditional selectors.

======================================================================
ADMIN USER SERVICE
======================================================================

Create:

AdminUserManagementService

Responsibilities:

listUsers
getUser
suspend
reactivate
deactivate

Compose:

UserRepository
CustomerProfileRepository
CleanerProfileRepository
AuthSessionService
AuditSink

Do not put Mongo queries in routes.

======================================================================
ADMIN BOOKING OPERATIONS SERVICE
======================================================================

Create:

AdminBookingOperationsService

Responsibilities:

list
detail
cancel

Compose:

BookingRepository
PaymentRepository/payment orchestration
DisputeRepository
profile/user repositories
NotificationSink
AuditSink.

Preserve payment consistency.

======================================================================
ADMIN DISPUTE SERVICE
======================================================================

Create:

AdminDisputeService

Participant side:

BookingDisputeService

or equivalent.

Thin HTTP routes.

======================================================================
HTTP ERROR CODES
======================================================================

Add safe codes as needed:

dispute_not_found
dispute_already_exists
dispute_not_allowed
invalid_dispute_state
invalid_dispute_subject
invalid_dispute_description
invalid_dispute_resolution

user_not_found
protected_admin_account
invalid_account_state
invalid_moderation_reason

admin_booking_not_cancellable

audit_log_not_found

Reuse existing:

booking_not_found
invalid_booking_state
payment_refund_failed
forbidden
account_unavailable

where semantically correct.

Do not expose raw Mongo errors.

======================================================================
DATABASE INDEXES
======================================================================

DISPUTES

1.

disputes_booking_unique

booking_id: 1
unique: true

2.

disputes_status_id_desc

status: 1
_id: -1

3.

disputes_customer_id_desc

customer_user_id: 1
_id: -1

4.

disputes_cleaner_id_desc

cleaner_user_id: 1
_id: -1

5.

disputes_category_status_id_desc

category: 1
status: 1
_id: -1

Evaluate redundancy with actual query patterns.

USERS

Existing email unique index remains.

Add only if useful for admin listing:

users_role_status_id_desc

role: 1
account_status: 1
_id: -1

Assess query usefulness.

Do not add redundant indexes blindly.

AUDIT_LOGS

1.

audit_logs_actor_id_desc

actor_user_id: 1
_id: -1

2.

audit_logs_action_id_desc

action: 1
_id: -1

3.

audit_logs_target_id_desc

target_type: 1
target_id: 1
_id: -1

4.

audit_logs_created_at

created_at: -1
_id: -1

Evaluate whether created_at + _id adds enough value for requested date filtering.

Use deliberate index reasoning.

======================================================================
COLLECTION NAMES
======================================================================

Extend central collection constants with:

disputes
audit_logs

Do not scatter collection names.

======================================================================
LIVE DATABASE POLICY
======================================================================

TASK 018 may mutate live Atlas ONLY through:

controlled index ensure.

It MUST NOT create/update live:

users
bookings
payments
disputes
audit logs
sessions
reviews
messages
notifications

for testing.

Do NOT suspend a real account.

Do NOT cancel a real booking.

Do NOT create a real dispute.

Automated tests use fakes/in-memory seams.

======================================================================
BACKEND TESTS — DISPUTES
======================================================================

Test:

customer opens eligible dispute
cleaner opens eligible dispute
foreign participant hidden
admin cannot participant-create
pending booking blocked
declined blocked
confirmed allowed
in_progress allowed
completed allowed
cancelled allowed

category validation
subject validation
description validation

creation:
status open
history creation entry
correct actor
booking participant ids derived

second dispute same booking:
409

get none
get own
foreign hidden

participant close:
resolved → closed
open cannot close
under_review cannot close
closed terminal.

======================================================================
BACKEND TESTS — ADMIN DISPUTES
======================================================================

Test:

admin list
default open
status/category filters
cursor
detail
missing
customer/cleaner forbidden

review:
open → under_review
idempotent under_review
resolved rejected
history actor admin

resolve:
open → resolved
under_review → resolved
resolution validation
resolved_by admin
resolved_at
history

close:
resolved → closed
conditional state

Notifications:

opened → other participant
review → both
resolve → both

dedupe.

Audit:

review
resolve
close.

======================================================================
BACKEND TESTS — USER MANAGEMENT
======================================================================

Test:

admin list
role filter
status filter
exact normalized email filter
pagination
safe serialization

detail:
customer
cleaner
missing
no password/hash/session fields.

suspend:
active customer
active cleaner
session revoke called
persisted account unavailable immediately
reason validation

already suspended:
chosen idempotent behavior

reactivate:
suspended → active
active idempotent
deactivated rejected

deactivate:
active → deactivated
suspended → deactivated
sessions revoked

admin target:
protected

admin self:
protected

customer/cleaner calling endpoints:
403

conditional-state behavior.

Audit created for actual successful state changes.

Idempotent no-op should not create misleading duplicate audit unless deliberate
policy says otherwise.

======================================================================
BACKEND TESTS — ADMIN BOOKINGS
======================================================================

List:

filters
cursor
safe DTO
payment/dispute summary
no N+1 if batch strategy used.

Detail:

safe operational data
payment
dispute
no security data.

Cancellation:

pending
confirmed unpaid
confirmed pending payment
confirmed paid
refund succeeds
refund fails keeps booking confirmed
in_progress blocked
completed blocked
foreign concept irrelevant to admin
reason validation
history actor admin
customer+cleaner notifications
audit entry

Do not bypass conditional booking transition.

======================================================================
BACKEND TESTS — AUDIT
======================================================================

Test:

append
list
filters
cursor
detail
missing

safe metadata

no update method
no delete method

Integration:

cleaner approve
cleaner reject
review hide
review unhide
payment refund request
dispute review/resolve/close
user moderation
admin booking cancellation

Audit write failure:

primary action remains successful.

No secrets/private message/address data written.

======================================================================
BACKEND REGRESSION
======================================================================

All existing:

auth
authorization
onboarding
service
availability
discovery
booking
payment
webhook
chat
notification
review

tests must remain green.

Do not weaken existing persisted-role rules.

======================================================================
FLUTTER DISPUTE MODELS
======================================================================

Create:

DisputeStatus
DisputeCategory
DisputeHistoryEntry
BookingDispute
AdminDisputeSummary
AdminDisputeDetail

Unknown enum values:

safe unknown/unsupported behavior.

======================================================================
FLUTTER PARTICIPANT DISPUTE API
======================================================================

Use authenticated Dio.

Operations:

getForBooking
create
close

No arbitrary participant id.

======================================================================
FLUTTER ADMIN DISPUTE API
======================================================================

Operations:

list
detail
markUnderReview
resolve
close

Admin authenticated Dio.

======================================================================
CUSTOMER / CLEANER BOOKING DETAIL
======================================================================

Add:

Report a Problem

for eligible:

confirmed
in_progress
completed
cancelled

If dispute exists:

View Dispute

Do not show:

pending
declined

create CTA.

======================================================================
PARTICIPANT DISPUTE SCREEN
======================================================================

Routes:

/customer/bookings/:bookingId/dispute

/cleaner/bookings/:bookingId/dispute

Screen:

if none:
create form

Category
Subject
Description

if existing:
status
subject
description
resolution when available
history

If resolved:

Close Dispute

No file attachment UI.

No chat-like evidence thread.

Existing booking chat remains separate.

======================================================================
ADMIN DISPUTE UI
======================================================================

Routes:

/admin/disputes
/admin/disputes/:disputeId

Admin home:

Disputes

List:

status
category
subject
booking
participants
created time

Filters.

Load More.

Detail:

full safe dispute
history
booking summary

Actions:

Start Review
Resolve
Close

Resolution dialog:

required text.

======================================================================
FLUTTER ADMIN USER MODELS / API
======================================================================

Create safe models for:

AdminUserSummary
AdminUserDetail

API:

list
detail
suspend
reactivate
deactivate

Use existing authenticated Dio.

======================================================================
ADMIN USERS UI
======================================================================

Routes:

/admin/users
/admin/users/:userId

AdminHomeScreen:

Users

List:

email
role
status
profile name where available
created date

Filters:

role
status

Optional exact email search field.

Load More.

Detail:

safe account/profile info
status

Actions for customer/cleaner:

Suspend
Reactivate
Deactivate

Confirmation dialogs.

Suspend/deactivate require reason.

No admin moderation actions on admin accounts.

Display:

Protected administrator account

for admin target.

======================================================================
FLUTTER ADMIN BOOKING API
======================================================================

Create admin operations API/repository/controller.

Operations:

list
detail
cancel

Use authenticated Dio.

======================================================================
ADMIN BOOKING OPERATIONS UI
======================================================================

Routes:

/admin/bookings
/admin/bookings/:bookingId

AdminHomeScreen:

Bookings

List:

status
customer
cleaner
service
schedule
quoted total
payment status
dispute status

Filters:

status
date range

Load More.

Detail:

booking lifecycle
service
schedule
address
payment summary
dispute summary
status history.

If eligible:

Cancel Booking

Reason required.

Show warning when paid booking requires refund.

Backend remains authoritative.

Do not simulate refund locally.

======================================================================
FLUTTER AUDIT MODELS / API
======================================================================

Create:

AuditAction
AdminAuditLogSummary
AdminAuditLogDetail

API:

list
detail

Admin only.

======================================================================
ADMIN AUDIT UI
======================================================================

Routes:

/admin/audit-logs
/admin/audit-logs/:auditLogId

AdminHomeScreen:

Audit Log

List:

time
action
actor
target type/id

Filters:

action
target type

Load More.

Detail:

safe reason
metadata
actor/target
timestamp.

Do not render arbitrary JSON unsafely.

Format known scalar metadata.

======================================================================
FLUTTER CONTROLLERS
======================================================================

Create focused Riverpod controllers:

BookingDisputeController
AdminDisputeController
AdminUserManagementController
AdminBookingOperationsController
AdminAuditLogController

Do not add this state to:

AuthController
BookingController
PaymentController

except feature coordination through repositories/providers where necessary.

======================================================================
FLUTTER NOTIFICATION INTEGRATION
======================================================================

Extend NotificationType for dispute events.

Explicit resource mapping:

dispute notification
→ role-appropriate dispute screen

Do not trust server-provided arbitrary routes.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Add safe messages for:

dispute_not_found
dispute_already_exists
dispute_not_allowed
invalid_dispute_state
invalid_dispute_subject
invalid_dispute_description
invalid_dispute_resolution
user_not_found
protected_admin_account
invalid_account_state
invalid_moderation_reason
admin_booking_not_cancellable
audit_log_not_found

Reuse payment refund error mapping.

Never show:

DioException.toString()
raw Mongo errors
stack traces
security secrets.

======================================================================
FLUTTER TESTS — DISPUTES
======================================================================

API/models:
parse
create
get
close
admin list/detail/review/resolve/close
safe errors

Participant controller:
none
create
existing
close
safe error

Widgets:
eligible Report a Problem
ineligible no CTA
create form
validation
existing status
history
resolved close

Admin:
home entry
list
filters
detail
start review
resolve dialog
close.

======================================================================
FLUTTER TESTS — ADMIN USERS
======================================================================

API/controller:

list
filters
pagination
detail
suspend
reactivate
deactivate
safe errors.

Widgets:

Users home entry
list
role/status filter
detail
suspend confirmation
reason
reactivate
deactivate
protected admin state.

======================================================================
FLUTTER TESTS — ADMIN BOOKINGS
======================================================================

API/controller:

list
filters
pagination
detail
cancel
refund error mapping.

Widgets:

Bookings entry
list
detail
payment/dispute summary
eligible cancel
reason dialog
paid warning
failure state.

======================================================================
FLUTTER TESTS — AUDIT
======================================================================

API/controller:

list
filter
pagination
detail
safe errors

Widgets:

Audit Log entry
list
filters
detail
safe metadata rendering.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Customer:

customer dispute route allowed.

Cleaner:

cleaner dispute route allowed.

Cross-role participant dispute paths:

redirect to own role home.

Admin:

admin disputes
admin users
admin bookings
admin audit

allowed.

Customer/cleaner:

admin operational routes forbidden via UX guard.

Admin:

participant dispute routes redirected admin home.

Notifications remain shared.

Logout/session expiry remains login.

All previous routes remain green.

======================================================================
SECURITY AUDIT
======================================================================

DISPUTES

Confirm:

- booking participant derived server-side;
- foreign booking/dispute hidden;
- admin cannot impersonate participant;
- conditional states;
- no contact/security data leaked.

USER MODERATION

Confirm:

- only persisted admin may moderate;
- target body cannot override IDs;
- admin targets protected;
- sessions revoked after suspension/deactivation;
- historical data not deleted;
- password/security fields never exposed.

ADMIN BOOKINGS

Confirm:

- admin role required;
- cancellation uses payment-aware orchestration;
- paid booking refund happens before cancellation;
- financial state cannot be bypassed;
- no provider/webhook secrets exposed.

AUDIT

Confirm:

- append-only repository;
- admin-only read;
- safe metadata;
- no secrets;
- primary action not corrupted by audit failure.

GLOBAL

Confirm:

- stale JWT role still cannot authorize;
- no new auth stack;
- no password/token logging;
- no secrets in Flutter;
- backend/.env ignored.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/disputes-collection.md

documentation/database/audit-logs-collection.md

Document:

fields
status lifecycle
history
ownership
indexes
privacy
admin operations
best-effort audit limitation.

======================================================================
DOCUMENTATION — API
======================================================================

Create:

documentation/api/dispute-api.md

documentation/api/admin-operations-api.md

Document:

participant dispute routes
admin dispute routes
user management
booking operations
audit routes
validation
filters
cursor pagination
errors
safe examples.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/disputes-admin-operations-and-audit.md

Document flows:

PARTICIPANT DISPUTE

booking participant
→ dispute create
→ history
→ notification
→ admin review
→ resolve
→ close

ACCOUNT MODERATION

admin
→ persisted admin authorization
→ conditional user status
→ session revocation
→ audit

ADMIN BOOKING CANCELLATION

admin
→ booking
→ payment state
→ refund/cancel payment if necessary
→ booking cancellation
→ notifications
→ audit

AUDIT

primary action
→ best-effort append-only audit log

Explain no transactional outbox/transaction guarantee.

======================================================================
ADR-016
======================================================================

Create:

documentation/decisions/ADR-016-disputes-admin-operations-and-audit.md

Required:

# ADR-016 — Disputes, Administrative Operations, and Audit Trail

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision must cover:

- one dispute per booking;
- eligible booking states;
- embedded dispute history;
- participant-only dispute creation;
- admin dispute lifecycle;
- account suspension/reactivation/deactivation;
- session revocation;
- administrator-account protection;
- admin booking oversight;
- payment-aware admin cancellation;
- append-only audit log;
- best-effort cross-document audit write;
- safe audit metadata;
- keyset pagination.

Alternatives:

### Multiple dispute threads per booking
Deferred to reduce operational ambiguity in initial marketplace workflow.

### Allow admin to create participant dispute
Rejected because admin should review, not impersonate marketplace participants.

### Delete suspended/deactivated user data
Rejected because bookings/payments/reviews/audit require historical integrity.

### Put moderation reason on users
Rejected because moderation actions belong in audit history.

### Allow cancelling paid booking before refund
Rejected due financial inconsistency risk.

### Mutable audit records
Rejected because audit trail should be append-only.

### Transactional outbox immediately
Deferred; existing architecture does not yet contain worker/outbox infrastructure.

Deferred:

appeals
evidence uploads
admin chat access
legal workflow
chargebacks
automated fraud detection
AI moderation
distributed outbox
SIEM export
audit retention automation
admin role hierarchy.

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
documentation/architecture/booking-reservation-and-lifecycle.md
documentation/architecture/payment-processing-and-webhooks.md
documentation/architecture/chat-notifications-and-reviews.md

backend/README.md
project/README.md
README.md

Do not claim:

payouts
password reset
MFA
real payment provider
AI moderation

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

clean working tree

latest commit:
TASK 017 checkpoint

Verify:

documentation/cursor/017_chat_notifications_reviews_and_moderation.md

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

416 tests
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

302 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new direct dependency.

If one is genuinely required:

STOP before adding.

======================================================================
STEP 5 — DISPUTE DOMAIN / DATA

Implement:

Dispute
DisputeStatus
DisputeCategory
history
validation
repository
indexes
safe DTOs.

Add tests.

======================================================================
STEP 6 — DISPUTE SERVICES

Implement:

BookingDisputeService
AdminDisputeService

participant authorization
conditional lifecycle
notifications
audit integration.

Tests.

======================================================================
STEP 7 — ADMIN USER MANAGEMENT

Implement:

repository extensions
AdminUserManagementService
safe DTOs
session revocation
admin protection
audit integration.

Tests.

======================================================================
STEP 8 — ADMIN BOOKING OPERATIONS

Implement:

list/detail/cancel
batch summaries
payment-aware cancellation
notifications
audit.

Tests.

======================================================================
STEP 9 — AUDIT DOMAIN

Implement:

AuditLog
AuditAction
AuditLogRepository
AuditLogService/AuditSink
admin list/detail.

Append-only.

Tests.

======================================================================
STEP 10 — EXISTING ADMIN AUDIT INTEGRATION

Add audit sink to:

cleaner approve/reject
review hide/unhide
payment refund request

without changing their existing business-state correctness.

Add regression tests.

======================================================================
STEP 11 — BACKEND ROUTES

Implement:

participant dispute
admin dispute
admin users
admin bookings
admin audit logs.

Thin route handlers.

======================================================================
STEP 12 — BACKEND PRE-LIVE VERIFICATION

Run:

dart format .
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

All green.

Record exact final backend test count/routes.

======================================================================
STEP 13 — LIVE INDEX ENSURE

Run controlled database index ensure.

Only index metadata mutation.

Verify TASK 018 indexes.

No live application data mutation.

======================================================================
STEP 14 — FLUTTER DATA / APIS

Implement:

dispute
admin users
admin bookings
audit

models/repositories/APIs.

Authenticated Dio only.

======================================================================
STEP 15 — FLUTTER CONTROLLERS

Implement focused Riverpod controllers.

======================================================================
STEP 16 — FLUTTER ROUTING

Add participant/admin routes.

Preserve existing auth/role routing.

======================================================================
STEP 17 — FLUTTER UI

Implement:

participant dispute UI
admin dispute UI
admin user management UI
admin booking operations UI
admin audit UI

Update AdminHomeScreen.

======================================================================
STEP 18 — NOTIFICATION INTEGRATION

Extend dispute notification handling and explicit Flutter resource mapping.

======================================================================
STEP 19 — FLUTTER TESTS

Add comprehensive:

models
API
controller
router
widget

tests.

Then run:

dart format lib test
flutter analyze
flutter test

All green.

Record exact count.

======================================================================
STEP 20 — ANDROID DEBUG BUILD

Run:

flutter build apk --debug

Must succeed.

Do not alter release signing/security.

======================================================================
STEP 21 — SAFE LIVE BACKEND VERIFICATION

Only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Expected 200.

Do NOT live call:

disputes
admin users
admin bookings
audit

routes.

Do not mutate real accounts/bookings.

======================================================================
STEP 22 — SECURITY AUDIT

Perform all TASK 018 security checks.

Regression verify TASK 012–017 security remains green.

======================================================================
STEP 23 — DOCUMENTATION

Create:

documentation/database/disputes-collection.md
documentation/database/audit-logs-collection.md

documentation/api/dispute-api.md
documentation/api/admin-operations-api.md

documentation/architecture/disputes-admin-operations-and-audit.md

documentation/decisions/ADR-016-disputes-admin-operations-and-audit.md

Update indexes/readmes.

======================================================================
STEP 24 — FINAL BACKEND VERIFICATION

dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Record exact count.

======================================================================
STEP 25 — FINAL FLUTTER VERIFICATION

flutter analyze
flutter test
flutter build apk --debug

Record exact count.

======================================================================
STEP 26 — FINAL GIT REVIEW

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

.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
JWT
refresh token
password
private Atlas data
APK
build directory
SDK artifact
project/devtools_options.yaml
unrelated generated file

is tracked.

Do NOT stage.

======================================================================
STEP 27 — TASK REPORT

Create:

documentation/cursor/018_disputes_admin_operations_and_audit.md

Use existing task report template.

The report MUST contain COMPLETE EXACT TASK 018 prompt under:

## Exact Cursor Prompt

Document:

checkpoint
baselines
dependency audit
dispute schema
categories
status lifecycle
history
authorization
notifications
admin dispute queue
user moderation
session revocation
admin protection
admin booking operations
payment-aware cancellation
audit schema
audit actions
append-only design
audit consistency limitation
existing admin-action audit integration
indexes
live index ensure
backend routes
backend tests
Flutter APIs/controllers
participant dispute UX
admin dispute UX
admin user UX
admin booking UX
audit UX
Flutter tests
APK
safe live verification
security
live data safety
files
warnings
Git status.

Never include:

backend/.env
secrets
passwords
JWTs
refresh tokens
private Atlas records
real dispute content
real user moderation data.

======================================================================
STEP 28 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 018 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 018 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## Dispute Model

## Dispute Eligibility

## Dispute Lifecycle

## Participant Dispute API

## Admin Dispute Operations

## Dispute Notifications

## Admin User Management

## Session Revocation

## Administrator Protection

## Admin Booking Oversight

## Payment-Aware Admin Cancellation

## Audit Log

## Audit Integrations

## Audit Consistency

## MongoDB Indexes

## Backend Tests

## Backend Routes

## Flutter Participant Dispute Experience

## Flutter Admin Dispute Experience

## Flutter Admin User Experience

## Flutter Admin Booking Experience

## Flutter Audit Experience

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

State whether disputes + admin user management + booking oversight +
payment-aware admin cancellation + append-only audit trail are complete and
ready for ChatGPT review.

Do NOT implement payouts.

Do NOT implement password recovery.

Do NOT implement MFA.

Do NOT implement AI moderation.

Do NOT begin TASK 019.

Start TASK 018 now.
~~~~

## Pre-Task Repository State

- `git rev-parse --show-toplevel`: D:/freelance/erfankhan_cse489/final
- Branch: `main`
- Working tree: clean at TASK 017 checkpoint `a034243 chat_notifications_reviews_and_moderation`
- `documentation/cursor/017_chat_notifications_reviews_and_moderation.md`: SUCCESS
- `backend/.env` ignored (`.gitignore:8:.env`)
- Backend baseline: `dart analyze` clean; `dart test` 416 passed
- Flutter baseline: `flutter analyze` clean; `flutter test` 302 passed
- No new direct packages. Did not run `dart pub upgrade` or `flutter pub upgrade`.

## Work Performed

Implemented disputes (one document per booking, embedded history, participant + admin lifecycle, notifications), admin user moderation with session revocation and admin-account protection, admin booking list/detail/payment-aware cancel, append-only audit logs with best-effort writes, audit side-effects on existing cleaner/review/payment admin actions, Flutter participant and admin UIs/controllers/routes/tests, live index ensure only, documentation, ADR-016, and this report. Left uncommitted.

## Files Created

### Backend

- `backend/lib/src/features/disputes/domain/dispute.dart`
- `backend/lib/src/features/disputes/domain/dispute_status.dart`
- `backend/lib/src/features/disputes/domain/dispute_category.dart`
- `backend/lib/src/features/disputes/domain/dispute_history_entry.dart`
- `backend/lib/src/features/disputes/domain/dispute_validation.dart`
- `backend/lib/src/features/disputes/domain/dispute_exceptions.dart`
- `backend/lib/src/features/disputes/data/dispute_repository.dart`
- `backend/lib/src/features/disputes/data/dispute_indexes.dart`
- `backend/lib/src/features/disputes/application/booking_dispute_service.dart`
- `backend/lib/src/features/disputes/application/admin_dispute_service.dart`
- `backend/lib/src/features/audit/domain/audit_log.dart`
- `backend/lib/src/features/audit/domain/audit_action.dart`
- `backend/lib/src/features/audit/domain/audit_validation.dart`
- `backend/lib/src/features/audit/domain/audit_exceptions.dart`
- `backend/lib/src/features/audit/data/audit_log_repository.dart`
- `backend/lib/src/features/audit/data/audit_log_indexes.dart`
- `backend/lib/src/features/audit/application/audit_log_service.dart`
- `backend/lib/src/features/users/application/admin_user_management_service.dart`
- `backend/lib/src/features/bookings/application/admin_booking_operations_service.dart`
- `backend/routes/api/v1/bookings/_middleware.dart`
- `backend/routes/api/v1/bookings/[bookingId]/dispute/index.dart`
- `backend/routes/api/v1/bookings/[bookingId]/dispute/close.dart`
- `backend/routes/api/v1/admin/disputes/index.dart`
- `backend/routes/api/v1/admin/disputes/[disputeId]/index.dart`
- `backend/routes/api/v1/admin/disputes/[disputeId]/review.dart`
- `backend/routes/api/v1/admin/disputes/[disputeId]/resolve.dart`
- `backend/routes/api/v1/admin/disputes/[disputeId]/close.dart`
- `backend/routes/api/v1/admin/users/index.dart`
- `backend/routes/api/v1/admin/users/[userId]/index.dart`
- `backend/routes/api/v1/admin/users/[userId]/suspend.dart`
- `backend/routes/api/v1/admin/users/[userId]/reactivate.dart`
- `backend/routes/api/v1/admin/users/[userId]/deactivate.dart`
- `backend/routes/api/v1/admin/bookings/index.dart`
- `backend/routes/api/v1/admin/bookings/[bookingId]/index.dart`
- `backend/routes/api/v1/admin/bookings/[bookingId]/cancel.dart`
- `backend/routes/api/v1/admin/audit-logs/index.dart`
- `backend/routes/api/v1/admin/audit-logs/[auditLogId]/index.dart`
- `backend/test/helpers/recording_audit_sink.dart`
- `backend/test/src/features/disputes/disputes_admin_operations_test.dart`
- `backend/test/routes/api/v1/disputes_admin_operations_routes_test.dart`

### Flutter

- `project/lib/features/disputes/data/dispute_models.dart`
- `project/lib/features/disputes/data/dispute_api.dart`
- `project/lib/features/disputes/presentation/booking_dispute_controller.dart`
- `project/lib/features/disputes/presentation/booking_dispute_screen.dart`
- `project/lib/features/disputes/presentation/admin_dispute_controller.dart`
- `project/lib/features/disputes/presentation/admin_dispute_list_screen.dart`
- `project/lib/features/disputes/presentation/admin_dispute_detail_screen.dart`
- `project/lib/features/admin/data/admin_user_models.dart`
- `project/lib/features/admin/data/admin_user_api.dart`
- `project/lib/features/admin/data/admin_booking_models.dart`
- `project/lib/features/admin/data/admin_booking_api.dart`
- `project/lib/features/admin/data/audit_models.dart`
- `project/lib/features/admin/data/audit_api.dart`
- `project/lib/features/admin/presentation/admin_user_management_controller.dart`
- `project/lib/features/admin/presentation/admin_user_list_screen.dart`
- `project/lib/features/admin/presentation/admin_user_detail_screen.dart`
- `project/lib/features/admin/presentation/admin_booking_operations_controller.dart`
- `project/lib/features/admin/presentation/admin_booking_list_screen.dart`
- `project/lib/features/admin/presentation/admin_booking_detail_screen.dart`
- `project/lib/features/admin/presentation/admin_audit_log_controller.dart`
- `project/lib/features/admin/presentation/admin_audit_list_screen.dart`
- `project/lib/features/admin/presentation/admin_audit_detail_screen.dart`
- `project/test/features/disputes/data/dispute_api_test.dart`
- `project/test/features/disputes/presentation/booking_dispute_controller_test.dart`
- `project/test/features/disputes/presentation/booking_dispute_screens_test.dart`
- `project/test/features/admin/data/admin_operations_api_test.dart`
- `project/test/features/admin/presentation/admin_operations_screens_test.dart`

### Documentation

- `documentation/database/disputes-collection.md`
- `documentation/database/audit-logs-collection.md`
- `documentation/api/dispute-api.md`
- `documentation/api/admin-operations-api.md`
- `documentation/architecture/disputes-admin-operations-and-audit.md`
- `documentation/decisions/ADR-016-disputes-admin-operations-and-audit.md`
- `documentation/cursor/018_disputes_admin_operations_and_audit.md`

## Files Modified

- `README.md`
- `backend/README.md`
- `project/README.md`
- `backend/lib/src/database/collection_names.dart`
- `backend/lib/src/database/database_indexes.dart`
- `backend/lib/src/features/authorization/application/role_scoped_composition.dart`
- `backend/lib/src/features/authorization/http/role_http_errors.dart`
- `backend/lib/src/features/authorization/http/role_middleware.dart`
- `backend/lib/src/features/authorization/http/role_route_helpers.dart`
- `backend/lib/src/features/bookings/data/booking_repository.dart`
- `backend/lib/src/features/bookings/domain/booking_exceptions.dart`
- `backend/lib/src/features/bookings/domain/booking_validation.dart`
- `backend/lib/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart`
- `backend/lib/src/features/notifications/domain/notification_type.dart`
- `backend/lib/src/features/payments/application/admin_payment_service.dart`
- `backend/lib/src/features/payments/application/booking_cancellation_orchestrator.dart`
- `backend/lib/src/features/payments/data/payment_repository.dart`
- `backend/lib/src/features/reviews/application/admin_review_moderation_service.dart`
- `backend/lib/src/features/users/data/mongo_user_repository.dart`
- `backend/lib/src/features/users/data/user_document_store.dart`
- `backend/lib/src/features/users/data/user_indexes.dart`
- `backend/lib/src/features/users/data/user_repository.dart`
- `backend/lib/src/features/users/domain/user_account_exceptions.dart`
- `backend/routes/api/v1/admin/reviews/[reviewId]/unhide.dart`
- `backend/test/helpers/marketplace_test_fixtures.dart`
- `backend/test/routes/api/v1/admin/cleaners_test.dart`
- `backend/test/src/features/cleaner_profiles/application/admin_cleaner_review_service_test.dart`
- `backend/test/src/features/users/data/mongo_user_repository_test.dart`
- `backend/test/src/features/users/data/user_indexes_test.dart`
- `backend/tool/ensure_database_indexes.dart`
- `documentation/README.md`
- `documentation/api/README.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/architecture/booking-reservation-and-lifecycle.md`
- `documentation/architecture/chat-notifications-and-reviews.md`
- `documentation/architecture/flutter-client-architecture.md`
- `documentation/architecture/payment-processing-and-webhooks.md`
- `documentation/database/README.md`
- `documentation/decisions/README.md`
- `project/lib/app/router/app_router.dart`
- `project/lib/app/router/app_routes.dart`
- `project/lib/core/network/api_failure.dart`
- `project/lib/features/admin/presentation/admin_home_screen.dart`
- `project/lib/features/bookings/data/booking_models.dart`
- `project/lib/features/bookings/presentation/cleaner_booking_detail_screen.dart`
- `project/lib/features/bookings/presentation/customer_booking_detail_screen.dart`
- `project/lib/features/notifications/data/notification_models.dart`
- `project/lib/features/notifications/presentation/notification_center_screen.dart`
- `project/test/app/router/app_router_test.dart`
- `project/test/core/network/api_failure_test.dart`
- `project/test/features/admin/presentation/admin_screens_test.dart`
- `project/test/features/bookings/presentation/cleaner_booking_screens_test.dart`
- `project/test/features/bookings/presentation/customer_booking_screens_test.dart`
- `project/test/features/chat/presentation/booking_chat_screens_test.dart`
- `project/test/features/payments/presentation/customer_payment_screens_test.dart`
- `project/test/helpers/feature_test_fakes.dart`

## Files Deleted

None.

## Commands Executed

- `git rev-parse --show-toplevel` / `git branch --show-current` / `git status` / `git log`
- `git check-ignore -v backend/.env`
- `git diff --check`
- `dart pub get` (baseline; no upgrade)
- `dart format .` (backend)
- `dart analyze` (backend; clean)
- `dart test` (backend; 443 passed)
- `dart pub global run dart_frog_cli:dart_frog list`
- `dart run tool/ensure_database_indexes.dart`
- `dart pub global run dart_frog_cli:dart_frog build`
- production server `PORT=8098 dart build/bin/server.dart`, safe GETs, then stopped
- `dart format lib test` (Flutter)
- `flutter analyze` (clean)
- `flutter test` (324 passed)
- `flutter build apk --debug`

Did not run: `git add`, `git commit`, `git push`, `dart pub upgrade`, `flutter pub upgrade`, plain `dart_frog list`.

## Implementation Details

One `disputes` document per `booking_id` (`disputes_booking_unique`). Eligible booking statuses: confirmed, in_progress, completed, cancelled. Participant ids come from the booking. Embedded history is appended in the same conditional update as status.

Dispute statuses: open, under_review, resolved, closed. Admin review is open to under_review (idempotent if already under_review). Resolve from open or under_review. Close from resolved only.

Notifications: dispute_opened (other participant), dispute_under_review and dispute_resolved (both), dispute_closed. resource_type=dispute, resource_id=booking id. Best-effort.

Admin users: exact normalized email filter only. Suspend/deactivate revoke all refresh sessions via AuthSessionService. Admin targets and self-target: 403 protected_admin_account. Reasons in audit_logs only. Idempotent no-ops do not duplicate audit.

Admin booking cancel: pending/confirmed only. Confirmed uses BookingCancellationOrchestrator.cancelByAdmin (refund/cancel payment first). Refund failure leaves confirmed. History actor is admin. Notify both with "An administrator cancelled this booking."

Audit: append-only repository. AuditSink after successful primary action. Failure does not roll back. Also wired into cleaner approve/reject, review hide/unhide, payment refund request.

Flutter: focused Riverpod controllers, authenticated Dio, go_router role guards. Admin home entries: Disputes, Users, Bookings, Audit Log.

## Technical Decisions

- One dispute per booking rather than threads.
- Embedded history rather than a second collection.
- Admin cannot participant-create.
- Best-effort audit/notifications; primary write remains authoritative.
- Payment-aware admin cancel reuses TASK 016 orchestration.
- Keyset pagination only.

## Verification Performed

Backend analyze/test/routes; Flutter analyze/test/APK; controlled index ensure; safe live GET / /health /ready /services on production build port 8098; security review against TASK 018 checklist; git ignore of backend/.env.

## Verification Results

- Backend `dart analyze`: no issues
- Backend `dart test`: 443 passed
- Dart Frog route list includes participant dispute routes and admin disputes/users/bookings/audit-logs
- Flutter `flutter analyze`: no issues
- Flutter `flutter test`: 324 passed
- `flutter build apk --debug`: success (`project/build/app/outputs/flutter-apk/app-debug.apk`, untracked)
- Index ensure: TASK 018 indexes exist (disputes_*, audit_logs_*, users_role_status_id_desc)
- Live GET: 200 for `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services`
- `git check-ignore -v backend/.env` -> `.gitignore:8:.env`

## Errors / Warnings

- Direct `dart_frog` is not on PATH. Use `dart pub global run dart_frog_cli:dart_frog list`.
- Non-TTY `dart_frog dev` StdinException remains; production-build fallback on port 8098 used for safe GETs.
- `git diff --check` reports LF/CRLF working-copy warnings on Windows; no conflict-marker or trailing-whitespace errors.

## Security / Secrets Check

No secrets committed. `backend/.env` ignored. No passwords, JWTs, refresh tokens, Mongo URI, webhook secrets, or live account/dispute/audit records in docs or tests. Flutter has no new secrets. Audit metadata sanitizes to safe scalars.

## Git Diff Summary

Uncommitted TASK 018 implementation across backend disputes/audit/admin operations, Flutter UIs/controllers/tests, and documentation. No APK, build directory, `.env`, or `devtools_options.yaml` tracked.

## Final Repository State

Branch `main`, dirty working tree, unstaged, uncommitted. Ready for ChatGPT review. TASK 019 not started.

## Unresolved Issues

None blocking TASK 018. Deferred: appeals, evidence uploads, admin chat access, legal workflow, chargebacks, fraud detection, AI moderation, transactional outbox, SIEM export, audit retention, admin role hierarchy, payouts, password recovery, MFA.

## Suggested Next Step

ChatGPT review of uncommitted TASK 018. Do not begin TASK 019 from this report.

## Checkpoint

TASK 017 commit `a034243` on clean `main` before implementation.

## Baselines

Backend 416 tests / analyze clean. Flutter 302 tests / analyze clean. No new direct dependencies.

## Dispute schema / categories / lifecycle / history / authorization / notifications

Documented in `documentation/database/disputes-collection.md` and `documentation/api/dispute-api.md`. Categories are enum-only. History is embedded. Notifications are best-effort with explicit NotificationType values.

## Admin dispute queue / user moderation / session revocation / admin protection / booking operations / payment-aware cancellation

Documented in `documentation/api/admin-operations-api.md` and ADR-016.

## Audit schema / actions / append-only / consistency limitation / existing admin-action integration

Documented in `documentation/database/audit-logs-collection.md`. Actions are an explicit enum. Audit is best-effort after primary success.

## Indexes / live index ensure

Live Atlas mutated only via `dart run tool/ensure_database_indexes.dart`. Verified disputes_booking_unique (unique), disputes_status_id_desc, disputes_customer_id_desc, disputes_cleaner_id_desc, disputes_category_status_id_desc, users_role_status_id_desc, audit_logs_actor_id_desc, audit_logs_action_id_desc, audit_logs_target_id_desc, audit_logs_created_at.

## Backend routes / tests

See dart_frog list in the TASK 018 RESULT response. Backend tests 443 passed including dispute, admin user, admin booking, audit, existing-action audit, and HTTP route coverage, plus regression of TASK 012-017 suites.

## Flutter APIs/controllers/UX/tests/APK

Participant dispute create/status/history/close. Admin disputes/users/bookings/audit UIs. Route guards. 324 tests. Debug APK succeeded and is untracked.

## Safe live verification / security / live data safety / Git status

Safe GETs only. No live disputes, users, bookings, or audit writes. Indexes only. Uncommitted, unstaged.
