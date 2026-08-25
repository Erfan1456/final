# Cursor Task 019 — Cleaner Earnings, Payouts, and Reconciliation

## Metadata

- Task ID: 019
- Task title: Cleaner Earnings Ledger, Payout Requests, Sandbox Settlement, and Financial Reconciliation
- Date: 2026-08-26
- Git branch: main
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Implement an append-only cleaner earnings ledger with snapshotted platform commission, refund adjustments, payout requests with sandbox settlement, signed payout webhooks, admin finance/reconciliation, and Flutter cleaner/admin finance UX. Do not implement a real payout provider, bank/card storage, KYC, tax, currency conversion, or AI. Do not commit.

## Exact Cursor Prompt

~~~~text
# TASK 019 — Cleaner Earnings Ledger, Payout Requests, Sandbox Settlement, and Financial Reconciliation

Repository:

D:\freelance\erfankhan_cse489\final

TASK 018 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

The marketplace currently supports:

- authentication and persisted-role authorization;
- profiles and addresses;
- cleaner onboarding;
- services and availability;
- discovery;
- booking reservation/lifecycle;
- payment ledger;
- development sandbox payment provider;
- signed payment webhooks;
- refunds;
- chat;
- notifications;
- verified reviews;
- disputes;
- admin user moderation;
- admin booking operations;
- append-only audit logs.

TASK 019 must implement the marketplace's cleaner financial settlement layer.

Implement:

CLEANER EARNINGS
- immutable earnings ledger;
- one original earning per completed + paid booking;
- platform commission snapshot;
- cleaner net earning snapshot;
- automatic refund adjustments;
- negative-balance support after post-payout refunds;
- earnings summary;
- ledger history.

PAYOUTS
- cleaner payout requests;
- available-balance validation;
- one active payout request per cleaner;
- idempotent payout requests;
- cleaner cancellation while still requested;
- admin payout review;
- admin payout rejection;
- admin payout processing;
- provider-neutral PayoutProvider boundary;
- DEVELOPMENT/TEST-ONLY sandbox payout provider;
- signed payout webhooks;
- webhook replay/idempotency;
- payout success/failure settlement;
- payout history.

ADMIN FINANCE
- payout queue;
- payout detail;
- financial reconciliation summary;
- cleaner financial detail;
- audit integration.

FLUTTER
- Cleaner Earnings dashboard;
- earnings ledger;
- payout request flow;
- payout history;
- Admin Payout Operations;
- Admin Finance/Reconciliation dashboard;
- sandbox settlement controls only when backend explicitly allows them.

Do NOT implement:

- real bank transfer;
- Stripe Connect;
- PayPal Payouts;
- bKash payout;
- bank-account storage;
- card storage;
- payout destination credentials;
- KYC;
- tax documents;
- tax withholding;
- currency conversion;
- multi-currency netting;
- chargebacks;
- automated fraud detection;
- AI;
- scheduled payout cron jobs.

No AI features.

======================================================================
IMPORTANT PRODUCT HONESTY
======================================================================

TASK 019 must never claim:

- real money was transferred;
- a bank account was paid;
- a production payout provider is configured.

The sandbox provider exists only to exercise:

- payout state;
- payout idempotency;
- provider callbacks;
- webhook authentication;
- webhook replay handling;
- payout success/failure;
- reconciliation UI.

Production must NEVER silently fall back to sandbox payout processing.

======================================================================
NO NEW DIRECT DEPENDENCY POLICY
======================================================================

Expected:

BACKEND:
no new direct dependency

FLUTTER:
no new direct dependency

Reuse existing:

Backend:
- Dart Frog
- mongo_dart
- hashlib
- existing environment/configuration architecture

Flutter:
- Dio
- Riverpod
- go_router
- existing authenticated networking

If a genuinely unavoidable new package is required:

STOP before adding it.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 018 checkpoint:

Backend:

dart analyze:
clean

dart test:
443 passed

Flutter:

flutter analyze:
clean

flutter test:
324 passed

Verify these exact baselines before implementation.

Use Dart Frog route command:

dart pub global run dart_frog_cli:dart_frog list

Do NOT rely on plain:

dart_frog list

because it is not directly available on PATH.

======================================================================
PLATFORM COMMISSION CONFIGURATION
======================================================================

Add:

PLATFORM_COMMISSION_BPS

Meaning:

platform commission in basis points.

Examples:

0    = 0%
500  = 5%
1500 = 15%
10000 = 100%

Validation:

integer
0–10000 inclusive.

Do NOT accept commission from Flutter.

Do NOT store commission policy on customer/cleaner profile.

The server configuration is authoritative at the time an earning is created.

For development/test:

a deterministic default may be used if existing configuration conventions
allow it.

Preferred default:

1500

for development/test ONLY.

For production:

configuration should be explicit.

If existing ServerConfig conventions make an explicit production requirement
awkward, document the chosen safe behavior.

This value is NOT secret.

Add placeholder/example documentation to:

backend/.env.example

Do not put production business configuration in Flutter.

======================================================================
WHY COMMISSION MUST BE SNAPSHOTTED
======================================================================

Platform commission may change in the future.

Therefore an earning record must snapshot:

gross_amount_minor
commission_bps
platform_fee_minor
cleaner_net_minor

Existing earnings must not be recalculated when configuration changes later.

======================================================================
COMMISSION INTEGER MATH
======================================================================

Never use double for money.

Given:

gross

and:

commission_bps

calculate round-half-up:

platform_fee_minor =
(gross * commission_bps + 5000) ~/ 10000

cleaner_net_minor =
gross - platform_fee_minor

Use integer arithmetic only.

======================================================================
EARNINGS LEDGER COLLECTION
======================================================================

Create:

earnings_ledger

Document:

{
  "_id": ObjectId,

  "cleaner_user_id": ObjectId,
  "booking_id": ObjectId,
  "payment_id": ObjectId,

  "entry_type": String,

  "gross_amount_minor": int,
  "commission_bps": int,
  "platform_fee_minor": int,
  "cleaner_amount_minor": int,

  "currency_code": String,

  "source_event_key": String,

  "created_at": DateTime
}

Ledger is append-only.

No update.

No delete.

======================================================================
EARNINGS ENTRY TYPES
======================================================================

Create enum:

EarningsEntryType

Wire values:

service_earning
refund_adjustment

`cleaner_amount_minor`:

service_earning:
positive

refund_adjustment:
negative

Do not create:

manual_adjustment

in TASK 019.

Admin must not arbitrarily alter cleaner balance.

======================================================================
SERVICE EARNING ELIGIBILITY
======================================================================

Create one `service_earning` only when BOTH are true:

booking.status == completed

AND

a successful payment exists with status:

paid
partially_refunded
refunded

However:

if the payment is already partially/full refunded before earning creation,
the ledger must represent the correct economic state.

Preferred approach:

1. create the ORIGINAL full service earning based on payment amount;
2. create refund adjustment entries corresponding to already-applied refunds.

This preserves historical accounting.

Do NOT simply create a reduced earning that loses refund history.

======================================================================
ONE ORIGINAL EARNING PER BOOKING
======================================================================

Guarantee exactly one:

service_earning

per booking.

Use a deliberate unique strategy.

Preferred document field:

source_event_key

Examples:

