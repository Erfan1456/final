# Cursor Task 016 — Payment Ledger, Sandbox Provider, Webhook Idempotency, Refund Foundation, and Admin Transaction Management

## Metadata

- Task ID: 016
- Task title: Payment Ledger, Sandbox Provider, Webhook Idempotency, Refund Foundation, and Admin Transaction Management
- Date: 2026-08-25
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Add a senior-level payment architecture without claiming a production external processor is configured: payments ledger, payment-attempt lifecycle, provider-neutral sandbox adapter (development/test only), signed webhooks with replay protection, payment-command idempotency, quote-derived amounts, refund foundation, payment-aware confirmed-booking cancellation, admin transaction inspection, customer/admin Flutter UX, tests, indexes, and documentation. Do not integrate Stripe/SSLCommerz/PayPal/bKash, card collection, payouts, tax, coupons, chat, reviews, disputes, or notifications. Do not commit.

## Exact Cursor Prompt

~~~~text
# TASK 016 — Payment Ledger, Sandbox Provider, Webhook Idempotency, Refund Foundation, and Admin Transaction Management

Repository:

D:\freelance\erfankhan_cse489\final

TASK 015 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

TASK 015 established:

- immutable booking quotation snapshots;
- booking lifecycle;
- customer/cleaner ownership;
- booking idempotency;
- reservation concurrency;
- customer/cleaner booking UI.

TASK 016 must add a senior-level PAYMENT architecture without falsely claiming
that a production external payment processor has been configured.

Implement:

BACKEND
- payments collection;
- payment-attempt lifecycle;
- provider-neutral payment boundary;
- DEVELOPMENT-ONLY sandbox payment provider;
- payment initialization;
- payment status;
- provider callback/webhook processing;
- webhook authenticity;
- webhook replay/idempotency protection;
- payment-command idempotency;
- amount/currency integrity;
- booking/payment state compatibility;
- failure/retry;
- refund foundation;
- transaction/audit visibility;
- admin payment inspection.

CUSTOMER FLUTTER
- payment status on eligible bookings;
- Start Payment;
- sandbox payment screen in development builds only;
- successful/failed payment UX;
- retry payment;
- payment transaction detail.

ADMIN FLUTTER
- payment transaction list;
- filters;
- transaction detail;
- refund action when eligible;
- audit information.

CROSS-CUTTING
- tests;
- documentation;
- indexes;
- security review;
- no real external payment provider;
- no live real-money transaction.

Do NOT implement:

- Stripe;
- SSLCommerz;
- PayPal;
- bKash;
- card-number collection;
- PCI card storage;
- cleaner payouts;
- tax;
- coupons;
- promotions;
- chat;
- reviews;
- disputes;
- notifications.

A real external provider can later implement the PaymentProvider interface
without replacing the core payment domain.

======================================================================
IMPORTANT PRODUCT HONESTY
======================================================================

TASK 016 must NEVER claim:

"real card payment"
"Stripe payment"
"production payment processor"
"real money charged"

unless a real external provider is later integrated.

The sandbox provider exists only to exercise:

- payment state machines;
- webhook flow;
- idempotency;
- retries;
- refunds;
- client UI;
- admin transaction operations.

Production mode must NOT silently fall back to the sandbox provider.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct package

FLUTTER:
no new direct package

Reuse:

Dart SDK:
- dart:convert
- dart:io
- dart:math

Existing backend:
- hashlib
- Dart Frog
- mongo_dart

Existing Flutter:
- Dio
- Riverpod
- go_router

If a genuinely required new direct package appears:

STOP before adding it and report the blocker.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 015 checkpoint:

Backend:

dart analyze:
clean

dart test:
348 passed

Flutter:

flutter analyze:
clean

flutter test:
214 passed

Verify these exact baselines first.

======================================================================
PAYMENT COLLECTION
======================================================================

Create:

payments

Document:

{
  "_id": ObjectId,

  "booking_id": ObjectId,
  "customer_user_id": ObjectId,
  "cleaner_user_id": ObjectId,

  "provider": String,

  "status": String,

  "amount_minor": int,
  "currency_code": String,

  "provider_payment_id": String?,
  "provider_reference": String?,

  "attempt_number": int,

  "client_idempotency_key": String,
  "request_fingerprint": String,

  "failure_code": String?,
  "failure_message": String?,

  "authorized_at": DateTime?,
  "paid_at": DateTime?,
  "failed_at": DateTime?,
  "cancelled_at": DateTime?,
  "refunded_at": DateTime?,

  "refunded_amount_minor": int,

  "created_at": DateTime,
  "updated_at": DateTime
}

All timestamps:

UTC.

Do NOT store:

card number
CVV
expiry
bank password
mobile-wallet PIN
JWT
refresh token
Mongo URI
ACCESS_TOKEN_SECRET
raw provider secret
raw webhook secret.

======================================================================
PAYMENT STATUS ENUM
======================================================================

Create:

PaymentStatus

Wire values:

pending
authorized
paid
failed
cancelled
partially_refunded
refunded

No raw status strings scattered through services.

======================================================================
CURRENT TASK 016 PAYMENT MODEL
======================================================================

A booking may have multiple historical payment ATTEMPTS.

Only ONE non-terminal payment attempt may be active for a booking at a time.

Terminal:

paid
failed
cancelled
refunded

partially_refunded is still tied to the successful paid transaction but should
not allow another full payment.

For TASK 016:

one successful paid payment per booking.

No split-tender.

No multiple currencies per booking.

======================================================================
BOOKING ELIGIBILITY FOR PAYMENT
======================================================================

Customer may initiate payment only when booking status is:

confirmed

Do NOT allow payment when:

pending
declined
cancelled
in_progress
completed

for this initial flow.

Reason:

cleaner must accept the job before customer pays.

Later policy may support authorization earlier.

If incompatible:

409
booking_not_payable

======================================================================
PAYMENT AMOUNT AUTHORITY
======================================================================

NEVER accept amount from Flutter.

Payment amount comes ONLY from booking:

quoted_total_minor
currency_code

Therefore:

payments.amount_minor
=
booking.quoted_total_minor

payments.currency_code
=
booking.currency_code

Request body must not provide:

amount
currency
cleaner
customer
booking status.

Backend derives them.

======================================================================
PROVIDER ABSTRACTION
======================================================================

Create a narrow interface:

PaymentProvider

Conceptual responsibilities:

createPayment(...)
parseAndVerifyWebhook(...)
refund(...)

Provider result models must not expose raw vendor responses into application
services.

Do not couple PaymentService directly to the development sandbox.

======================================================================
PAYMENT PROVIDER ENUM
======================================================================

Create:

PaymentProviderType

TASK 016 allowed wire value:

sandbox

only.

Keep enum extensible.

Do NOT create fake enum names for providers not implemented.

======================================================================
SANDBOX PROVIDER
======================================================================

Create:

SandboxPaymentProvider

It is allowed ONLY when:

APP_ENV == development
OR
APP_ENV == test

Production:

sandbox initialization must fail safely:

503
payment_provider_unavailable

Never auto-enable sandbox in production.

======================================================================
SANDBOX PAYMENT FLOW
======================================================================

Sandbox provider emulates an asynchronous external processor.

When payment begins:

provider creates an opaque provider_payment_id.

Suggested:

sandbox_<secure-random-base64url>

Do not use sequential IDs.

Initial provider/payment status:

pending

Flutter receives a safe sandbox payment session representation.

The client does NOT directly alter the Mongo payment status.

======================================================================
DEVELOPMENT SANDBOX COMPLETION API
======================================================================

Because there is no external processor, implement DEV-ONLY sandbox simulator:

POST /api/v1/dev/payments/[paymentId]/simulate

Only available when:

APP_ENV == development

In test:
route may be exercised with injected config.

In production:
return 404 or otherwise do not expose operational sandbox simulation.

Body:

{
  "result": "success"
}

or

{
  "result": "failure"
}

This endpoint must NOT directly perform PaymentRepository status mutation.

Instead it must generate a signed sandbox webhook payload and feed it through
the SAME webhook verification/processing application path used by external
provider callbacks.

