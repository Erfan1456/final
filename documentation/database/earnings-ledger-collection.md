# Earnings Ledger Collection

This document describes the `earnings_ledger` collection.

TASK 019 stores an **append-only cleaner earnings ledger**. Payment remains the financial source of truth for charges and refunds. The ledger is an accounting projection: original service earnings plus refund adjustments. Documents are never updated or deleted.

This is **not** a bank statement and does **not** mean money was transferred to a cleaner.

## Purpose

One document is one ledger entry for one cleaner, derived from a completed booking and its authoritative successful payment.

Original earning amounts:

```text
gross_amount_minor = payment.amount_minor
currency_code = payment.currency_code
```

Flutter never supplies amount, currency, or commission. `PLATFORM_COMMISSION_BPS` is snapshotted at earning creation. Existing rows are not recalculated when configuration later changes.

## Document shape

```text
_id                      ObjectId
cleaner_user_id          ObjectId
booking_id               ObjectId
payment_id               ObjectId
entry_type               String     (EarningsEntryType wire value)
gross_amount_minor       int
commission_bps           int
platform_fee_minor       int
cleaner_amount_minor     int
currency_code            String
source_event_key         String
created_at               DateTime   (UTC)
```

All persisted DateTimes are UTC.

## Forbidden fields

Do not store bank account, routing number, card, CVV, wallet PIN, JWT, refresh token, Mongo URI, webhook secrets, or signatures.

## Entry types

Wire values: `service_earning`, `refund_adjustment`.

| type | `cleaner_amount_minor` |
| --- | --- |
| `service_earning` | positive |
| `refund_adjustment` | negative |

TASK 019 does not create `manual_adjustment`. Administrators cannot arbitrarily alter cleaner balance.

## Commission integer math

Never use `double` for money.

```text
platform_fee_minor = (gross * commission_bps + 5000) ~/ 10000
cleaner_net_minor  = gross - platform_fee_minor
```

Round-half-up for the fee. Net is always gross minus fee.

## Eligibility

One `service_earning` is created only when **both** are true:

* `booking.status == completed`
* a successful payment exists (`paid`, `partially_refunded`, or `refunded`)

Preferred creation order: original full earning from `payment.amount_minor`, then refund-adjustment entries for already-applied refunds. Do not collapse refunds into a reduced original earning.

## Source-event uniqueness

`source_event_key` is the uniqueness identity.

* Original earning: `earning:booking:<bookingId>`
* Provider refund: `refund:<provider>:<providerEventId>`
* Catch-up after earning creation: `refund:catchup:payment:<paymentId>`

Unique index `earnings_ledger_source_event_unique` is the correctness mechanism. Duplicate webhook delivery must not duplicate ledger rows.

## Refund adjustments

Refund allocation uses the **original earning** `commission_bps`, not current configuration.

```text
platform_fee_refund_minor = (refund_delta_minor * commission_bps + 5000) ~/ 10000
cleaner_refund_minor      = refund_delta_minor - platform_fee_refund_minor

gross_amount_minor     = -refund_delta_minor
platform_fee_minor     = -platform_fee_refund_minor
cleaner_amount_minor   = -cleaner_refund_minor
```

The sum of refund-adjustment gross amounts must not exceed the original paid amount. Payment webhook integrity remains authoritative.

## Negative balances

Cleaner ledger totals **may** become negative (for example payout already paid, then an administrator refunds a completed booking). Do not clamp to zero. Future earnings offset the deficit before another payout can be requested.

## Per-currency accounting

Do not sum different `currency_code` values. There is no exchange-rate conversion.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `earnings_ledger_source_event_unique` | `source_event_key` | yes |
| `earnings_ledger_cleaner_currency_id_desc` | `cleaner_user_id`, `currency_code`, `_id` desc | no |
| `earnings_ledger_booking_type` | `booking_id`, `entry_type` | no |
| `earnings_ledger_created_at` | `created_at` desc, `_id` desc | no |

`earnings_ledger_created_at` is kept for admin date-range scans. Cleaner listing uses cleaner + currency + `_id`. Booking + type is narrower than a booking-only index for earning/refund lookup.

## Privacy

Client DTOs omit `source_event_key`. Ledger APIs never expose payment-provider secrets, customer PII beyond booking id, or Mongo internals.