earning:booking:<bookingId>

Unique index:

earnings_ledger_source_event_unique

source_event_key: 1

unique:
true

Refund adjustment events use their own deterministic source event keys.

Correctness must rely on the unique index.

Not only a pre-read.

======================================================================
EARNING CREATION TRIGGERS
======================================================================

Earning creation must be idempotently attempted from BOTH:

1. successful cleaner job completion;
2. successful payment transition to paid.

Reason:

either domain transition may happen before the other.

Create:

EarningsSettlementService.ensureBookingEarning(...)

or equivalent.

It:

- loads booking;
- requires completed;
- resolves authoritative successful payment;
- creates service earning idempotently;
- ensures already-existing refund adjustments;
- safely returns no-op when conditions are not yet met.

Do NOT duplicate earning logic in booking and payment services.

======================================================================
PAYMENT AUTHORITY
======================================================================

Use Payment as authoritative financial settlement record.

Original earning gross amount:

payment.amount_minor

Currency:

payment.currency_code

These should correspond to booking immutable quote.

Do not accept amount from caller.

======================================================================
REFUND ADJUSTMENTS
======================================================================

When successful payment refund state changes, reduce cleaner earnings.

For each incremental refund amount:

refund_delta_minor

Compute:

platform_fee_refund_minor =
(refund_delta_minor * commission_bps + 5000) ~/ 10000

cleaner_refund_minor =
refund_delta_minor - platform_fee_refund_minor

Create:

refund_adjustment

with:

gross_amount_minor = -refund_delta_minor

platform_fee_minor = -platform_fee_refund_minor

cleaner_amount_minor = -cleaner_refund_minor

Use original earning's:

commission_bps

NOT current configuration.

This is critical.

======================================================================
REFUND EVENT IDEMPOTENCY
======================================================================

Do not create duplicate refund adjustments from repeated provider webhook.

Use deterministic source event key based on the applied payment event.

Preferred concept:

refund:<provider>:<providerEventId>

or another stable unique event identity already present in the payment webhook
processing result.

Do not use current timestamp/randomness.

Duplicate webhook:

no duplicate ledger entry.

======================================================================
CUMULATIVE REFUNDS
======================================================================

For:

partial refund 1
partial refund 2
full remaining refund

each actual incremental refund event creates one adjustment.

The sum of refund adjustments must never exceed the original paid amount.

Existing payment webhook integrity remains authoritative.

Do not reinvent payment refund validation.

======================================================================
NEGATIVE CLEANER BALANCE
======================================================================

Cleaner balance MAY become negative.

Example:

- cleaner receives payout;
- later administrator refunds completed booking.

Do NOT clamp balance to zero.

Negative balance means future earnings must offset the deficit before another
payout can be requested.

This is deliberate accounting behavior.

======================================================================
EARNINGS SUMMARY
======================================================================

For a cleaner and optional currency:

calculate:

gross_earned_minor
platform_fees_minor
refunds_gross_minor
cleaner_refund_adjustments_minor
net_ledger_minor
reserved_payout_minor
paid_out_minor
available_balance_minor

Because multiple currencies may eventually exist:

TASK 019 must NOT combine different currencies into one number.

API should return per-currency summaries.

No exchange-rate conversion.

======================================================================
PAYOUT BALANCE FORMULA
======================================================================

For one currency:

net_ledger_minor =
sum cleaner_amount_minor from earnings_ledger

reserved_payout_minor =
sum payout amount where status in:
requested
processing

paid_out_minor =
sum payout amount where status == paid

available_balance_minor =
net_ledger_minor
- reserved_payout_minor
- paid_out_minor

Failed/cancelled/rejected payout requests:

do NOT reduce available balance.

If result is negative:

return negative value.

Payout request requires:

available_balance_minor > 0.

======================================================================
PAYOUT REQUEST COLLECTION
======================================================================

Create:

payout_requests

Document:

{
  "_id": ObjectId,

  "cleaner_user_id": ObjectId,

  "amount_minor": int,
  "currency_code": String,

  "status": String,

  "attempt_number": int,

  "client_idempotency_key": String,
  "request_fingerprint": String,

  "provider": String?,
  "provider_payout_id": String?,

  "requested_at": DateTime,
  "processing_at": DateTime?,
  "paid_at": DateTime?,
  "failed_at": DateTime?,
  "cancelled_at": DateTime?,
  "rejected_at": DateTime?,

  "failure_code": String?,
  "failure_message": String?,

  "rejection_reason": String?,

  "processed_by": ObjectId?,

  "created_at": DateTime,
  "updated_at": DateTime
}

Do NOT store:

bank account
routing number
mobile wallet PIN
card
CVV
password
JWT
refresh token
provider secret.

======================================================================
PAYOUT STATUS
======================================================================

Create:

PayoutStatus

Wire values:

requested
processing
paid
failed
cancelled
rejected

Lifecycle:

cleaner request:
none → requested

cleaner cancel:
requested → cancelled

admin reject:
requested → rejected

admin process:
requested → processing

provider success:
processing → paid

provider failure:
processing → failed

Terminal:

paid
failed
cancelled
rejected

Do not reopen a payout request.

A cleaner makes a NEW request after failure/rejection/cancellation.

======================================================================
ONE ACTIVE PAYOUT PER CLEANER
======================================================================

At most one payout where:

status == requested
or
status == processing

per cleaner.

Use an explicit:

payout_active: bool

field if that gives the cleanest Mongo partial unique index.

If used:

requested:
true

processing:
true

terminal:
false

Create partial unique index:

payout_requests_cleaner_active_unique

cleaner_user_id: 1

unique:
true

partial:
payout_active == true

Status and payout_active MUST update atomically.

======================================================================
PAYOUT REQUEST IDEMPOTENCY
======================================================================

Cleaner:

POST payout

requires:

Idempotency-Key

Same validation already used elsewhere:

16–128 ASCII
trim
no controls
do not lowercase.

Fingerprint:

cleaner_user_id
amount_minor
currency_code

Unique:

cleaner_user_id
client_idempotency_key

Same key + same fingerprint:

return existing request.

Same key + different intent:

409
idempotency_key_reused

Duplicate-key race:

load existing and compare.

======================================================================
PAYOUT AMOUNT VALIDATION
======================================================================

amount_minor:

integer only
>= 1

No doubles.

No string numbers.

currency_code:

three ASCII letters
normalize uppercase.

Requested amount must be:

<= available_balance_minor

for that currency at time of creation.

Otherwise:

409
insufficient_payout_balance

======================================================================
PAYOUT CONCURRENCY
======================================================================

Two simultaneous payout requests could both read the same available balance.

Correctness relies on:

one-active-payout-per-cleaner partial unique index.

Therefore at most one succeeds as active.

When duplicate-active race occurs:

409
payout_already_active

Do not expose Mongo duplicate-key details.

======================================================================
CLEANER PAYOUT CANCELLATION
======================================================================

Cleaner may cancel only:

requested

Use conditional selector:

_id
cleaner_user_id
status == requested
payout_active == true

Set:

cancelled
payout_active false
cancelled_at
updated_at

Unknown/foreign:

404
payout_not_found

Processing payout cannot be cancelled by cleaner in TASK 019.

======================================================================
PAYOUT PROVIDER BOUNDARY
======================================================================