This is critical.

Do not create a second fake status-update shortcut.

======================================================================
SANDBOX WEBHOOK SECRET
======================================================================

Add backend config:

SANDBOX_PAYMENT_WEBHOOK_SECRET

Backend only.

Minimum:

32 UTF-8 bytes.

Add placeholder to:

backend/.env.example

Never value.

Do NOT place in Flutter.

Do NOT print value.

Do NOT require the developer to paste it into ChatGPT.

Tests use fake secrets.

If absent in local development:

payment sandbox runtime may report unavailable.

The rest of the app/server must still boot.

======================================================================
WEBHOOK SIGNATURE
======================================================================

Use HMAC-SHA256.

Header:

X-Sandbox-Signature

Signature input:

exact raw HTTP request body bytes/text as received.

Expected signature:

lowercase hexadecimal HMAC-SHA256.

Use constant-time comparison.

If existing hashlib has an HMAC facility:
use it.

Otherwise use a correct SDK/existing-package implementation.

Do NOT invent cryptography.

Do NOT compare secrets/signatures with naive timing-sensitive equality when a
constant-time helper can be implemented.

======================================================================
WEBHOOK ROUTE
======================================================================

Add:

POST /api/v1/payments/webhooks/sandbox

This webhook route is NOT authenticated by customer JWT.

It is authenticated by:

HMAC webhook signature.

Reject:

missing signature
invalid signature
malformed body
unknown event

without exposing secret details.

Invalid signature:

401
invalid_webhook_signature

======================================================================
SANDBOX WEBHOOK EVENT
======================================================================

Canonical payload conceptually:

{
  "event_id": "...",
  "event_type": "payment.succeeded",
  "provider_payment_id": "...",
  "amount_minor": 500000,
  "currency_code": "BDT",
  "created_at": "..."
}

Failure:

event_type:
payment.failed

Refund:

payment.refunded

Partial refund if supported:
payment.partially_refunded

Keep payload intentionally provider-like.

======================================================================
PAYMENT WEBHOOK EVENTS COLLECTION
======================================================================

Create:

payment_webhook_events

Document:

{
  "_id": ObjectId,
  "provider": String,
  "provider_event_id": String,
  "event_type": String,
  "provider_payment_id": String,
  "payload_sha256": String,
  "processing_status": String,
  "processed_at": DateTime?,
  "created_at": DateTime
}

Do NOT persist:

raw signature secret.

Do not need to persist the entire raw webhook payload.

Store hash and approved identifiers/metadata.

======================================================================
WEBHOOK EVENT IDEMPOTENCY
======================================================================

Unique:

provider + provider_event_id

If same event delivered repeatedly:

must not apply payment transition twice.

Return safe 200 acknowledgement for already processed identical event.

If same provider_event_id arrives with DIFFERENT payload hash:

409
webhook_event_conflict

This detects inconsistent replay.

Correctness must rely on DB unique index.

Not merely a pre-read.

======================================================================
WEBHOOK PROCESSING STATUS
======================================================================

Use enum:

received
processed
ignored
failed

or similarly explicit model.

For valid duplicate already-processed event:

acknowledge safely.

Do not create multiple payment transitions.

======================================================================
PAYMENT STATE CHANGES FROM WEBHOOK
======================================================================

payment.succeeded:

pending/authorized
→ paid

Set:

paid_at
failure fields null

payment.failed:

pending/authorized
→ failed

Set:

failed_at
safe provider failure code/message if available.

payment.refunded:

paid/partially_refunded
→ refunded

Set:

refunded_amount_minor = amount_minor
refunded_at

payment.partially_refunded:

paid/partially_refunded
→ partially_refunded

Update cumulative refunded amount.

Never transition:

failed → paid

from an unrelated stale attempt.

Webhook must resolve payment by:

provider
provider_payment_id

and verify amount/currency match expected values where event type contains
them.

Mismatch:

409
payment_integrity_mismatch

Do NOT update payment.

======================================================================
PAYMENT INITIALIZATION IDEMPOTENCY
======================================================================

Customer payment-start request requires:

Idempotency-Key

Use same validation rules as booking:

16–128 ASCII
trim
control-safe
do not lowercase.

Create fingerprint from:

customer_user_id
booking_id

No amount input exists.

Unique index:

payments_customer_idempotency_unique

key:

customer_user_id: 1
client_idempotency_key: 1

unique:
true

Same key + same fingerprint:

return existing payment attempt.

Same key + different booking:

409
idempotency_key_reused

Race:

unique index + load/compare.

======================================================================
ACTIVE PAYMENT UNIQUENESS
======================================================================

Create:

payments_booking_active_unique

Partial unique index:

booking_id: 1

where status in:

pending
authorized

This prevents two concurrently active charge attempts for one booking.

If Mongo partial filter using `$in` is supported in partial indexes by the
deployed Atlas version, use it.

If partialFilterExpression restrictions prevent this exact `$in` shape:

represent active state explicitly with:

payment_active: bool

and use:

partial payment_active == true

If using payment_active:

document it and update atomically with status.

Do NOT silently drop active-payment uniqueness.

Choose the cleanest verified Mongo-compatible design.

======================================================================
SUCCESSFUL PAYMENT UNIQUENESS
======================================================================

Also guarantee no second successful payment after one is already:

paid
partially_refunded
refunded

Application service must check historical successful payment.

Consider a durable field:

settlement_recorded: bool

or deliberate unique strategy if useful.

Do not create unnecessary complexity if repository-level conditional logic plus
a booking-level paid marker is cleaner.

Preferred TASK 016 approach:

add to booking:

payment_status_summary

Allowed:

unpaid
pending
paid
partially_refunded
refunded

and:

payment_id: ObjectId?

Update this through payment processing.

However:

booking business lifecycle and payment document must not become impossible to
reconcile if one write succeeds and the second fails.

Therefore inspect whether Mongo transactions are available/practical.

Do NOT blindly add a cross-document transaction.

If no transaction architecture exists:

treat Payment as source of truth;
booking summary is optional cache only.

It is acceptable to OMIT booking payment cache in TASK 016.

Flutter may query booking-associated payment separately.

Document decision.

======================================================================
PAYMENT SOURCE OF TRUTH
======================================================================

Unless an actual transaction strategy is implemented:

payments collection is authoritative payment state.

Do NOT claim booking status itself proves payment.

Booking:

confirmed

does not mean paid.

Booking:

completed

does not inherently mean paid unless payment record says so.

======================================================================
PAYMENT ATTEMPT RETRY
======================================================================

Customer may retry after:

failed
cancelled

provided:

booking still confirmed

and there is no:

pending
authorized
paid
partially_refunded
refunded

payment that blocks retry.

A retry creates a new Payment document with:

attempt_number
=
previous max + 1

New Idempotency-Key required for a new logical retry.

======================================================================
PAYMENT CANCELLATION
======================================================================

Customer may cancel a pending sandbox payment attempt before it succeeds.

POST:

/api/v1/customer/bookings/[bookingId]/payment/cancel

Conditional:

payment belongs to customer booking
status == pending

Set:

cancelled
payment_active false if that field is used
cancelled_at

This is local/provider cancellation orchestration.

Sandbox provider may implement cancel as immediate local cancellation.

Do not cancel the BOOKING.

Booking remains confirmed.

======================================================================
BOOKING CANCELLATION INTEGRATION
======================================================================

When customer/cleaner attempts to cancel a CONFIRMED booking:

If payment is:

pending
authorized

booking cancellation must first ensure payment attempt is safely cancelled.

If payment is:

paid
partially_refunded

TASK 016 policy:

booking cancellation requires refund.

Do not silently cancel a paid booking without payment compensation.

Implement coordinated cancellation orchestration:

paid booking cancellation
→ initiate sandbox refund
→ process refund through sandbox webhook path
→ after payment reaches refunded
→ booking cancellation may complete

Since asynchronous real-provider orchestration does not exist yet, for TASK 016
the sandbox provider can synchronously produce/dispatch the refund webhook via
the shared webhook processing path.

If refund fails:

booking remains confirmed.

