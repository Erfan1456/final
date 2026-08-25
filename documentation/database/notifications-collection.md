# Notifications Collection

This document describes the `notifications` collection.

TASK 017 stores a persistent in-app notification feed. There is no push provider, email, SMS, Firebase, or transactional outbox.

## Purpose

One document is one in-app notification for one user. Creation is idempotent on `(user_id, dedupe_key)`. Notification insert happens after a successful primary booking/payment/message/review mutation. Unexpected notification write failure does not roll back the primary operation.

Cross-collection exactly-once delivery is **not** guaranteed.

## Document shape

```text
_id              ObjectId
user_id          ObjectId
type             String     (NotificationType wire value)
title            String
body             String
resource_type    String?
resource_id      ObjectId?
dedupe_key       String
read_at          DateTime?
created_at       DateTime   (UTC)
```

## Types

Wire values: `booking_requested`, `booking_confirmed`, `booking_declined`, `booking_cancelled`, `job_started`, `job_completed`, `payment_paid`, `payment_failed`, `payment_refunded`, `message_received`, `review_received`.

## Privacy

Title/body must never contain a full service address, password/token, payment credentials, webhook payload, customer/cleaner phone, private email, or raw provider/Mongo errors. Generic copy is used (`New booking request`, `New message`, `Payment completed`).

Message notifications may include a safe body preview of at most 120 Unicode code points.

## Deduplication

Deterministic `dedupe_key` examples:

- `booking:<bookingId>:created|confirmed|declined|cancelled|started|completed`
- `message:<messageId>`
- `payment-event:<providerEventId>`
- `review:<reviewId>:created`

Duplicate creation is treated as already delivered. The unique index is authoritative.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `notifications_user_id_desc` | `user_id`, `_id` desc | no |
| `notifications_user_read_id_desc` | `user_id`, `read_at`, `_id` desc | no |
| `notifications_user_dedupe_unique` | `user_id`, `dedupe_key` | yes |

List pagination is `_id` descending keyset (`after`). No offset pagination.

## Security

HTTP never accepts `user_id` from the body. Ownership is the authenticated persisted user. Unknown or foreign mark-read is `404 notification_not_found`. `dedupe_key` is omitted from public JSON.