Create:

PayoutProvider

Conceptual responsibilities:

createPayout(...)
parseAndVerifyWebhook(...)

TASK 019 provider enum:

sandbox

only.

Do not add fake enum entries for providers that do not exist.

======================================================================
SANDBOX PAYOUT PROVIDER
======================================================================

Create:

SandboxPayoutProvider

Allowed only when:

APP_ENV == development
or
APP_ENV == test

Production:

must return:

503
payout_provider_unavailable

Never silently enable sandbox in production.

======================================================================
SANDBOX PAYOUT WEBHOOK SECRET
======================================================================

Add backend-only config:

SANDBOX_PAYOUT_WEBHOOK_SECRET

Minimum:

32 UTF-8 bytes.

Add placeholder only to:

backend/.env.example

Never print real value.

Never place value in Flutter.

Do not ask user to paste it into ChatGPT.

If local secret is not configured:

sandbox payout runtime may report unavailable.

The rest of backend must still boot.

======================================================================
PAYOUT PROVIDER ID
======================================================================

Sandbox provider generates opaque:

provider_payout_id

Example prefix:

sandbox_payout_

+

secure random base64url.

Do not use sequential ids.

======================================================================
ADMIN PROCESS PAYOUT
======================================================================

Route later defined.

Only:

requested

may process.

Workflow:

1. conditional transition requested → processing;
2. set payout_active remains true;
3. set processed_by admin;
4. invoke provider createPayout using backend-owned payout amount/currency;
5. persist provider id safely.

IMPORTANT:

Provider-call failure must safely transition:

processing → failed

and:

payout_active = false

where possible.

Do not leave an obviously failed provider request permanently reserving balance.

Document cross-system consistency limitation.

======================================================================
DEVELOPMENT PAYOUT SIMULATION
======================================================================

Add DEV-only:

POST /api/v1/dev/payouts/[payoutId]/simulate

Body:

{
  "result": "success"
}

or

{
  "result": "failure"
}

Only operational when:

APP_ENV == development.

Production:

404 or safe unavailable behavior.

This route MUST NOT directly mutate payout state.

It must generate a signed sandbox payout webhook and invoke the SAME webhook
processing path.

No shortcut.

======================================================================
PAYOUT WEBHOOK ROUTE
======================================================================

Add:

POST /api/v1/payouts/webhooks/sandbox

Authentication:

HMAC-SHA256

Header:

X-Sandbox-Payout-Signature

Sign:

exact raw request body.

Use constant-time comparison.

Invalid:

401
invalid_payout_webhook_signature

Do not expose secret details.

======================================================================
PAYOUT WEBHOOK EVENT COLLECTION
======================================================================

Create:

payout_provider_events

Document:

{
  "_id": ObjectId,
  "provider": String,
  "provider_event_id": String,
  "event_type": String,
  "provider_payout_id": String,
  "payload_sha256": String,
  "processing_status": String,
  "processed_at": DateTime?,
  "created_at": DateTime
}

Do not persist raw secret/signature.

Do not need full raw payload.

======================================================================
PAYOUT EVENT TYPES
======================================================================

Sandbox provider:

payout.paid
payout.failed

Event payload includes:

provider event id
provider payout id
amount_minor
currency_code
created_at

Verify amount/currency exactly against payout request.

Mismatch:

409
payout_integrity_mismatch

No state mutation.

======================================================================
PAYOUT WEBHOOK IDEMPOTENCY
======================================================================

Unique:

provider
provider_event_id

Duplicate identical event:

safe 200 acknowledgement.

Same provider_event_id with different payload hash:

409
payout_webhook_event_conflict

Correctness relies on database uniqueness.

======================================================================
PAYOUT WEBHOOK STATE
======================================================================

payout.paid:

processing → paid

Set:

payout_active false
paid_at

payout.failed:

processing → failed

Set:

payout_active false
failed_at
safe failure fields

Stale paid event after terminal failed:

do not silently resurrect payout.

Stale failed event after paid:

do not downgrade.

Mark event ignored where appropriate.

======================================================================
PAYOUT NOTIFICATIONS
======================================================================

Extend NotificationType.

Recommended:

payout_requested
payout_processing
payout_paid
payout_failed
payout_rejected
payout_cancelled

New payout request:

optionally notify admins if existing notification architecture supports a safe
admin-target strategy.

Not mandatory.

Cleaner notifications ARE required for:

admin processing
paid
failed
rejected

Cleaner cancellation does not require self-notification.

Use deterministic dedupe keys.

Duplicate provider event:

no duplicate notification.

Notification remains best-effort.

======================================================================
PAYOUT AUDIT ACTIONS
======================================================================

Extend AuditAction:

payout_processing_started
payout_rejected

Optionally:

payout_sandbox_simulated

Do NOT audit provider webhook secret/signature.

Do NOT write full provider payload.

Payout success/failure provider events themselves are visible via provider-event
records.

Admin processing/rejection actions should have audit entries.

======================================================================
ADMIN REJECT PAYOUT
======================================================================

POST reject body:

{
  "reason": "..."
}

Reason:

required
5–500 Unicode code points
trim
plain text
reject controls.

Only:

requested → rejected

Set:

payout_active false
rejected_at
rejection_reason
processed_by admin

Notify cleaner.

Audit action.

======================================================================
PAYOUT ATTEMPT NUMBER
======================================================================

For each cleaner + currency, attempts may increment globally or per cleaner.

Simpler policy:

attempt_number =
previous maximum for cleaner + 1

Currency may differ.

Document exact approach.

No security meaning attached.

======================================================================
CLEANER FINANCIAL API
======================================================================

Add cleaner-role routes:

GET /api/v1/cleaner/earnings/summary

GET /api/v1/cleaner/earnings/ledger

GET /api/v1/cleaner/payouts

POST /api/v1/cleaner/payouts

GET /api/v1/cleaner/payouts/[payoutId]

POST /api/v1/cleaner/payouts/[payoutId]/cancel

Cleaner role only.

No approved-cleaner requirement for historical earnings/payout reads.

Reason:

historical financial records must remain accessible even if onboarding state
changes later.

Persisted active cleaner account is still required.

======================================================================
EARNINGS SUMMARY API
======================================================================

GET:

/api/v1/cleaner/earnings/summary

Return:

{
  "currencies": [
    {
      "currency_code": "BDT",
      "gross_earned_minor": ...,
      "platform_fees_minor": ...,
      "refunds_gross_minor": ...,
      "cleaner_refund_adjustments_minor": ...,
      "net_ledger_minor": ...,
      "reserved_payout_minor": ...,
      "paid_out_minor": ...,
      "available_balance_minor": ...
    }
  ]
}

Do not combine currencies.

======================================================================
EARNINGS LEDGER API
======================================================================

GET:

/api/v1/cleaner/earnings/ledger

Query:

currency
entry_type
limit
after

limit:
20 default
1–50

after:
ObjectId

Sort:
_id descending

No offset.

Safe fields only.

Do not expose internal source_event_key unless genuinely useful.

Preferred:

omit source_event_key from client DTO.

======================================================================
CLEANER PAYOUT LIST
======================================================================

GET:

/api/v1/cleaner/payouts

Query:

status
currency
limit
after

Sort:

_id descending.

