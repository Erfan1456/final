# Payment Webhook Events Collection

This document describes the `payment_webhook_events` collection.

TASK 016 records **approved metadata** for provider webhook deliveries so replay and conflict detection are durable. The collection does not store raw webhook secrets, signatures, or the full raw payload.

## Purpose

Each document is one provider event receipt identified by `(provider, provider_event_id)`. The unique index is the correctness mechanism for concurrent duplicate delivery. Application code also pre-reads the existing event so identical replays acknowledge without a second insert.

## Document shape

```text
_id                   ObjectId
provider              String
provider_event_id     String
event_type            String
provider_payment_id   String
payload_sha256        String     (SHA-256 of exact raw body bytes, lowercase hex)
processing_status     String     (received | processed | ignored | failed)
processed_at          DateTime?
created_at            DateTime   (UTC)
```

## Processing status

| status | meaning |
| --- | --- |
| `received` | Event accepted and not yet applied |
| `processed` | Valid transition applied |
| `ignored` | Duplicate, stale, unknown payment, or non-applicable transition |
| `failed` | Integrity mismatch or apply error |

Identical already-processed/ignored events return a safe HTTP 200 acknowledgement. Same `provider_event_id` with a **different** `payload_sha256` is `409 webhook_event_conflict`.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `payment_webhook_events_provider_event_unique` | `provider`, `provider_event_id` | yes |
| `payment_webhook_events_payment_created` | `provider_payment_id`, `created_at` | no |

## Admin visibility

`GET /api/v1/admin/payments/{paymentId}/events` returns `provider_event_id`, `event_type`, `processing_status`, `processed_at`, and `created_at`. It does not return payload hash, signature, secret, or raw body.