Return safe:

409
refund_required

or:

payment_refund_failed

Choose clear domain semantics and document.

Do NOT mark booking cancelled first and hope refund succeeds later.

======================================================================
CUSTOMER PAYMENT API
======================================================================

Add:

GET /api/v1/customer/bookings/[bookingId]/payment

POST /api/v1/customer/bookings/[bookingId]/payment

POST /api/v1/customer/bookings/[bookingId]/payment/cancel

Customer role only.

GET:

payment summary/history for own booking.

POST:

requires Idempotency-Key.

Starts or idempotently returns payment.

First attempt:

201

Identical replay:

200

Retry after terminal failed/cancelled with new key:

201

======================================================================
PAYMENT RESPONSE
======================================================================

Safe fields:

id
booking_id
provider
status
amount_minor
currency_code
attempt_number
created_at
updated_at
paid_at
failed_at
cancelled_at
refunded_at
refunded_amount_minor

Sandbox development response may additionally include:

sandbox_session:
{
  "payment_id": "...",
  "simulation_available": true
}

Do NOT include:

client_idempotency_key
request_fingerprint
webhook secret
signature
raw provider response
internal failure stack.

======================================================================
CUSTOMER PAYMENT HISTORY
======================================================================

GET may return:

{
  "current": ... | null,
  "attempts": [...]
}

Sort:

attempt_number descending.

Maximum attempts naturally expected small.

No pagination needed yet unless implementation prefers it.

======================================================================
ADMIN PAYMENT API
======================================================================

Add:

GET /api/v1/admin/payments

GET /api/v1/admin/payments/[paymentId]

POST /api/v1/admin/payments/[paymentId]/refund

Admin role only.

======================================================================
ADMIN PAYMENT LIST
======================================================================

Filters:

status
provider
currency
booking_id
customer_user_id
limit
after

limit:

default 20
1–50

Cursor:

payment _id descending

No offset pagination.

Return safe transaction metadata.

Do not expose:

passwords
tokens
raw provider responses
webhook secret
idempotency key
fingerprint.

======================================================================
ADMIN PAYMENT DETAIL
======================================================================

May include:

payment safe data
booking id
customer id
cleaner id
service snapshot name
booking status
webhook event summaries
failure metadata
refund metadata

Do not expose:

private account security data.

======================================================================
ADMIN REFUND
======================================================================

Admin refund input:

{
  "amount_minor": integer | null,
  "reason": "..."
}

For TASK 016:

support full refund
and optional partial refund.

Reason:

required
5–500 Unicode code points
plain text
trimmed
no controls.

If amount omitted:

remaining refundable amount.

Validate:

1 <= refund amount <= amount_minor - refunded_amount_minor

Only:

paid
partially_refunded

may refund.

Use provider refund interface.

Sandbox refund must route through signed webhook processing.

Do not directly mark refunded from HTTP handler.

======================================================================
REFUND IDEMPOTENCY
======================================================================

Admin refund request requires:

Idempotency-Key

Create a collection:

payment_refund_requests

Document:

{
  "_id": ObjectId,
  "payment_id": ObjectId,
  "admin_user_id": ObjectId,
  "idempotency_key": String,
  "amount_minor": int,
  "reason": String,
  "request_fingerprint": String,
  "status": String,
  "created_at": DateTime,
  "updated_at": DateTime
}

Unique:

admin_user_id + idempotency_key

Same key + same fingerprint:

return existing result.

Different intent:

409 idempotency_key_reused.

Do not issue provider refund twice after network retry.

======================================================================
REFUND STATUS
======================================================================

RefundRequestStatus:

pending
succeeded
failed

Provider webhook determines final payment refund state.

Sandbox provider may complete immediately through its webhook path.

======================================================================
WEBHOOK OUT-OF-ORDER HANDLING
======================================================================

Webhooks may arrive late/repeated/out of order.

Handle safely.

Examples:

payment.failed arrives after paid:
ignore as stale/invalid state;
do NOT downgrade paid.

payment.succeeded twice:
second is idempotent/no-op.

refund event twice:
same provider event is idempotent.

unknown payment:
record safe event as ignored if appropriate;
do not expose sensitive details.

Document state-machine rules.

======================================================================
WEBHOOK AUDIT
======================================================================

Add:

GET /api/v1/admin/payments/[paymentId]/events

Admin only.

Return approved metadata:

provider_event_id
event_type
processing_status
processed_at
created_at

Do NOT return:

raw signature
secret
full raw payload.

======================================================================
PAYMENT INDEXES
======================================================================

Create deliberate indexes.

payments:

1.
payments_provider_payment_id_unique

provider: 1
provider_payment_id: 1

unique:
true

Partial if provider_payment_id can be null so null rows do not collide.

2.
payments_customer_idempotency_unique

customer_user_id: 1
client_idempotency_key: 1

unique:
true

3.
payments_booking_attempt_unique

booking_id: 1
attempt_number: 1

unique:
true

4.
payments_booking_id_desc

booking_id: 1
_id: -1

5.
payments_customer_id_desc

customer_user_id: 1
_id: -1

6.
payments_status_id_desc

status: 1
_id: -1

7.
active-payment uniqueness index according to the selected compatible strategy.

payment_webhook_events:

1.
payment_webhook_events_provider_event_unique

provider: 1
provider_event_id: 1

unique:
true

2.
payment_webhook_events_payment_created

provider_payment_id: 1
created_at: 1

payment_refund_requests:

1.
payment_refund_admin_idempotency_unique

admin_user_id: 1
idempotency_key: 1

unique:
true

2.
payment_refund_payment_created

payment_id: 1
created_at: -1

Evaluate redundancy.

Do not create pointless duplicate indexes.

======================================================================
LIVE DATABASE POLICY
======================================================================

TASK 016 may mutate live Atlas ONLY through:

controlled index ensure.

Do NOT create live:

payments
payment_webhook_events
refund requests
bookings
customers
cleaners
sessions
availability

Do NOT run sandbox payment simulation against real Atlas application data.

All payment lifecycle tests use fakes/in-memory stores.

======================================================================
PAYMENT REPOSITORY
======================================================================

Create narrow:

PaymentRepository

Responsibilities conceptually:

findById
findForCustomerBooking
listForBooking
findByCustomerIdempotency
findByProviderPaymentId
findActiveForBooking
findSuccessfulForBooking
nextAttemptNumber
create
cancelPending
markPaidFromWebhook
markFailedFromWebhook
applyRefundFromWebhook
adminPage

Conditional state selectors mandatory.

No arbitrary update maps in application services.

======================================================================
WEBHOOK EVENT REPOSITORY
======================================================================

Create:

PaymentWebhookEventRepository

Responsibilities:

findByProviderEventId
createReceived
markProcessed
markIgnored
markFailed
listForPayment/providerPaymentId

Duplicate unique event mapping must be explicit.

======================================================================
REFUND REQUEST REPOSITORY
======================================================================

Create narrow:

PaymentRefundRequestRepository

with idempotent creation and status transitions.

======================================================================
PAYMENT APPLICATION SERVICE
======================================================================

Create HTTP-independent:

CustomerPaymentService

Responsibilities:

getPayment
startPayment
cancelPayment

It receives current authenticated customer.

Checks booking ownership and payability.

Uses booking immutable quote.

======================================================================
WEBHOOK APPLICATION SERVICE
======================================================================

Create:

PaymentWebhookService

Responsibilities:

verify provider webhook
parse
hash payload
enforce event idempotency
resolve payment
verify amount/currency
apply valid conditional transition
mark event processed/ignored/failed

HTTP route must stay thin.

======================================================================
ADMIN PAYMENT SERVICE
======================================================================

Create:

AdminPaymentService

Responsibilities:

list
detail
events
refund

Persisted admin authorization remains middleware responsibility.

======================================================================
BOOKING CANCELLATION ORCHESTRATOR
======================================================================

Do NOT bury payment-aware cancellation logic inside HTTP handlers.

Create a service/orchestrator that coordinates:

booking cancellation request
+
current payment state
+
payment cancellation/refund when required
+
existing conditional booking cancellation.