No admin/security fields except safe rejection reason may be shown to cleaner.

Do NOT expose:

processed_by
client idempotency key
fingerprint
provider webhook metadata.

======================================================================
CLEANER PAYOUT CREATE
======================================================================

POST:

/api/v1/cleaner/payouts

Header:

Idempotency-Key

Body:

{
  "amount_minor": 100000,
  "currency_code": "BDT"
}

Return:

201 first creation

200 idempotent replay

No payout destination info.

======================================================================
ADMIN PAYOUT API
======================================================================

Add:

GET /api/v1/admin/payouts

GET /api/v1/admin/payouts/[payoutId]

POST /api/v1/admin/payouts/[payoutId]/process

POST /api/v1/admin/payouts/[payoutId]/reject

Admin only.

======================================================================
ADMIN PAYOUT LIST
======================================================================

Query:

status
currency
cleaner_user_id
limit
after

Default status:

requested

limit:
20
1–50

after:
ObjectId

Sort:
_id descending

Safe summary:

payout id
cleaner id
cleaner display name
amount
currency
status
attempt
requested date

No secrets.

======================================================================
ADMIN PAYOUT DETAIL
======================================================================

Return:

safe payout data
cleaner safe profile summary
earnings summary for payout currency
provider-event summaries
audit-safe operational metadata

Do NOT expose:

password
sessions
token
idempotency key
fingerprint
HMAC signature
webhook secret.

======================================================================
ADMIN FINANCE SUMMARY API
======================================================================

Add:

GET /api/v1/admin/finance/summary

Query:

from
to
currency

Dates:

explicit timezone/offset
normalize UTC.

If omitted:

reasonable bounded default such as last 30 days.

Maximum range:

366 days.

Return PER CURRENCY:

gross_service_volume_minor
platform_fee_minor
cleaner_net_earnings_minor
refund_gross_minor
cleaner_refund_adjustments_minor
payout_requested_minor
payout_processing_minor
payout_paid_minor
payout_failed_minor

No currency conversion.

Do not label:

profit

because platform operating costs/tax are not represented.

Use:

platform_fee_minor

not "profit".

======================================================================
ADMIN CLEANER FINANCE DETAIL
======================================================================

Add:

GET /api/v1/admin/cleaners/[userId]/finance

Admin only.

Return:

per-currency cleaner earnings summary
recent ledger entries
recent payouts

No bank information because none exists.

======================================================================
EARNINGS REPOSITORY
======================================================================

Create:

EarningsLedgerRepository

Responsibilities conceptually:

findBySourceEventKey
append
listForCleaner
aggregateCleanerCurrencySummary
aggregateAdminFinanceSummary
findServiceEarningForBooking

Append-only.

No update/delete.

Duplicate source-event handling explicit.

======================================================================
PAYOUT REPOSITORY
======================================================================

Create narrow:

PayoutRepository

Responsibilities:

findById
findOwnedById
findByCleanerIdempotency
findActiveForCleaner
nextAttemptNumber
listForCleaner
adminPage
createRequested
cancelRequested
startProcessing
attachProviderPayoutId
markPaid
markFailed
rejectRequested
aggregatePayoutTotals

Conditional selectors mandatory.

No arbitrary update maps exposed.

======================================================================
PAYOUT EVENT REPOSITORY
======================================================================

Create:

PayoutProviderEventRepository

Responsibilities similar to payment webhook event repository.

Use duplicate event handling.

======================================================================
EARNINGS SETTLEMENT SERVICE
======================================================================

Create:

EarningsSettlementService

Responsibilities:

ensureBookingEarning
applyRefundAdjustment

It is HTTP-independent.

It must be idempotent.

Primary payment/booking business operations must not be undone solely because
earnings ledger side effect fails unexpectedly.

IMPORTANT:

Because earnings affect money owed to cleaner, failure must not simply disappear.

If settlement append fails unexpectedly:

- booking/payment primary operation remains authoritative;
- emit safe server diagnostic;
- document reconciliation need;
- admin financial reconciliation should make inconsistencies discoverable.

Do NOT falsely claim distributed exactly-once financial accounting.

======================================================================
RECONCILIATION PRINCIPLE
======================================================================

TASK 019 must include a reconciliation operation/service capable of detecting:

- completed + successful payment booking with missing service earning;
- refund amount that is not fully represented by refund-adjustment ledger;
- duplicate impossible conditions if any are visible;
- paid payout states included in balance calculations.

Do NOT automatically mutate live application data through admin GET.

Provide read-only reconciliation detection.

Recommended admin route:

GET /api/v1/admin/finance/reconciliation

Query:

currency
limit
after

Return safe inconsistency summaries.

Examples:

missing_service_earning
refund_adjustment_mismatch

Do not dump private records.

======================================================================
OPTIONAL CONTROLLED RECONCILIATION TOOL
======================================================================

A controlled backend tool MAY be created to repair missing earnings in the
future, but TASK 019 must NOT run a repair against live Atlas.

Preferred:

read-only API/service detection only.

Do not auto-heal silently.

======================================================================
PAYOUT APPLICATION SERVICES
======================================================================

Create:

CleanerPayoutService

Responsibilities:

summary
ledger
list payouts
get payout
request payout
cancel requested payout

Create:

AdminPayoutService

Responsibilities:

list
detail
process
reject

Create:

PayoutWebhookService

Responsibilities:

signature
event idempotency
payload integrity
conditional provider result

Create:

AdminFinanceService

Responsibilities:

summary
cleaner finance
reconciliation.

======================================================================
ERROR CODES
======================================================================

Add safe errors:

insufficient_payout_balance
payout_already_active
payout_not_found
invalid_payout_state
payout_provider_unavailable
invalid_payout_amount
invalid_payout_currency
invalid_payout_webhook_signature
payout_webhook_event_conflict
payout_integrity_mismatch
invalid_payout_rejection_reason

Reuse:

idempotency_key_required
invalid_idempotency_key
idempotency_key_reused

Do not expose Mongo/provider internals.

======================================================================
DATABASE INDEXES
======================================================================

EARNINGS_LEDGER

1.

earnings_ledger_source_event_unique

source_event_key: 1
unique: true

2.

earnings_ledger_cleaner_currency_id_desc

cleaner_user_id: 1
currency_code: 1
_id: -1

3.

earnings_ledger_booking_type

booking_id: 1
entry_type: 1

4.

earnings_ledger_created_at

created_at: -1
_id: -1

Evaluate redundancy.

PAYOUT_REQUESTS

1.

payout_requests_cleaner_idempotency_unique

cleaner_user_id: 1
client_idempotency_key: 1

unique: true

2.

payout_requests_cleaner_active_unique

cleaner_user_id: 1

unique: true

partial:
payout_active == true

3.

payout_requests_cleaner_id_desc

cleaner_user_id: 1
_id: -1

4.

payout_requests_status_id_desc

status: 1
_id: -1

5.

payout_requests_provider_payout_unique

provider: 1
provider_payout_id: 1

unique:
true

partial where provider_payout_id exists.

PAYOUT_PROVIDER_EVENTS

1.

payout_events_provider_event_unique

provider: 1
provider_event_id: 1

unique:
true

2.

payout_events_provider_payout_created

provider_payout_id: 1
created_at: 1

Evaluate all redundancy deliberately.

