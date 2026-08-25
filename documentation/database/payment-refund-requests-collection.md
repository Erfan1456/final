# Payment Refund Requests Collection

This document describes the `payment_refund_requests` collection.

TASK 016 records **idempotent admin refund commands**. Provider webhooks determine the payment's refunded/partially_refunded state. This collection prevents issuing the provider refund twice after a network retry.

## Purpose

One document is one admin refund command for one payment. Uniqueness is `(admin_user_id, idempotency_key)`.

## Document shape

```text
_id                    ObjectId
payment_id             ObjectId
admin_user_id          ObjectId
idempotency_key        String
amount_minor           int
reason                 String
request_fingerprint    String     (SHA-256 of payment id, amount, reason)
status                 String     (pending | succeeded | failed)
created_at             DateTime   (UTC)
updated_at             DateTime   (UTC)
```

Reason is required, 5–500 Unicode code points, trimmed plain text, no controls. Amount omitted means remaining refundable (`amount_minor - refunded_amount_minor`). Validated range: `1 <= amount <= remaining`.

Only `paid` and `partially_refunded` payments may refund.

Same key + same fingerprint returns the existing result without a second provider refund. Same key + different intent is `409 idempotency_key_reused`. Replay lookup happens **before** remaining-amount checks so a successful full refund can be retried with the original omitted amount.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `payment_refund_admin_idempotency_unique` | `admin_user_id`, `idempotency_key` | yes |
| `payment_refund_payment_created` | `payment_id`, `created_at` desc | no |

## Forbidden fields

Do not store card data, webhook secrets, JWTs, or raw provider responses.