Reuse for:

customer confirmed-booking cancellation
cleaner confirmed-booking cancellation

Preserve TASK 015 ownership/reason policies.

Pending booking has no payment because payment starts only after confirmed.

======================================================================
ERROR CODES
======================================================================

Add safe errors as needed:

payment_not_found
booking_not_payable
payment_already_active
payment_already_paid
payment_provider_unavailable
invalid_webhook_signature
webhook_event_conflict
payment_integrity_mismatch
invalid_payment_state
payment_refund_failed
invalid_refund_amount
invalid_refund_reason

Use appropriate:

400
401
404
409
503

No raw Mongo/provider errors.

======================================================================
BACKEND TESTS — PAYMENT DOMAIN
======================================================================

Test:

status wire values
provider enum
safe serialization
amount/currency derived from booking
no card/security fields
active-state behavior
refund remaining calculation

======================================================================
BACKEND TESTS — PAYMENT INITIALIZATION
======================================================================

Test:

confirmed booking starts payment
pending booking blocked
cancelled booking blocked
completed booking blocked
foreign booking hidden
amount from quote
currency from quote
request cannot override amount
first attempt number 1
retry increments
same idempotency replay
idempotency conflict
duplicate race
active-payment conflict
already-paid conflict
provider unavailable in production
sandbox allowed development/test

No Atlas.

======================================================================
BACKEND TESTS — WEBHOOK
======================================================================

Mandatory:

valid signature
missing signature
invalid signature
constant-time verification helper
success event → paid
failed event → failed
amount mismatch rejected
currency mismatch rejected
duplicate event idempotent
same event id / different payload conflict
stale failure after paid cannot downgrade
unknown payment handled safely
event status persisted
raw signature not persisted

======================================================================
BACKEND TESTS — REFUND
======================================================================

Test:

full refund
partial refund
second partial refund
too-large amount
zero/negative amount
invalid payment status
reason validation
refund idempotent replay
refund idempotency conflict
provider refund invoked once
webhook drives payment state
duplicate refund webhook harmless

======================================================================
BACKEND TESTS — CANCELLATION INTEGRATION
======================================================================

Test:

confirmed unpaid booking cancels normally

pending payment:
payment cancelled first
booking cancellation succeeds

paid payment:
refund succeeds then booking cancellation succeeds

paid payment:
refund fails → booking remains confirmed

partially-refunded:
remaining refund required

customer ownership unchanged

cleaner ownership unchanged

no payment:
TASK 015 cancellation behavior remains.

======================================================================
BACKEND TESTS — ADMIN
======================================================================

Test:

customer cannot admin list/refund
cleaner cannot admin list/refund
admin allowed
list pagination/filter
detail
events
refund
safe serialization
no idempotency/fingerprint/secrets exposed

======================================================================
FLUTTER ENVIRONMENT / DEVELOPMENT POLICY
======================================================================

Flutter must NOT contain:

SANDBOX_PAYMENT_WEBHOOK_SECRET

Flutter may know from API response:

provider == sandbox
simulation_available == true

Only display sandbox controls in a DEVELOPMENT-capable API response.

Do not infer production/dev solely from a hard-coded Flutter flag if backend
already states simulation availability.

======================================================================
FLUTTER PAYMENT MODELS
======================================================================

Create:

PaymentStatus
PaymentProviderType
PaymentSummary
PaymentAttempt
PaymentHistory
AdminPaymentSummary
AdminPaymentDetail
PaymentWebhookEventSummary

Unknown enum values:

safe parsing failure / controlled unsupported state.

Do not crash app startup.

======================================================================
FLUTTER CUSTOMER PAYMENT API
======================================================================

Use authenticated Dio.

Operations:

getPayment
startPayment
cancelPayment

Start sends:

Idempotency-Key

One logical attempt retains same key through network/auth retry.

New explicit retry:

new key.

Reuse existing idempotency helper pattern from booking.

Do not create another auth stack.

======================================================================
FLUTTER SANDBOX API
======================================================================

Development-only API wrapper:

simulateSuccess
simulateFailure

It may exist in code because server authorization/environment decides access.

UI only displays these actions if:

simulation_available == true.

Label clearly:

Development Sandbox

Do NOT visually present sandbox as a real card processor.

======================================================================
CUSTOMER BOOKING DETAIL UPDATE
======================================================================

For confirmed booking add Payment section.

Possible states:

No payment:
Pay Now

Pending:
Payment Pending
Cancel Payment
sandbox controls if available

Paid:
Paid
amount/date

Failed:
Payment Failed
Retry Payment

Cancelled payment:
Retry Payment

Partially Refunded:
show paid amount/refunded amount

Refunded:
show refunded

Do NOT show card-entry fields.

======================================================================
PAYMENT SCREEN
======================================================================

Add:

/customer/bookings/:bookingId/payment

Create:

CustomerPaymentScreen

Display:

booking/service
quoted total
currency
provider
payment status
attempt number

Action:

Start Payment

After sandbox pending session:

Development Sandbox:
Simulate Success
Simulate Failure

Clearly label sandbox UI.

No card number.

No CVV.

No fake credit-card form.

======================================================================
BOOKING CANCELLATION UX
======================================================================

If cancellation requires refund:

UI may display:

"Your payment must be refunded before this booking can be cancelled."

Backend orchestrates authoritative sequence.

After successful sandbox refund and cancellation:

refresh booking + payment state.

Do not locally assume refund succeeded before backend confirms.

======================================================================
ADMIN PAYMENT ROUTES
======================================================================

Flutter:

/admin/payments
/admin/payments/:paymentId

Update AdminHomeScreen:

Payments

======================================================================
ADMIN PAYMENT LIST SCREEN
======================================================================

Show:

payment id short display
booking id
status
provider
amount
currency
attempt
created time

Filters:

status
provider
currency

Load More.

Do not show sensitive provider/internal values.

======================================================================
ADMIN PAYMENT DETAIL SCREEN
======================================================================

Show:

safe payment metadata
booking link/id
customer/cleaner IDs
status
amount
refund amount
timestamps
failure information
webhook event summaries

Eligible:

Refund

Refund dialog:

optional amount
reason

Generate secure client idempotency key and preserve across retry.

======================================================================
FLUTTER PAYMENT CONTROLLERS
======================================================================

Create:

CustomerPaymentController
AdminPaymentController

Keep payment state outside:

AuthController
BookingController

Coordinate refresh where needed through repositories/providers rather than
merging all feature state.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Map:

payment_not_found
booking_not_payable
payment_already_active
payment_already_paid
payment_provider_unavailable
payment_integrity_mismatch
invalid_payment_state
payment_refund_failed
invalid_refund_amount
invalid_refund_reason
webhook_event_conflict

Never show:

DioException.toString()
raw Mongo error
webhook secret
signature
stack trace.

======================================================================
FLUTTER TESTS — CUSTOMER PAYMENT
======================================================================

Models/API:

parse statuses
start sends Idempotency-Key
auth refresh preserves key
history
sandbox flag
safe errors

Controller:

load
start
duplicate-start guard
retry new key
cancel pending
sandbox success refresh
sandbox failure refresh
safe error

Widgets:

booking detail payment section
Pay Now
pending
paid
failed
retry
refunded
sandbox label
simulate success/failure only when available
no card/CVV UI

======================================================================
FLUTTER TESTS — ADMIN PAYMENT
======================================================================

Controller:

list
filters
pagination
detail
events
refund
refund idempotency
safe error

Widgets:

admin home Payments
list
filters
detail
events
refund dialog
amount/reason validation
loading states.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Customer:

can payment route for customer path.

Cleaner:
cannot.

Admin:
cannot customer payment path.

Admin payment routes:
admin allowed
customer/cleaner redirected to own home.

Auth expiry:
login.

Existing booking/discovery/profile/onboarding routes remain green.

======================================================================
LIVE SERVER VERIFICATION
======================================================================

Safe live routes only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Do NOT live-call:

payment start
sandbox simulate
webhook
refund
admin payments

against real Atlas.

Sandbox behavior is fully automated with fakes/test config.