======================================================================
COLLECTION NAMES
======================================================================

Extend central collection names:

earnings_ledger
payout_requests
payout_provider_events

No scattered collection literals.

======================================================================
LIVE DATABASE POLICY
======================================================================

TASK 019 may live-mutate Atlas ONLY through:

controlled index ensure.

It MUST NOT create live:

earnings entries
payout requests
payout events
bookings
payments
refunds
users
sessions

Do NOT run sandbox payout simulation against real application records.

All lifecycle testing:

fakes/in-memory stores only.

======================================================================
BACKEND TESTS — COMMISSION
======================================================================

Test:

0 bps
500 bps
1500 bps
10000 bps
round-half-up edge cases
integer-only behavior
no doubles
net = gross - fee.

======================================================================
BACKEND TESTS — EARNINGS
======================================================================

Test:

completed + paid creates earning
completed + payment missing → no-op
paid + booking not completed → no-op
completion later creates
payment later creates
both trigger paths still one entry
duplicate source-event race
correct gross
correct commission snapshot
correct platform fee
correct cleaner net
currency from payment
no client amount influence.

======================================================================
BACKEND TESTS — REFUND ADJUSTMENTS
======================================================================

Test:

partial refund
second partial refund
full remaining refund
uses ORIGINAL earning commission rate
not current config
negative ledger entry
duplicate webhook/event no duplicate adjustment
cumulative math
refund before earning creation gets represented after earning creation
negative cleaner balance allowed.

======================================================================
BACKEND TESTS — EARNINGS SUMMARY
======================================================================

Test:

single currency
multiple currencies remain separate
gross
fee
refunds
net ledger
reserved payout
paid payout
available balance
negative available balance.

======================================================================
BACKEND TESTS — PAYOUT REQUEST
======================================================================

Test:

valid request
amount integer only
currency normalization
amount <= available
amount > available rejected
zero rejected
negative rejected
negative balance rejected
same key replay
same key conflict
active payout conflict
duplicate-active race safe
customer/admin cannot cleaner-create
body cannot override cleaner id.

======================================================================
BACKEND TESTS — PAYOUT LIFECYCLE
======================================================================

Cleaner:

cancel requested
foreign hidden
processing cannot cancel

Admin:

list
default requested
filters
detail
process
reject
reason validation
customer/cleaner cannot admin operations

Provider:

sandbox dev/test allowed
production unavailable
provider id opaque
processing state.

======================================================================
BACKEND TESTS — PAYOUT WEBHOOK
======================================================================

Mandatory:

valid signature
missing signature
invalid signature
constant-time comparison
paid transition
failed transition
amount mismatch
currency mismatch
duplicate event
same event id/different payload conflict
stale failure after paid cannot downgrade
stale paid after failed cannot resurrect
event processing status
raw signature not persisted.

======================================================================
BACKEND TESTS — PAYOUT BALANCE RESERVATION
======================================================================

Test:

requested subtracts available
processing subtracts available
paid subtracts available
failed releases
cancelled releases
rejected releases
one active payout protects concurrent drain.

======================================================================
BACKEND TESTS — RECONCILIATION
======================================================================

Test:

healthy completed/paid booking no issue
missing earning detected
refund mismatch detected
correct refund ledger no issue
multiple currencies
cursor/limit if implemented
safe summaries only.

======================================================================
BACKEND REGRESSION — PAYMENT / BOOKING
======================================================================

Ensure:

booking completion still works
payment webhook still secure
refund behavior unchanged
booking cancellation/refund orchestration unchanged
earning side-effect failure does not corrupt primary transition
notification/audit regression green.

======================================================================
FLUTTER FINANCIAL MODELS
======================================================================

Create:

CleanerCurrencyEarningsSummary
EarningsLedgerEntry
EarningsEntryType
PayoutStatus
CleanerPayout
AdminPayoutSummary
AdminPayoutDetail
AdminFinanceCurrencySummary
FinanceReconciliationIssue

Unknown enum:

safe fallback/unsupported handling.

Money stays integer minor units.

======================================================================
FLUTTER CLEANER EARNINGS API
======================================================================

Use authenticated Dio.

Operations:

getSummary
getLedger
listPayouts
getPayout
requestPayout
cancelPayout

Payout request sends:

Idempotency-Key

At least 128 bits from:

Random.secure()

One logical request keeps same key across network/auth retry.

New explicit payout request:

new key.

======================================================================
CLEANER EARNINGS CONTROLLER
======================================================================

Create focused Riverpod controller/state.

Support:

summary
selected currency
ledger first page/load more
payout history
request payout
cancel payout
safe errors.

Do not add financial state into AuthController.

======================================================================
CLEANER HOME
======================================================================

Approved or historically earning cleaner should have:

Earnings & Payouts

Do not hide historical finance merely because onboarding later changes.

Backend remains authoritative.

======================================================================
CLEANER EARNINGS SCREEN
======================================================================

Route:

/cleaner/earnings

Create:

CleanerEarningsScreen

Show per selected currency:

Gross service value
Platform fees
Refund adjustments
Net earnings ledger
Reserved payouts
Paid out
Available balance

Important:

Do not call gross:

income received.

Do not call platform fee:

profit.

Display money as existing technical minor-unit convention unless currency
metadata has since been implemented.

Example:

BDT 250000 minor units

No global divide-by-100 assumption.

======================================================================
EARNINGS LEDGER UI
======================================================================

Within earnings experience or separate route:

/cleaner/earnings/ledger

Show:

service earning
refund adjustment
amount
currency
booking reference
date

Refund entries visually indicate negative amount.

Load More.

No private customer/payment-provider information.

======================================================================
PAYOUT REQUEST UI
======================================================================

Route:

/cleaner/payouts/request

Fields:

Currency
Amount in minor units

Display:

available balance

Explain:

"No bank or wallet destination is collected yet. This project currently uses
a development payout workflow."

Do not create fake bank form.

Final:

Request Payout

Disable duplicate taps.

======================================================================
PAYOUT HISTORY UI
======================================================================

Route:

/cleaner/payouts

Show:

amount
currency
status
attempt
requested date
paid/failed/rejected state

If requested:

Cancel Request

If rejected:

safe rejection reason.

Do not show processed_by admin id unless useful; preferred omit.

======================================================================
ADMIN PAYOUT FLUTTER API
======================================================================

Operations:

listPayouts
getPayout
process
reject
simulateSuccess
simulateFailure

Simulation controls shown only when backend says:

simulation_available == true.

======================================================================
ADMIN PAYOUT CONTROLLER
======================================================================

Focused Riverpod.

Support:

list/filter/pagination
detail
process
reject
sandbox simulation
safe error.

======================================================================
ADMIN HOME
======================================================================

Add:

Payouts

Finance

Keep existing:

Disputes
Users
Bookings
Payments
Reviews
Audit Log.

======================================================================
ADMIN PAYOUT LIST SCREEN
======================================================================

Route:

/admin/payouts

Default:

Requested

Filters:

status
currency

Show:

cleaner
amount
currency
status
requested date.

Load More.

======================================================================
ADMIN PAYOUT DETAIL SCREEN
======================================================================

Route:

/admin/payouts/:payoutId

Show:

safe payout details
cleaner
amount
status
attempt
available/financial summary
timestamps
provider-event summaries if safe

