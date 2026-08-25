# Earnings and Payout API

TASK 019 cleaner earnings, payout requests, sandbox payout webhooks, admin payout operations, finance summary, and read-only reconciliation.

There is **no production payout processor**. Sandbox is development/test only. Amounts are integer minor units. Clients never send commission. Examples below are fake.

See [earnings-payouts-and-reconciliation.md](../architecture/earnings-payouts-and-reconciliation.md) and [ADR-017](../decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md).

## Cleaner (JWT, persisted cleaner role)

Approved-cleaner is **not** required for historical earnings and payout reads. A persisted active cleaner account is still required.

### `GET /api/v1/cleaner/earnings/summary`

```json
{
  "success": true,
  "data": {
    "currencies": [
      {
        "currency_code": "BDT",
        "gross_earned_minor": 250000,
        "platform_fees_minor": 37500,
        "refunds_gross_minor": 0,
        "cleaner_refund_adjustments_minor": 0,
        "net_ledger_minor": 212500,
        "reserved_payout_minor": 0,
        "paid_out_minor": 0,
        "available_balance_minor": 212500
      }
    ]
  }
}
```

Currencies are never combined.

### `GET /api/v1/cleaner/earnings/ledger`

Query: `currency`, `entry_type`, `limit` (default 20, 1–50), `after` (ObjectId). Sort `_id` descending. No offset. `source_event_key` is omitted from the DTO.

### `GET /api/v1/cleaner/payouts`

Query: `status`, `currency`, `limit`, `after`. Sort `_id` descending. Safe rejection reason may appear. Omitted: `processed_by`, idempotency key, fingerprint, webhook metadata.

### `POST /api/v1/cleaner/payouts`

Header: `Idempotency-Key`. Body:

```json
{
  "amount_minor": 100000,
  "currency_code": "BDT"
}
```

First creation: `201`. Identical replay: `200`. Body cannot choose cleaner id. No payout destination.

### `GET /api/v1/cleaner/payouts/{payoutId}`

Owned payout only. Foreign/unknown: `404 payout_not_found`.

### `POST /api/v1/cleaner/payouts/{payoutId}/cancel`

Only `requested`. Processing cannot be cancelled by the cleaner.

## Admin payouts (JWT, persisted admin)

### `GET /api/v1/admin/payouts`

Query: `status` (default `requested`), `currency`, `cleaner_user_id`, `limit`, `after`. Safe summary fields only.

### `GET /api/v1/admin/payouts/{payoutId}`

Safe payout, cleaner display name, currency earnings summary, provider-event summaries. Omits password, sessions, tokens, idempotency key, fingerprint, HMAC signature, webhook secret.

### `POST /api/v1/admin/payouts/{payoutId}/process`

Only `requested` → `processing`, then provider `createPayout` with backend-owned amount/currency. Production without a real provider: `503 payout_provider_unavailable`.

### `POST /api/v1/admin/payouts/{payoutId}/reject`

```json
{
  "reason": "Incomplete onboarding review"
}
```

Reason: required, 5–500 Unicode code points, trim, plain text, no controls. Only `requested` → `rejected`.

## Admin finance

### `GET /api/v1/admin/finance/summary`

Query: `from`, `to` (explicit offset, normalized UTC), `currency`. Default bounded window: last 30 days. Maximum range: 366 days.

Per currency: `gross_service_volume_minor`, `platform_fee_minor`, `cleaner_net_earnings_minor`, `refund_gross_minor`, `cleaner_refund_adjustments_minor`, `payout_requested_minor`, `payout_processing_minor`, `payout_paid_minor`, `payout_failed_minor`.

Do not label `platform_fee_minor` as profit.

### `GET /api/v1/admin/finance/reconciliation`

Query: `currency`, `limit`, `after`. Read-only. Issue types include `missing_service_earning` and `refund_adjustment_mismatch`. No repair button and no mutation.

### `GET /api/v1/admin/cleaners/{userId}/finance`

Per-currency cleaner earnings summary, recent ledger entries, recent payouts. No bank information.

## Webhook (HMAC, not user JWT)

### `POST /api/v1/payouts/webhooks/sandbox`

Header: `X-Sandbox-Payout-Signature` = lowercase hex HMAC-SHA256 of the **exact raw body bytes**. Constant-time compare. Invalid: `401 invalid_payout_webhook_signature`.

Canonical event types: `payout.paid`, `payout.failed`.

## Development simulation

### `POST /api/v1/dev/payouts/{payoutId}/simulate`

Operational only when `APP_ENV == development`. Production: `404` or safe unavailable.

```json
{ "result": "success" }
```

or `"failure"`. The route **does not** mutate payout status directly. It signs a sandbox payout webhook and processes it through `PayoutWebhookService`.

Admin UI shows Simulate Success / Simulate Failure only when the API sets `simulation_available == true`.

## Error codes

| code | typical status |
| --- | --- |
| `insufficient_payout_balance` | 409 |
| `payout_already_active` | 409 |
| `payout_not_found` | 404 |
| `invalid_payout_state` | 409 |
| `payout_provider_unavailable` | 503 |
| `invalid_payout_amount` | 400 |
| `invalid_payout_currency` | 400 |
| `invalid_payout_webhook_signature` | 401 |
| `payout_webhook_event_conflict` | 409 |
| `payout_integrity_mismatch` | 409 |
| `invalid_payout_rejection_reason` | 400 |
| `idempotency_key_required` | 400 |
| `invalid_idempotency_key` | 400 |
| `idempotency_key_reused` | 409 |

Mongo duplicate-key and provider internals are never returned.