======================================================================
DOCUMENTATION
======================================================================

Create:

documentation/database/payments-collection.md
documentation/database/payment-webhook-events-collection.md
documentation/database/payment-refund-requests-collection.md

documentation/api/payment-api.md

documentation/architecture/payment-processing-and-webhooks.md

documentation/decisions/ADR-014-payment-provider-webhooks-and-refunds.md

Document clearly:

- no production provider configured;
- sandbox is development/test only;
- payment collection is source of truth;
- booking immutable quote is amount authority;
- payment idempotency;
- webhook signature;
- webhook event idempotency;
- out-of-order events;
- active payment uniqueness;
- refund idempotency;
- cancellation/refund orchestration;
- Flutter sandbox UX;
- provider adapter future path;
- no PCI/card data.

======================================================================
ADR-014
======================================================================

Required:

# ADR-014 — Payment Provider Boundary, Webhooks, and Refunds

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision includes:

provider-neutral PaymentProvider
development sandbox provider
production sandbox prohibition
booking quote authority
Payment source of truth
payment attempts
idempotent initialization
signed webhooks
event replay protection
conditional payment states
refund requests
refund idempotency
payment-aware booking cancellation
admin transaction inspection

Alternatives:

### Trust Flutter payment-success response
Rejected.

### Let client provide amount
Rejected.

### Directly mutate payment from sandbox simulation route
Rejected; simulator must use webhook path.

### Store raw card data
Rejected.

### Mark booking paid without payment record
Rejected.

### Process duplicate webhook every time
Rejected.

### Refund after cancelling booking
Rejected because failed refund could leave financial inconsistency.

### Hard-code Stripe now
Not selected because provider/account requirements have not been chosen.

Deferred:

real gateway adapter
provider-specific SDK
3DS
PCI hosted elements
payouts
tax
fees
refund settlement latency
chargebacks
disputes
webhook delivery queues/retries
multi-currency conversion.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

Run:

git rev-parse --show-toplevel
git branch --show-current
git status
git status --short
git log -10 --oneline

Expected:

main
clean tree
latest TASK 015 checkpoint

Verify TASK 015 report Status SUCCESS.

Verify backend/.env ignored.

If tree not clean:

STOP.

======================================================================
STEP 2 — BASELINES

Backend:

dart pub get
dart analyze
dart test
dart_frog list

Expected:
348 tests

Flutter:

flutter pub get
flutter analyze
flutter test

Expected:
214 tests

If either fails:

STOP.

======================================================================
STEP 3 — DEPENDENCY AUDIT

Confirm no direct package required.

If required:

STOP before adding.

======================================================================
STEP 4 — PAYMENT DOMAIN / INDEXES

Implement:

payments
webhook events
refund requests
enums
validation
index specifications
safe DTOs.

Tests first/alongside implementation.

======================================================================
STEP 5 — PROVIDER ABSTRACTION / SANDBOX

Implement:

PaymentProvider
SandboxPaymentProvider
configuration
HMAC signing/verifying
provider results
production sandbox prohibition.

Add security tests.

======================================================================
STEP 6 — PAYMENT REPOSITORIES

Implement focused repositories.

Conditional state updates.

Duplicate-key mappings.

No Atlas tests.

======================================================================
STEP 7 — PAYMENT SERVICES

Implement:

CustomerPaymentService
PaymentWebhookService
AdminPaymentService
payment-aware booking cancellation orchestrator.

Comprehensive tests.

======================================================================
STEP 8 — BACKEND ROUTES

Implement customer payment routes.

Webhook route.

Development simulation route.

Admin payment/routes/events/refund.

Thin handlers.

======================================================================
STEP 9 — BOOKING INTEGRATION

Replace direct confirmed-booking cancellation path with payment-aware
orchestrator where applicable.

Preserve TASK 015 lifecycle/security behavior.

Add regressions.

======================================================================
STEP 10 — BACKEND PRE-LIVE VERIFICATION

dart format .
dart analyze
dart test
dart_frog list

All green before index ensure.

======================================================================
STEP 11 — LIVE INDEX ENSURE

Ensure approved payment/webhook/refund indexes.

Verify metadata including partial indexes.

No payment documents.

No webhook documents.

No refund documents.

======================================================================
STEP 12 — FLUTTER PAYMENT DATA / API

Implement models/APIs/idempotency.

Use authenticated Dio.

======================================================================
STEP 13 — FLUTTER STATE

Implement customer/admin payment controllers.

======================================================================
STEP 14 — CUSTOMER UI

Update booking detail.

Add payment screen.

Sandbox UI only when backend says simulation available.

======================================================================
STEP 15 — ADMIN UI

Payment list/detail/events/refund.

Update admin home.

======================================================================
STEP 16 — FLUTTER TESTS

Add comprehensive tests.

Run:

dart format lib test
flutter analyze
flutter test

Record count.

======================================================================
STEP 17 — ANDROID DEBUG BUILD

flutter build apk --debug

Must succeed.

======================================================================
STEP 18 — SAFE LIVE REGRESSION

Only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

No payment/live sandbox/admin transaction calls.

======================================================================
STEP 19 — SECURITY AUDIT

Confirm:

no client amount authority
no card data
sandbox forbidden production
webhook HMAC
constant-time signature compare
event idempotency
payment idempotency
refund idempotency
conditional payment states
payment-aware cancellation
no raw provider/Mongo errors
no secrets Flutter
no secret logs
.env ignored.

======================================================================
STEP 20 — DOCUMENTATION

Create all TASK 016 docs and update indexes.

======================================================================
STEP 21 — FINAL BACKEND VERIFICATION

dart analyze
dart test
dart_frog list

All green.

Record exact count/routes.

======================================================================
STEP 22 — FINAL FLUTTER VERIFICATION

flutter analyze
flutter test
flutter build apk --debug

All green.

Record count.

======================================================================
STEP 23 — FINAL GIT REVIEW

git status --short
git check-ignore -v backend/.env

Inspect diffs.

No:

.env
sandbox secret
JWT
password
APK
build
private Atlas data
unrelated feature

tracked.

======================================================================
STEP 24 — TASK REPORT

Create:

documentation/cursor/016_payment_ledger_webhooks_and_admin_transactions.md

Use existing task-report template.

Include COMPLETE EXACT TASK 016 prompt under:

## Exact Cursor Prompt

Document:

checkpoint
baselines
dependencies
schema
payment states
provider abstraction
sandbox restriction
HMAC
webhook format
event idempotency
payment idempotency
active-payment uniqueness
amount authority
attempt retry
refunds
refund idempotency
out-of-order events
booking cancellation orchestration
repositories/services
customer APIs
webhook API
dev simulation API
admin APIs
indexes + metadata
Flutter models/APIs
controllers
customer payment UX
sandbox UX
admin UX
backend tests
Flutter tests
APK
safe live GETs
security
live data safety
files
warnings
Git status.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET value
password
JWT
refresh token
card data
real payment credentials
private Atlas records.

======================================================================
STEP 25 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 016 uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 016 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## Payment Model

## Payment Amount Authority

## Payment Provider Boundary

## Sandbox Provider

## Webhook Authentication

## Webhook Idempotency

## Payment Idempotency

## Payment Retry

## Refund Foundation

## Booking Cancellation Integration

## MongoDB Indexes

## Customer Payment API

## Admin Payment API

## Development Simulation API

## Backend Tests

## Backend Routes

## Flutter Customer Payment Experience

## Flutter Admin Payment Experience

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

State whether payment ledger + sandbox provider + secure webhook processing +
refund foundation + admin transaction management are complete and ready for
ChatGPT review.

Do NOT integrate a real payment provider.

Do NOT implement payouts.

Do NOT implement chat.

Do NOT implement reviews.

Do NOT begin TASK 017.

Start TASK 016 now.
~~~~

## Pre-Task Repository State

- `git rev-parse --show-toplevel`: `D:/freelance/erfankhan_cse489/final`
- Branch: `main`
- Working tree: clean
- HEAD: `f960ae1` TASK 015 checkpoint (`ooking_reservation_and_lifecycle`)
- TASK 015 report Status: SUCCESS
- `backend/.env` gitignored (`.gitignore:8:.env`)
- No new direct packages required or added