Requested actions:

Process
Reject

Reject requires reason.

Processing result:

Development Sandbox controls only if API says available:

Simulate Success
Simulate Failure

Clearly label:

Development Sandbox

Do not make it look like a bank transfer.

======================================================================
ADMIN FINANCE SCREEN
======================================================================

Route:

/admin/finance

Show per currency:

gross service volume
platform fees
cleaner net earnings
refunds
payout requested
payout processing
payout paid
payout failed

Allow:

date range
currency filter

No cross-currency total.

Add:

Reconciliation Issues

navigation/section.

======================================================================
ADMIN RECONCILIATION UI
======================================================================

Route:

/admin/finance/reconciliation

Read-only.

Display:

issue type
booking/payment reference
currency
safe explanation

No repair button in TASK 019.

Do not automatically mutate financial records.

======================================================================
ADMIN CLEANER FINANCE LINK
======================================================================

From Admin User Detail for cleaner:

View Financial Summary

Route conceptually:

/admin/users/:userId/finance

or another clear route.

Use backend cleaner finance endpoint.

Read-only.

======================================================================
FLUTTER NOTIFICATION INTEGRATION
======================================================================

Extend NotificationType for payout events.

Resource mapping:

payout
→ cleaner payout detail/history as appropriate.

Do not trust arbitrary server URLs.

======================================================================
FLUTTER ERROR MAPPING
======================================================================

Map:

insufficient_payout_balance
payout_already_active
payout_not_found
invalid_payout_state
payout_provider_unavailable
invalid_payout_amount
invalid_payout_currency
payout_integrity_mismatch
payout_webhook_event_conflict
invalid_payout_rejection_reason

Never show:

DioException.toString()
raw Mongo duplicate error
HMAC secret/signature
stack trace.

======================================================================
FLUTTER TESTS — CLEANER EARNINGS
======================================================================

Models/API:

summary parse
multiple currencies
ledger
negative adjustment
payout history
safe errors

Controller:

load summary
select currency
ledger pagination
payout history
request
duplicate submit guard
cancel
safe errors.

Widgets:

earnings home entry
summary values
negative balance
multiple currencies
ledger
refund adjustment
no fake currency conversion.

======================================================================
FLUTTER TESTS — PAYOUT REQUEST
======================================================================

Test:

available balance displayed
amount validation
currency validation
Idempotency-Key sent
auth refresh retains key
request success
insufficient balance
active payout error
cancel
rejection reason
no bank/card form.

======================================================================
FLUTTER TESTS — ADMIN PAYOUT
======================================================================

Controller/API:

list
filter
pagination
detail
process
reject
sandbox success
sandbox failure

Widgets:

Admin home Payouts
list
detail
Process
Reject dialog
sandbox label
simulate buttons only when available
no real bank-transfer claim.

======================================================================
FLUTTER TESTS — ADMIN FINANCE
======================================================================

Test:

finance summary
multiple currencies separated
date filter
reconciliation list
clean state
missing earning issue
refund mismatch issue
cleaner finance detail.

======================================================================
FLUTTER ROUTER TESTS
======================================================================

Cleaner:

earnings
ledger
payout history
request payout

allowed.

Customer:

redirected from cleaner finance.

Admin:

payouts
finance
reconciliation
cleaner finance

allowed.

Customer/cleaner:

admin finance routes forbidden through UX guards.

Admin:

cleaner payout-request routes redirected admin home.

Auth expiry:

login.

Previous routes remain green.

======================================================================
SECURITY AUDIT
======================================================================

EARNINGS

Confirm:

- payment/booking amount server-derived;
- no client commission;
- original commission snapshotted;
- refund adjustment uses original commission;
- append-only ledger;
- duplicate source event cannot duplicate earning/refund;
- multiple currencies never summed together.

PAYOUTS

Confirm:

- cleaner identity from auth;
- body cannot choose cleaner id;
- amount cannot exceed available balance;
- active-payout unique reservation;
- idempotent request;
- admin processing/rejection persisted-role protected;
- provider amount/currency backend-owned;
- sandbox forbidden production;
- HMAC payout webhook;
- constant-time compare;
- provider event replay protected;
- no bank/card/wallet secret stored.

FLUTTER

Confirm:

- no payout webhook secret;
- no Mongo URI;
- no backend signing secret;
- no bank/card field;
- existing authenticated Dio reused;
- no new auth stack.

GLOBAL

Confirm:

- `.env` ignored;
- existing auth/payment/booking security regressions green;
- no raw financial/provider errors exposed.

======================================================================
DOCUMENTATION — DATABASE
======================================================================

Create:

documentation/database/earnings-ledger-collection.md

documentation/database/payout-requests-collection.md

documentation/database/payout-provider-events-collection.md

Document:

fields
append-only ledger
commission math
refund adjustments
negative balances
balance formula
payout reservation
statuses
indexes
webhook events
privacy
sandbox limitation.

======================================================================
DOCUMENTATION — API
======================================================================

Create:

documentation/api/earnings-and-payout-api.md

Document:

cleaner earnings
ledger
payouts
admin payouts
finance
reconciliation
dev simulation
webhook

with fake examples only.

======================================================================
DOCUMENTATION — ARCHITECTURE
======================================================================

Create:

documentation/architecture/earnings-payouts-and-reconciliation.md

Document flows:

COMPLETION / PAYMENT

booking completed
+
payment successful
→ idempotent earning creation

REFUND

provider refund event
→ payment transition
→ refund adjustment using original commission

PAYOUT

cleaner balance
→ request
→ reservation
→ admin process
→ provider
→ signed webhook
→ paid/failed

RECONCILIATION

booking/payment truth
↔ earnings ledger
→ detect missing/mismatched accounting

Explain:

- payment remains payment source of truth;
- earnings ledger is append-only accounting projection;
- no real payout provider;
- no bank destination;
- no cross-currency conversion;
- no exactly-once distributed transaction claim.

======================================================================
ADR-017
======================================================================

Create:

documentation/decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md

Required:

# ADR-017 — Cleaner Earnings, Payout Requests, and Financial Reconciliation

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Security
## Deferred Decisions

Decision covers:

- append-only earnings ledger;
- completed + successful-payment eligibility;
- commission basis-point snapshot;
- integer fee math;
- refund adjustment entries;
- original commission used for refund allocation;
- negative balances;
- per-currency accounting;
- one active payout per cleaner;
- payout request idempotency;
- provider-neutral payout interface;
- dev/test sandbox only;
- signed payout webhook;
- payout event replay protection;
- admin processing/rejection;
- reconciliation detection.

Alternatives:

### Recalculate earnings from current booking/payment every request
Rejected because historical commission/refund accounting would not be stable.

### Store cleaner balance directly on cleaner_profiles
Rejected because mutable aggregate can drift and loses accounting history.

### Clamp negative balances to zero
Rejected because post-payout refunds create a real future offset obligation.

### Use floating-point money
Rejected.

### Combine all currencies
Rejected without exchange-rate infrastructure.

### Let cleaner directly trigger provider payout
Rejected; admin processing remains explicit in current operational model.

### Store bank details now
Deferred because no real payout provider/KYC system exists.

### Directly mutate payout from sandbox simulation
Rejected; simulator must use signed webhook path.

