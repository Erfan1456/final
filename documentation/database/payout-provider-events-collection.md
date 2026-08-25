# Payout Provider Events Collection

This document describes the `payout_provider_events` collection.

TASK 019 records **approved metadata** for payout provider webhook deliveries so replay and conflict detection are durable. The collection does not store raw webhook secrets, signatures, or the full raw payload.

The sandbox payout provider exists only to exercise payout state, idempotency, callbacks, HMAC authentication, replay handling, and reconciliation UI. It does not transfer real money.

## Purpose

Each document is one provider event receipt identified by `(provider, provider_event_id)`. The unique index is the correctness mechanism for concurrent duplicate delivery.

## Document shape

```text
_id                   ObjectId
provider              String
provider_event_id     String
event_type            String
provider_payout_id    String
payload_sha256        String     (SHA-256 of exact raw body bytes, lowercase hex)
processing_status     String     (received | processed | ignored | failed)
processed_at          DateTime?
created_at            DateTime   (UTC)
```

## Event types (sandbox)

Wire values: `payout.paid`, `payout.failed`.

Payload includes provider event id, provider payout id, `amount_minor`, `currency_code`, and `created_at`. Amount and currency must match the payout request exactly. Mismatch: `409 payout_integrity_mismatch` with no state mutation.

## Processing status

| status | meaning |
| --- | --- |
| `received` | Event accepted and not yet applied |
| `processed` | Valid transition applied |
| `ignored` | Duplicate, stale (paid after failed, failed after paid), or non-applicable |
| `failed` | Integrity mismatch or apply error |

Identical already-processed/ignored events return a safe HTTP 200 acknowledgement. Same `provider_event_id` with a **different** `payload_sha256` is `409 payout_webhook_event_conflict`.

Stale paid after terminal failed does not resurrect. Stale failed after paid does not downgrade.

## Authentication

`POST /api/v1/payouts/webhooks/sandbox` uses HMAC-SHA256 over the exact raw body. Header: `X-Sandbox-Payout-Signature`. Comparison is constant-time. Invalid: `401 invalid_payout_webhook_signature`.

`SANDBOX_PAYOUT_WEBHOOK_SECRET` is backend-only, minimum 32 UTF-8 bytes. It is never printed, stored on the event, or placed in Flutter.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `payout_events_provider_event_unique` | `provider`, `provider_event_id` | yes |
| `payout_events_provider_payout_created` | `provider_payout_id`, `created_at` | no |

## Privacy

Do not persist raw secret or signature. Duplicate provider events must not duplicate cleaner notifications.