Baselines before TASK 016:

- Backend `dart analyze`: No issues found
- Backend `dart test`: **348 passed**
- Flutter `flutter analyze`: No issues found
- Flutter `flutter test`: **214 passed**

## Work Performed

Implemented the payment domain (`payments`, `payment_webhook_events`, `payment_refund_requests`), `PaymentProvider` / `SandboxPaymentProvider`, HMAC-SHA256 webhook authenticity, customer/admin/webhook/dev-simulate HTTP routes, `BookingCancellationOrchestrator`, Flutter customer and admin payment surfaces, indexes (live ensure of metadata only), tests, and documentation including ADR-014.

Payments are the source of truth. Booking payment cache and Mongo multi-document transactions were omitted. Amounts come only from the booking quote. Sandbox is forbidden in production. Sandbox simulate and refunds always dispatch a signed webhook through `PaymentWebhookService`; they never mutate payment status from the HTTP handler.

## Files Created

### Backend domain / application / data / provider / security

- `backend/lib/src/features/payments/domain/payment.dart`
- `backend/lib/src/features/payments/domain/payment_status.dart`
- `backend/lib/src/features/payments/domain/payment_provider_type.dart`
- `backend/lib/src/features/payments/domain/payment_exceptions.dart`
- `backend/lib/src/features/payments/domain/payment_validation.dart`
- `backend/lib/src/features/payments/domain/payment_webhook_event.dart`
- `backend/lib/src/features/payments/domain/payment_webhook_event_type.dart`
- `backend/lib/src/features/payments/domain/payment_webhook_processing_status.dart`
- `backend/lib/src/features/payments/domain/payment_refund_request.dart`
- `backend/lib/src/features/payments/domain/refund_request_status.dart`
- `backend/lib/src/features/payments/data/payment_indexes.dart`
- `backend/lib/src/features/payments/data/payment_repository.dart`
- `backend/lib/src/features/payments/data/payment_webhook_event_indexes.dart`
- `backend/lib/src/features/payments/data/payment_webhook_event_repository.dart`
- `backend/lib/src/features/payments/data/payment_refund_request_indexes.dart`
- `backend/lib/src/features/payments/data/payment_refund_request_repository.dart`
- `backend/lib/src/features/payments/provider/payment_provider.dart`
- `backend/lib/src/features/payments/provider/sandbox_payment_provider.dart`
- `backend/lib/src/features/payments/provider/payment_provider_resolver.dart`
- `backend/lib/src/features/payments/security/sandbox_webhook_hmac.dart`
- `backend/lib/src/features/payments/application/customer_payment_service.dart`
- `backend/lib/src/features/payments/application/payment_webhook_service.dart`
- `backend/lib/src/features/payments/application/admin_payment_service.dart`
- `backend/lib/src/features/payments/application/booking_cancellation_orchestrator.dart`
- `backend/lib/src/features/payments/application/sandbox_payment_simulation_service.dart`

### Backend routes

- `backend/routes/api/v1/customer/bookings/[bookingId]/payment/index.dart`
- `backend/routes/api/v1/customer/bookings/[bookingId]/payment/cancel.dart`
- `backend/routes/api/v1/payments/_middleware.dart`
- `backend/routes/api/v1/payments/webhooks/sandbox.dart`
- `backend/routes/api/v1/dev/_middleware.dart`
- `backend/routes/api/v1/dev/payments/[paymentId]/simulate.dart`
- `backend/routes/api/v1/admin/payments/index.dart`
- `backend/routes/api/v1/admin/payments/[paymentId]/index.dart`
- `backend/routes/api/v1/admin/payments/[paymentId]/events.dart`
- `backend/routes/api/v1/admin/payments/[paymentId]/refund.dart`

### Backend tests

- `backend/test/helpers/payment_test_fixtures.dart`
- `backend/test/src/features/payments/payment_domain_test.dart`
- `backend/test/src/features/payments/payment_hmac_test.dart`
- `backend/test/src/features/payments/payment_service_test.dart`
- `backend/test/routes/api/v1/payments/payment_routes_test.dart`

### Flutter

- `project/lib/features/payments/data/payment_models.dart`
- `project/lib/features/payments/data/payment_api.dart`
- `project/lib/features/payments/presentation/customer_payment_controller.dart`
- `project/lib/features/payments/presentation/customer_payment_section.dart`
- `project/lib/features/payments/presentation/customer_payment_screen.dart`
- `project/lib/features/payments/presentation/admin_payment_controller.dart`
- `project/lib/features/payments/presentation/admin_payment_list_screen.dart`
- `project/lib/features/payments/presentation/admin_payment_detail_screen.dart`
- `project/test/features/payments/data/payment_api_test.dart`
- `project/test/features/payments/presentation/customer_payment_controller_test.dart`
- `project/test/features/payments/presentation/customer_payment_screens_test.dart`
- `project/test/features/payments/presentation/admin_payment_controller_test.dart`
- `project/test/features/payments/presentation/admin_payment_screens_test.dart`

### Documentation

- `documentation/database/payments-collection.md`
- `documentation/database/payment-webhook-events-collection.md`
- `documentation/database/payment-refund-requests-collection.md`
- `documentation/api/payment-api.md`
- `documentation/architecture/payment-processing-and-webhooks.md`
- `documentation/decisions/ADR-014-payment-provider-webhooks-and-refunds.md`
- `documentation/cursor/016_payment_ledger_webhooks_and_admin_transactions.md`

## Files Modified

- `backend/.env.example` — empty `SANDBOX_PAYMENT_WEBHOOK_SECRET=` placeholder only
- `backend/lib/src/config/server_config.dart`
- `backend/lib/src/database/collection_names.dart`
- `backend/lib/src/database/database_indexes.dart`
- `backend/lib/src/features/authorization/application/role_scoped_composition.dart`
- `backend/lib/src/features/authorization/http/role_http_errors.dart`
- `backend/lib/src/features/authorization/http/role_middleware.dart`
- `backend/lib/src/features/authorization/http/role_route_helpers.dart`
- `backend/lib/src/features/bookings/application/cleaner_booking_service.dart`
- `backend/lib/src/features/bookings/application/customer_booking_service.dart`
- `backend/lib/src/features/bookings/data/booking_repository.dart`
- `backend/test/src/config/server_config_test.dart`
- `backend/test/src/features/bookings/booking_service_test.dart`
- `backend/tool/ensure_database_indexes.dart`
- `documentation/README.md`
- `documentation/api/README.md`
- `documentation/api/booking-api.md`
- `documentation/architecture/README.md`
- `documentation/architecture/backend-api-architecture.md`
- `documentation/architecture/booking-reservation-and-lifecycle.md`
- `documentation/architecture/flutter-client-architecture.md`
- `documentation/database/README.md`
- `documentation/decisions/README.md`
- `documentation/setup/development-environment.md`
- `project/lib/app/router/app_router.dart`
- `project/lib/app/router/app_routes.dart`
- `project/lib/core/network/api_failure.dart`
- `project/lib/features/admin/presentation/admin_home_screen.dart`
- `project/lib/features/bookings/presentation/customer_booking_detail_screen.dart`
- `project/test/app/router/app_router_test.dart`
- `project/test/core/network/api_failure_test.dart`
- `project/test/features/admin/presentation/admin_screens_test.dart`
- `project/test/helpers/feature_test_fakes.dart`

## Files Deleted

None.

## Commands Executed