### Automatically repair reconciliation issues
Deferred because financial repair should be deliberate/auditable.

Deferred:

real payout provider
bank/wallet destination
KYC
tax
scheduled payouts
payout fees
currency conversion
chargebacks
automated reconciliation repair
accounting export.

======================================================================
DOCUMENTATION INDEX UPDATES
======================================================================

Update as necessary:

documentation/README.md
documentation/api/README.md
documentation/database/README.md
documentation/architecture/README.md
documentation/decisions/README.md

documentation/architecture/payment-processing-and-webhooks.md
documentation/architecture/booking-reservation-and-lifecycle.md
documentation/architecture/disputes-admin-operations-and-audit.md

backend/README.md
project/README.md
README.md

Do not claim:

real payouts
bank integration
KYC
tax
currency conversion

exist.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From repository root:

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

working tree:
clean

latest commit:
TASK 018 checkpoint

Verify:

documentation/cursor/018_disputes_admin_operations_and_audit.md

Status:
SUCCESS

Verify:

backend/.env ignored.

If tree is not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend:

dart pub get
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Expected:

443 passed
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

324 passed

If not:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new direct dependency.

If genuinely required:

STOP before adding.

======================================================================
STEP 5 — COMMISSION CONFIGURATION / DOMAIN

Implement:

PLATFORM_COMMISSION_BPS
validation
integer fee calculation
tests.

======================================================================
STEP 6 — EARNINGS DOMAIN / LEDGER

Implement:

EarningsLedgerEntry
EarningsEntryType
repository
indexes
safe DTOs
summary aggregation.

Append-only.

Tests.

======================================================================
STEP 7 — EARNINGS SETTLEMENT

Implement:

EarningsSettlementService

completion/payment trigger integration
refund adjustment integration
idempotency
negative balance behavior.

Comprehensive tests.

======================================================================
STEP 8 — PAYOUT DOMAIN / REPOSITORY

Implement:

PayoutRequest
PayoutStatus
validation
idempotency
active reservation
repository
indexes.

Tests.

======================================================================
STEP 9 — PAYOUT PROVIDER / WEBHOOK

Implement:

PayoutProvider
SandboxPayoutProvider
HMAC
provider events
webhook service
dev simulator

Production sandbox prohibition.

Tests.

======================================================================
STEP 10 — CLEANER PAYOUT SERVICE

Implement:

summary
ledger
list
get
request
cancel.

Tests.

======================================================================
STEP 11 — ADMIN PAYOUT / FINANCE SERVICES

Implement:

AdminPayoutService
AdminFinanceService
reconciliation detection.

Tests.

======================================================================
STEP 12 — AUDIT / NOTIFICATION INTEGRATION

Extend:

AuditAction
NotificationType

for payout workflow.

Do not weaken best-effort semantics.

Tests.

======================================================================
STEP 13 — BACKEND ROUTES

Implement:

cleaner earnings/payout routes
admin payout routes
admin finance routes
payout webhook
development simulator.

Thin handlers.

======================================================================
STEP 14 — BACKEND PRE-LIVE VERIFICATION

Run:

dart format .
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

All green.

Record exact test count/routes.

======================================================================
STEP 15 — LIVE INDEX ENSURE

Run controlled index tool.

Only index metadata mutation.

Verify TASK 019 index metadata including partial indexes.

No earnings/payout application documents.

======================================================================
STEP 16 — FLUTTER DATA / API

Implement:

earnings
payout
admin payout
finance
reconciliation

models/APIs.

Authenticated Dio only.

======================================================================
STEP 17 — FLUTTER STATE

Implement focused Riverpod controllers.

======================================================================
STEP 18 — FLUTTER ROUTING

Add cleaner/admin financial routes.

Preserve existing role/auth guards.

======================================================================
STEP 19 — CLEANER FINANCE UI

Implement:

CleanerEarningsScreen
ledger
Payout History
Payout Request

No bank/card form.

======================================================================
STEP 20 — ADMIN FINANCE UI

Implement:

AdminPayoutListScreen
AdminPayoutDetailScreen
AdminFinanceScreen
AdminFinanceReconciliationScreen
cleaner finance detail.

======================================================================
STEP 21 — FLUTTER TESTS

Add comprehensive:

models
API
controller
router
widget

tests.

Then:

dart format lib test
flutter analyze
flutter test

All green.

Record exact count.

======================================================================
STEP 22 — ANDROID DEBUG BUILD

Run:

flutter build apk --debug

Must succeed.

Do not alter release signing/network security.

======================================================================
STEP 23 — SAFE LIVE BACKEND VERIFICATION

Only:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Expected 200.

Do NOT call:

earnings
payout
finance
reconciliation
payout webhook
sandbox payout simulate

against live Atlas.

======================================================================
STEP 24 — SECURITY / FINANCIAL AUDIT

Perform all TASK 019 security/accounting checks.

Regression verify TASK 012–018 remains green.

======================================================================
STEP 25 — DOCUMENTATION

Create:

documentation/database/earnings-ledger-collection.md
documentation/database/payout-requests-collection.md
documentation/database/payout-provider-events-collection.md

documentation/api/earnings-and-payout-api.md

documentation/architecture/earnings-payouts-and-reconciliation.md

documentation/decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md

Update documentation indexes/READMEs.

======================================================================
STEP 26 — FINAL BACKEND VERIFICATION

Run:

dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Record exact count/routes.

======================================================================
STEP 27 — FINAL FLUTTER VERIFICATION

Run:

flutter analyze
flutter test
flutter build apk --debug

Record exact count.

======================================================================
STEP 28 — FINAL GIT REVIEW

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

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET
password
JWT
refresh token
bank data
card data
private Atlas data
APK
build directory
SDK artifact
project/devtools_options.yaml
temporary prompt file
unrelated generated file

is tracked.

Remove unrelated generated tooling/temp files before final report.

Do NOT stage.

======================================================================
STEP 29 — TASK REPORT

Create:

documentation/cursor/019_cleaner_earnings_payouts_and_reconciliation.md

Use existing task-report template.

The report MUST contain the COMPLETE EXACT TASK 019 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 018 checkpoint;
- baseline counts;
- dependencies;
- commission config;
- commission integer math;
- earnings ledger schema;
- service earning eligibility;
- dual trigger;
- earning idempotency;
- refund adjustments;
- original commission snapshot;
- negative balances;
- per-currency summary;
- payout balance formula;
- payout schema;
- payout lifecycle;
- active reservation;
- payout idempotency;
- provider boundary;
- sandbox restriction;
- HMAC webhook;
- provider event replay;
- admin process/reject;
- payout notifications/audit;
- reconciliation;
- indexes/live ensure;
- backend routes/tests;
- Flutter APIs/controllers;
- cleaner earnings UI;
- payout UI;
- admin payout UI;
- finance/reconciliation UI;
- Flutter tests;
- APK;
- safe live checks;
- security/financial audit;
- live data safety;
- files;
- warnings;
- final Git status.

Never include:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET
passwords
JWTs
refresh tokens
bank data
card data
real financial records
private Atlas records.

======================================================================
STEP 30 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave TASK 019 completely uncommitted for ChatGPT review.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 019 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## Commission Configuration

## Earnings Ledger

