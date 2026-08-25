# Payout Requests Collection

This document describes the `payout_requests` collection.

TASK 019 stores cleaner payout **requests** and their lifecycle. This is **not** a bank transfer ledger. There is no stored payout destination. The only provider is a development/test **sandbox**. Production must never silently enable sandbox payouts.

## Purpose

One document is one payout request for one cleaner and one currency. Amounts are integer minor units. Flutter never chooses `cleaner_user_id`.

## Document shape

```text
_id                      ObjectId
cleaner_user_id          ObjectId
amount_minor             int
currency_code            String
status                   String     (PayoutStatus wire value)
attempt_number           int
client_idempotency_key   String
request_fingerprint      String
payout_active            bool
provider                 String?
provider_payout_id       String?
requested_at             DateTime
processing_at            DateTime?
paid_at                  DateTime?
failed_at                DateTime?
cancelled_at             DateTime?
rejected_at              DateTime?
failure_code             String?
failure_message          String?
rejection_reason         String?
processed_by             ObjectId?
created_at               DateTime   (UTC)
updated_at               DateTime   (UTC)
```

## Forbidden fields

Do not store bank account, routing number, mobile-wallet PIN, card, CVV, password, JWT, refresh token, provider secret, or webhook signature.

## Status lifecycle

Wire values: `requested`, `processing`, `paid`, `failed`, `cancelled`, `rejected`.

```text
none → requested          (cleaner request)
requested → cancelled     (cleaner cancel)
requested → rejected      (admin reject)
requested → processing    (admin process)
processing → paid         (provider success webhook)
processing → failed       (provider failure webhook or provider-call failure)
```

Terminal: `paid`, `failed`, `cancelled`, `rejected`. Do not reopen a request. The cleaner creates a **new** request after failure, rejection, or cancellation.

`payout_active` is `true` for `requested` and `processing`, and `false` for terminal statuses. Status and `payout_active` update atomically.

## One active payout per cleaner

At most one request with `payout_active == true` per cleaner. Partial unique index `payout_requests_cleaner_active_unique` is the concurrency control. Duplicate-active races return `409 payout_already_active` without exposing Mongo details.

## Balance reservation

For one currency:

```text
net_ledger_minor        = sum cleaner_amount_minor (earnings_ledger)
reserved_payout_minor   = sum amount where status in requested, processing
paid_out_minor          = sum amount where status == paid
available_balance_minor = net_ledger_minor - reserved_payout_minor - paid_out_minor
```

Failed, cancelled, and rejected requests do **not** reduce available balance. Negative available balance is returned as-is. A new request requires `available_balance_minor > 0` and `amount_minor <= available_balance_minor`.

## Idempotency

Cleaner `POST` requires `Idempotency-Key` (16–128 ASCII, trim, no controls, not lowercased). Fingerprint is cleaner + amount + currency. Unique `(cleaner_user_id, client_idempotency_key)`. Same key + same fingerprint returns the existing request. Same key + different intent: `409 idempotency_key_reused`.

## Attempt number

`attempt_number` is the previous maximum for that **cleaner** (all currencies) + 1. It has no security meaning.

## Provider-call failure

Admin process transitions `requested` → `processing`, then calls `PayoutProvider.createPayout` with backend-owned amount/currency. If the provider call fails, the request should transition `processing` → `failed` with `payout_active = false` where possible so the reservation is released. Cross-system consistency is not an exactly-once distributed transaction.

## Indexes

| name | keys | unique | partial |
| --- | --- | --- | --- |
| `payout_requests_cleaner_idempotency_unique` | `cleaner_user_id`, `client_idempotency_key` | yes | |
| `payout_requests_cleaner_active_unique` | `cleaner_user_id` | yes | `payout_active == true` |
| `payout_requests_cleaner_id_desc` | `cleaner_user_id`, `_id` desc | no | |
| `payout_requests_status_id_desc` | `status`, `_id` desc | no | |
| `payout_requests_provider_payout_unique` | `provider`, `provider_payout_id` | yes | `provider_payout_id` is string |

## Privacy

Cleaner DTOs omit `processed_by`, `client_idempotency_key`, `request_fingerprint`, and provider webhook metadata. Safe rejection reason may be shown. Admin DTOs may include provider id and `simulation_available` when the backend explicitly allows sandbox simulation.