- `git rev-parse --show-toplevel`
- `git branch --show-current`
- `git status` / `git status --short`
- `git log -10 --oneline` / `git log -1 --oneline`
- `git check-ignore -v backend/.env`
- `dart pub get` (backend, pre-task)
- `dart analyze` (backend)
- `dart test` (backend)
- `dart pub global run dart_frog_cli:dart_frog list`
- `dart format .` (backend)
- `dart run tool/ensure_database_indexes.dart` (index metadata only)
- `flutter pub get` (project, pre-task)
- `flutter analyze`
- `flutter test`
- `dart format lib test` (project)
- `flutter build apk --debug`
- `dart pub global run dart_frog_cli:dart_frog build`
- Production server: `PORT=8097 dart build\bin\server.dart`
- Safe live GETs: `/`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services`
- `git diff --stat`
- `git check-ignore -v` for `.env`, APK, `backend/build`

Not run: `dart pub upgrade`, `flutter pub upgrade`, `git add`, `git commit`, `git push`. No live payment start, simulate, webhook, refund, or admin payment calls against Atlas.

## Implementation Details

### Payment model

`payments` documents store booking/customer/cleaner ids, provider, status, quote-derived `amount_minor`/`currency_code`, optional opaque `provider_payment_id`/`provider_reference`, `attempt_number`, client idempotency key + fingerprint, failure metadata, timestamps (UTC), `refunded_amount_minor`, plus explicit `payment_active` and `settlement_recorded` booleans for partial unique indexes. No card numbers, CVV, expiry, wallet PINs, JWTs, refresh tokens, Mongo URI, access-token secret, or webhook secret.

`PaymentStatus` wire values: `pending`, `authorized`, `paid`, `failed`, `cancelled`, `partially_refunded`, `refunded`. Terminal for a charge attempt: paid, failed, cancelled, refunded. `partially_refunded` remains tied to the successful payment and blocks another full charge via `settlement_recorded`.

One successful paid payment per booking. No split-tender. No multiple currencies per booking.

### Amount authority

Flutter never sends amount or currency. `CustomerPaymentService` copies `quoted_total_minor` and `currency_code` from the booking snapshot.

### Provider boundary

`PaymentProvider`: `createPayment`, `parseAndVerifyWebhook`, `refund`. Result types (`CreatedPaymentSession`, `VerifiedWebhookEvent`, `SignedWebhookDispatch`) do not leak raw vendor payloads. `PaymentProviderResolver` constructs `SandboxPaymentProvider` only when `APP_ENV` is `development` or `test` and the webhook secret is at least 32 UTF-8 bytes. Production never falls back to sandbox (`503 payment_provider_unavailable`). Missing secret still allows the rest of the server to boot.

`PaymentProviderType` TASK 016 wire value: `sandbox` only.

### Sandbox flow

`SandboxPaymentProvider.createPayment` issues `sandbox_<secure-random-base64url>` as `provider_payment_id` with pending status. Flutter receives a safe `sandbox_session` with `simulation_available: true` only when the backend allows simulation. The client does not mutate Mongo payment status.

`POST /api/v1/dev/payments/{paymentId}/simulate` exists only when not production (`dev` middleware returns 404 in production). Body `{ "result": "success" | "failure" }`. The simulator signs a sandbox webhook and feeds `PaymentWebhookService` — no repository shortcut.

### Webhooks

`POST /api/v1/payments/webhooks/sandbox` is HMAC-authenticated, not JWT. Header `X-Sandbox-Signature`: lowercase hex HMAC-SHA256 of exact raw body bytes (hashlib `hmac_sha256`). Verification uses `HashDigest.isEqual` plus a XOR-fold hex helper. Invalid signature: `401 invalid_webhook_signature`.

Events: `payment.succeeded`, `payment.failed`, `payment.refunded`, `payment.partially_refunded`. Event collection stores provider, event id, type, provider payment id, payload SHA-256, processing status (`received` / `processed` / `ignored` / `failed`), timestamps. Unique `(provider, provider_event_id)`. Same event + same hash: 200 ack. Same event + different hash: `409 webhook_event_conflict`. Amount/currency mismatch: `409 payment_integrity_mismatch` without updating payment. Stale `payment.failed` after paid is ignored (no downgrade). Unknown payment: event ignored, no leak.

### Payment initialization idempotency

Requires `Idempotency-Key` (16–128 ASCII, trim, control-safe, not lowercased). Fingerprint: customer_user_id + booking_id. Unique index `payments_customer_idempotency_unique`. Same key + same fingerprint: replay. Same key + different booking: `409 idempotency_key_reused`. Duplicate-key race: load/compare.

### Retry and cancel

Retry after failed/cancelled when booking is still confirmed and no blocking payment exists. New document, `attempt_number = max + 1`, new idempotency key. Customer cancel of pending attempt: `POST .../payment/cancel`. Booking remains confirmed.

### Refunds

Admin `POST /api/v1/admin/payments/{paymentId}/refund` requires `Idempotency-Key`. Optional `amount_minor` (null = remaining). Reason 5–500 Unicode, trimmed, no controls. Eligible: paid / partially_refunded. Provider refund returns a signed webhook processed by the shared path. `payment_refund_requests` unique on admin_user_id + idempotency_key. Status: pending / succeeded / failed. Replay of same fingerprint returns the existing result.

### Booking cancellation orchestration

`BookingCancellationOrchestrator` used by customer and cleaner confirmed-booking cancel. Pending/authorized: cancel payment first. Paid/partially_refunded: full remaining sandbox refund through webhook path, then cancel booking. Refund failure: booking stays confirmed; `409 payment_refund_failed`. Pending bookings have no payment. TASK 015 ownership/reason policies preserved.

### Customer / admin APIs

Customer GET history `{ current, attempts }` (attempt_number descending). POST start: 201 first, 200 identical replay, 201 retry with new key. Safe DTO only; sandbox_session in development when simulation is available.

Admin list: filters status/provider/currency/booking_id/customer_user_id, limit 1–50 default 20, `_id` descending cursor. Detail may include booking snapshot name/status and webhook summaries. Events endpoint returns approved metadata only.

### Flutter

Models parse unknown enums as `unknown` without crashing. APIs use `authenticatedDioProvider`. Start/refund reuse booking idempotency helper. Sandbox simulate wrappers exist in code; UI shows **Development Sandbox** only when `simulation_available == true`. No card/CVV. Controllers: `CustomerPaymentController`, `AdminPaymentController`. Routes: `/customer/bookings/:bookingId/payment`, `/admin/payments`, `/admin/payments/:paymentId`. Cancellation UX uses the mapped refund-before-cancel message.

## Technical Decisions

- Payments collection is authoritative; no booking `payment_status_summary` cache; no Mongo multi-document transaction.
- Active uniqueness: `payment_active` boolean + partial unique `payments_booking_active_unique` (Atlas already uses boolean partial unique indexes for reservations; `$in` status partial filters were not required).
- Successful uniqueness: `settlement_recorded` + partial unique `payments_booking_settlement_unique`.
- Confirmed-booking cancel refund failure code: `payment_refund_failed` (Flutter also maps `refund_required` to the same user message).
- Webhook service pre-reads provider+event id before insert so in-memory tests without unique indexes still detect duplicates/conflicts; Atlas unique index remains the race authority.

## Verification Performed

- Pre-task git checkpoint and baselines (348 / 214).
- Dependency audit: hashlib HMAC reused; no pubspec dependency added.
- Backend analyze/test/format/`dart_frog list`.
- Live index ensure (metadata only).
- Flutter analyze/test/format/debug APK.
- Safe live GETs on a production `dart_frog build` server (PORT 8097).
- Git ignore checks for `.env`, APK, generated `backend/build`.

## Verification Results

### Backend

- `dart analyze`: No issues found
- `dart test`: **398 passed** (348 baseline + 50)
- `dart_frog list`: routes listed below
- Indexes: `dart run tool/ensure_database_indexes.dart` succeeded, including partial unique `payment_active` and `settlement_recorded`

### Flutter

- `flutter analyze`: No issues found
- `flutter test`: **244 passed** (214 baseline + 30)
- `flutter build apk --debug`: succeeded → `project/build/app/outputs/flutter-apk/app-debug.apk` (not committed)

### Live backend (PORT 8097, TASK 016 production build)

- `GET /` → 200 `home_cleaning_marketplace_api`
- `GET /api/v1/health` → 200
- `GET /api/v1/ready` → 200
- `GET /api/v1/services` → 200 public catalog (`home-cleaning` / hourly)

No payment start, sandbox simulate, webhook, refund, or admin payment routes invoked live.

## Errors / Warnings

- `dart_frog dev` fails in this non-TTY environment (`StdinException` echo mode). Live GETs used `dart_frog build` + `dart build\bin\server.dart`, matching TASK 014/015.
- Port 8098 was already occupied by a leftover process; TASK 016 live GETs used **8097**.
- Untracked `project/devtools_options.yaml` appeared from Flutter tooling (empty extensions). Not part of TASK 016 and not staged.
- `dart format .` in backend reformatted generated `backend/build/bin/server.dart` only (gitignored). Source already formatted.

## Security / Secrets Check

This task added backend-only `SANDBOX_PAYMENT_WEBHOOK_SECRET` configuration. `.env.example` has an empty placeholder. No secret values were logged, committed, placed in Flutter, or recorded in this report. Tests use a fake secret in test code only. Production sandbox is prohibited. HMAC uses hashlib; comparison is constant-time. Clients cannot supply amount/currency. No PCI/card fields. Safe error mapping; no raw Mongo/provider/Dio strings in UX. `.env` remains gitignored.

## Git Diff Summary

Uncommitted TASK 016 payment ledger, sandbox provider, webhook/refund/cancellation orchestration, Flutter customer/admin payment UX, tests, indexes, and documentation. No `.env`, APK, `backend/build`, or secret values tracked.

## Final Repository State

Working tree dirty with TASK 016 changes. Not staged. Not committed. Not pushed.

## Unresolved Issues

None blocking TASK 016. Real gateway adapters, 3DS, PCI hosted elements, payouts, tax, fees, chargebacks, disputes, webhook delivery queues, and multi-currency conversion remain deferred.

## Suggested Next Step

TASK 017 as prepared by ChatGPT. Do not begin it in this task. Do not integrate a real payment provider in this task.

## Checkpoint

Clean `main` at TASK 015 `f960ae1`. TASK 015 report SUCCESS. `backend/.env` ignored.

## Baselines

Backend 348 tests, Flutter 214 tests, both analyzes clean, before implementation.

## Dependencies

No new direct package. Backend reused hashlib, Dart Frog, mongo_dart. Flutter reused Dio, Riverpod, go_router. Dart SDK: `dart:convert`, `dart:io`, `dart:math`.

## Schema

Collections: `payments`, `payment_webhook_events`, `payment_refund_requests`. UTC timestamps. No security/card/secret fields persisted on payments. Webhook events store payload SHA-256, not raw payload or signature.

## Payment states

`PaymentStatus` enum with the seven wire values above. Application services do not scatter raw status strings.

## Provider abstraction

Narrow `PaymentProvider`. Application services do not import the sandbox type except the resolver/simulator composition. A future real adapter can implement the same interface.

## Sandbox restriction

Allowed only for `development` and `test`. Production: `503 payment_provider_unavailable`. No silent fallback. Server boots if the sandbox secret is absent.

## HMAC

HMAC-SHA256 via hashlib. `X-Sandbox-Signature`. Exact raw body. Lowercase hex. Constant-time compare.

## Webhook format

Provider-like JSON: `event_id`, `event_type`, `provider_payment_id`, `amount_minor`, `currency_code`, `created_at`. Success/failure/refund/partial refund event types as specified.

## Event idempotency

Unique provider + provider_event_id. Duplicate identical payload: 200. Different payload hash: `webhook_event_conflict`. Unique index is the race authority.

## Payment idempotency

Customer `Idempotency-Key` + fingerprint + unique customer+key index. Replay vs `idempotency_key_reused`.

## Active-payment uniqueness

`payment_active` + partial unique index on `booking_id` where `payment_active == true`. Documented in collection docs and ADR-014.

## Amount authority

Booking `quoted_total_minor` and `currency_code` only.

## Attempt retry

New payment document after failed/cancelled; incremented `attempt_number`; new idempotency key.

## Refunds

Full and partial. Remaining amount when omitted. Reason validation. Provider refund + webhook path. `RefundRequestStatus` pending/succeeded/failed.

## Refund idempotency

`payment_refund_requests` unique admin_user_id + idempotency_key. Same fingerprint replay. Different intent: `idempotency_key_reused`.

## Out-of-order events

Failed after paid ignored. Duplicate success/refund events idempotent by event id. Unknown payment ignored. Paid never downgraded to failed.

## Booking cancellation orchestration

HTTP handlers stay thin. Orchestrator: cancel pending payment, refund paid/partial, then existing conditional booking cancel. Failed refund keeps booking confirmed.

## Repositories / services

`PaymentRepository`, `PaymentWebhookEventRepository`, `PaymentRefundRequestRepository` with conditional updates. `CustomerPaymentService`, `PaymentWebhookService`, `AdminPaymentService`, `BookingCancellationOrchestrator`, `SandboxPaymentSimulationService`.

## Customer APIs

- `GET /api/v1/customer/bookings/{bookingId}/payment`
- `POST /api/v1/customer/bookings/{bookingId}/payment`
- `POST /api/v1/customer/bookings/{bookingId}/payment/cancel`

Customer role. Pay only when booking `confirmed`. Else `409 booking_not_payable`.

## Webhook API

- `POST /api/v1/payments/webhooks/sandbox`

## Development simulation API

- `POST /api/v1/dev/payments/{paymentId}/simulate`

Production middleware 404. Tests inject config.

## Admin APIs

- `GET /api/v1/admin/payments`
- `GET /api/v1/admin/payments/{paymentId}`
- `GET /api/v1/admin/payments/{paymentId}/events`
- `POST /api/v1/admin/payments/{paymentId}/refund`

Admin role only.

## Indexes + metadata

payments:

1. `payments_provider_payment_id_unique` — provider + provider_payment_id unique, partial `provider_payment_id` type string
2. `payments_customer_idempotency_unique` — customer_user_id + client_idempotency_key unique
3. `payments_booking_attempt_unique` — booking_id + attempt_number unique
4. `payments_booking_id_desc` — booking_id + `_id` desc
5. `payments_customer_id_desc` — customer_user_id + `_id` desc
6. `payments_status_id_desc` — status + `_id` desc
7. `payments_booking_active_unique` — booking_id unique, partial `payment_active == true`
8. `payments_booking_settlement_unique` — booking_id unique, partial `settlement_recorded == true`

payment_webhook_events:

1. `payment_webhook_events_provider_event_unique`
2. `payment_webhook_events_payment_created`

payment_refund_requests:

1. `payment_refund_admin_idempotency_unique`
2. `payment_refund_payment_created`

Live ensure verified these names/partial filters. No payment/webhook/refund **documents** were created on Atlas by this task.

## Flutter models / APIs / controllers / UX

Described above. Admin Home includes Payments. Sandbox labeled Development Sandbox. No fake card form.

## Backend tests

Domain, initialization, webhook, refund, cancellation integration, admin, HMAC, routes. All in-memory/fakes. No Atlas lifecycle tests.

## Flutter tests

Models/API (Idempotency-Key including auth refresh), controllers, customer/admin widgets, router role gating. Existing booking/discovery/profile/onboarding routes remain green.

## APK

Debug APK built successfully. Not tracked.

## Safe live GETs

Only `/`, `/health`, `/ready`, `/services`.

## Security

No client amount authority. No card data. Sandbox forbidden in production. Webhook HMAC + constant-time compare. Event/payment/refund idempotency. Conditional payment states. Payment-aware cancellation. No raw provider/Mongo errors. No secrets in Flutter. No secret logs. `.env` ignored.

## Live data safety

Live Atlas mutation: approved index ensure only. No live payments, webhook events, refund requests, bookings, customers, cleaners, or sessions created by TASK 016 payment simulation.

## Git status

Uncommitted, unstaged. `git check-ignore -v backend/.env` → `.gitignore:8:.env`.

## Issues / Warnings

See Errors / Warnings. None blocking.

## Final Statement

Payment ledger, development/test sandbox provider, signed webhook processing with replay protection, refund foundation, payment-aware booking cancellation, and admin transaction management are complete and ready for ChatGPT review. No real payment provider was integrated. Payouts, chat, and reviews were not implemented. TASK 017 was not started. TASK 016 is uncommitted.