## Earnings Eligibility

## Earnings Idempotency

## Refund Adjustments

## Negative Balance Handling

## Earnings Summary

## Payout Model

## Payout Balance Reservation

## Payout Idempotency

## Payout Lifecycle

## Payout Provider Boundary

## Sandbox Payout Provider

## Payout Webhook Authentication

## Payout Webhook Idempotency

## Cleaner Earnings API

## Cleaner Payout API

## Admin Payout Operations

## Admin Finance Summary

## Financial Reconciliation

## Notifications and Audit

## MongoDB Indexes

## Backend Tests

## Backend Routes

## Flutter Cleaner Earnings Experience

## Flutter Cleaner Payout Experience

## Flutter Admin Payout Experience

## Flutter Admin Finance Experience

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

## Security and Financial Integrity Verification

## Git Status

## Issues / Warnings

## Final Statement

State whether cleaner earnings + commission accounting + refund adjustments +
payout requests + sandbox payout settlement + admin financial reconciliation
are complete and ready for ChatGPT review.

Do NOT integrate a real payout provider.

Do NOT store bank/card information.

Do NOT implement tax.

Do NOT implement password recovery.

Do NOT begin TASK 020.

Start TASK 019 now.
~~~~

## Pre-Task Repository State

- Root: D:/freelance/erfankhan_cse489/final
- Branch: main
- Working tree: clean at TASK 018 checkpoint 67e242a (disputes_admin_operations_and_audit)
- documentation/cursor/018_disputes_admin_operations_and_audit.md Status: SUCCESS
- `backend/.env` gitignored
- Backend baseline: dart analyze clean; dart test 443 passed
- Flutter baseline: flutter analyze clean; flutter test 324 passed
- No new direct pub dependencies; dart pub upgrade / flutter pub upgrade not run

## Work Performed

Implemented TASK 019 backend earnings/payout/finance domain, repositories, services, routes, indexes, and tests; Flutter models, APIs, Riverpod controllers, cleaner/admin screens, routing, and tests; documentation including ADR-017. Live Atlas mutated only via controlled index ensure. Sandbox payout simulation was not run against live application records.

## Files Created

See git status in the TASK 019 result. Principal new areas: backend lib/src/features/earnings, payouts, finance; Flutter lib/features/earnings and admin payout/finance screens; documentation database/API/architecture/ADR-017/task report.

## Files Modified

Existing config, collection names, index tool, booking/payment settlement hooks, notifications, audit actions, Flutter router/home/error mapping, and documentation indexes/READMEs.

## Files Deleted

None.

## Commands Executed

- git rev-parse / branch / status / log (STEP 1)
- backend: dart pub get, dart analyze, dart test, dart pub global run dart_frog_cli:dart_frog list (baseline and final)
- project: flutter pub get, flutter analyze, flutter test (baseline and final)
- dart format lib test routes tool
- dart run tool/ensure_database_indexes.dart
- flutter build apk --debug
- dart pub global run dart_frog_cli:dart_frog build
- GET http://127.0.0.1:8099/ /api/v1/health /api/v1/ready /api/v1/services
- git check-ignore -v backend/.env
- git diff --check
- git status --short

## Implementation Details

Commission: integer 0-10000 bps; default 1500 when unset (documented for production to set explicitly). Fee math: (gross * bps + 5000) ~/ 10000.

Earnings: append-only earnings_ledger. Unique source_event_key. Dual trigger via EarningsSettlementService.ensureBookingEarning from cleaner complete and payment paid. try* wrappers log and do not undo primary writes.

Refund adjustments use original earning commission_bps. Catch-up key `refund:catchup:payment:<id>`. Event key `refund:<provider>:<eventId>`. Negative balances allowed.

Payout: one active per cleaner (payout_active partial unique). Idempotency-Key 16-128 ASCII. attempt_number = max for cleaner + 1 (all currencies). Sandbox only when APP_ENV development or test. HMAC X-Sandbox-Payout-Signature. Dev simulate signs webhook and uses PayoutWebhookService.

Reconciliation: read-only GET. Issue types missing_service_earning and refund_adjustment_mismatch.

Flutter: focused controllers; authenticated Dio; Idempotency-Key from Random.secure(); sandbox buttons only when simulation_available.

## Technical Decisions

- Snapshot commission rather than recalculate.
- Ledger not a balance field on cleaner_profiles.
- Negative balances not clamped.
- Integer money only.
- Per-currency summaries.
- Admin processes provider payout; cleaner cannot.
- No bank destination storage.
- Simulator uses signed webhook path.
- No auto-repair of reconciliation issues.

## Verification Performed

Backend analyze/test/routes; Flutter analyze/test/APK; controlled index ensure including partial unique payout_active; safe live GET on TASK 019 production build port 8099; security/accounting review against TASK 019 checklist; git ignore of backend/.env.

## Verification Results

- Backend dart analyze: no issues
- Backend dart test: 483 passed
- Dart Frog route list includes cleaner earnings/payouts, admin payouts/finance/reconciliation/cleaner finance, sandbox payout webhook, dev payout simulate
- Flutter flutter analyze: no issues
- Flutter flutter test: 349 passed
- flutter build apk --debug: success (project/build/app/outputs/flutter-apk/app-debug.apk, untracked)
- Index ensure: TASK 019 indexes exist including earnings_ledger_source_event_unique, payout_requests_cleaner_active_unique (partial payout_active=true), payout_events_provider_event_unique
- Live GET: 200 for /, /api/v1/health, /api/v1/ready, /api/v1/services on port 8099
- git check-ignore -v backend/.env -> .gitignore:8:.env

## Errors / Warnings

- Direct dart_frog is not on PATH. Use dart pub global run dart_frog_cli:dart_frog list.
- Non-TTY dart_frog dev StdinException remains; production-build fallback on port 8099 used for safe GETs.
- Port 8098 was already occupied by a leftover process; TASK 019 verification used 8099.
- git diff --check may report LF/CRLF working-copy warnings on Windows; no conflict-marker errors.
- Earnings settlement failure is logged for reconciliation; primary booking/payment is not rolled back. Not exactly-once distributed accounting.

## Security / Secrets Check

No secrets committed. backend/.env ignored. No passwords, JWTs, refresh tokens, Mongo URI, webhook secrets, bank/card data, or live earnings/payout records in docs or tests. Flutter has no payout webhook secret. Commission is not a secret and is not accepted from Flutter.

## Git Diff Summary

Uncommitted TASK 019 implementation across backend earnings/payouts/finance, Flutter UIs/controllers/tests, and documentation. No APK, build directory, .env, or devtools_options.yaml should be tracked.

## Final Repository State

Branch main, dirty working tree, unstaged, uncommitted. Ready for ChatGPT review. TASK 020 not started.

## Unresolved Issues

None blocking TASK 019. Deferred: real payout provider, bank/wallet destination, KYC, tax, scheduled payouts, payout fees, currency conversion, chargebacks, automated reconciliation repair, accounting export.

## Suggested Next Step

ChatGPT review of uncommitted TASK 019. Do not begin TASK 020 from this report.

## Checkpoint

TASK 018 commit 67e242a on clean main before implementation.

## Baselines

Backend 443 tests / analyze clean. Flutter 324 tests / analyze clean. No new direct dependencies.
