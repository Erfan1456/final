# Payments Collection

This document describes the `payments` collection.

TASK 016 stores an authoritative **payment ledger**. A booking may have multiple historical payment attempts. Only one non-terminal attempt may be active at a time. One successful paid payment is allowed per booking. The collection is the source of truth for payment state. Booking `confirmed` or `completed` does not prove payment.

TASK 016 does **not** configure a production payment processor. The only implemented provider is the development/test **sandbox**. It exercises state machines, webhooks, idempotency, retries, refunds, and UI. It does not charge real money and must never be enabled in production.

## Purpose

One document is one payment attempt for one booking, derived from the booking's immutable quote:

```text
payments.amount_minor = booking.quoted_total_minor
payments.currency_code = booking.currency_code
```

Flutter never supplies amount, currency, customer, cleaner, or booking status. The backend derives those from the owned confirmed booking.

## Document shape

```text
_id                      ObjectId
booking_id               ObjectId
customer_user_id         ObjectId
cleaner_user_id          ObjectId
provider                 String     (PaymentProviderType; TASK 016: sandbox)
status                   String     (PaymentStatus wire value)
amount_minor             int
currency_code            String
provider_payment_id      String?
provider_reference       String?
attempt_number           int
client_idempotency_key   String
request_fingerprint      String     (SHA-256 lowercase hex)
failure_code             String?
failure_message          String?
payment_active           bool
settlement_recorded      bool
authorized_at            DateTime?
paid_at                  DateTime?
failed_at                DateTime?
cancelled_at             DateTime?
refunded_at              DateTime?
refunded_amount_minor    int
created_at               DateTime   (UTC)
updated_at               DateTime   (UTC)
```

All persisted DateTimes are UTC.

## Forbidden fields

Do not store card number, CVV, expiry, bank password, mobile-wallet PIN, JWT, refresh token, Mongo URI, `ACCESS_TOKEN_SECRET`, raw provider secret, or raw webhook secret.

## Status enum

Wire values: `pending`, `authorized`, `paid`, `failed`, `cancelled`, `partially_refunded`, `refunded`.

`payment_active` occupies the partial unique active slot (`pending`/`authorized`). `settlement_recorded` occupies the partial unique successful-payment slot (`paid`/`partially_refunded`/`refunded`). Both flags update in the same atomic payment write as `status`.

Terminal for a charge attempt: `paid`, `failed`, `cancelled`, `refunded`. `partially_refunded` is tied to a successful paid transaction and blocks another full charge.

## Eligibility

A customer may start payment only when the booking is `confirmed`. Other booking statuses return `409 booking_not_payable`.

Retry is allowed after `failed` or `cancelled` when the booking is still confirmed and no active/settled payment blocks a new attempt. A retry creates a new document with `attempt_number = previous max + 1` and requires a new `Idempotency-Key`.

## Idempotency

Customer start requires `Idempotency-Key` (same 16–128 ASCII rules as bookings; trimmed; not lowercased). Fingerprint is SHA-256 of `[customer_user_id, booking_id]`. Unique index `payments_customer_idempotency_unique` on `(customer_user_id, client_idempotency_key)`. Same key + same fingerprint returns the existing attempt. Same key + different booking is `409 idempotency_key_reused`.

## Indexes

| name | keys | unique | partial |
| --- | --- | --- | --- |
| `payments_provider_payment_id_unique` | `provider`, `provider_payment_id` | yes | `provider_payment_id` is string |
| `payments_customer_idempotency_unique` | `customer_user_id`, `client_idempotency_key` | yes | |
| `payments_booking_attempt_unique` | `booking_id`, `attempt_number` | yes | |
| `payments_booking_id_desc` | `booking_id`, `_id` desc | no | |
| `payments_customer_id_desc` | `customer_user_id`, `_id` desc | no | |
| `payments_status_id_desc` | `status`, `_id` desc | no | |
| `payments_booking_active_unique` | `booking_id` | yes | `payment_active == true` |
| `payments_booking_settlement_unique` | `booking_id` | yes | `settlement_recorded == true` |

Active uniqueness uses `payment_active` rather than a `$in` status partial filter, matching the existing `reservation_active` Atlas pattern.

## Booking cache

TASK 016 does **not** cache payment status on the booking document and does not use Mongo multi-document transactions. Payment documents are authoritative. Flutter loads booking-associated payment separately.

## Security

Public JSON omits `client_idempotency_key`, `request_fingerprint`, webhook secrets, signatures, and raw provider payloads. `toString` never prints secrets.
