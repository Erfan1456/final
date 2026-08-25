# Earnings, Payouts, and Reconciliation

TASK 019 adds an append-only cleaner earnings ledger, payout requests, a development-only sandbox payout adapter, signed payout webhooks, admin payout operations, and read-only financial reconciliation.

This is **not** a production payout processor. There is no bank transfer, Stripe Connect, PayPal Payouts, bKash payout, KYC, tax, or currency conversion. No real money is transferred.

## Completion / payment → earning

```text
booking completed
  AND
successful payment (paid / partially_refunded / refunded)
  → EarningsSettlementService.ensureBookingEarning
  → service_earning (idempotent source_event_key earning:booking:<id>)
  → catch-up refund_adjustment rows if refunds already exist
```

Either domain transition may happen first. Both booking completion and payment-paid webhook call the same settlement service. Duplicate calls still produce one original earning.

Payment is the amount authority (`amount_minor`, `currency_code`). Commission is snapshotted from `PLATFORM_COMMISSION_BPS` at creation.

Primary booking/payment writes remain authoritative if ledger append fails. Settlement logs a diagnostic. Admin reconciliation can detect missing earnings. TASK 019 does not claim distributed exactly-once accounting.

## Refund → adjustment

```text
provider refund event
  → payment transition (TASK 016)
  → applyRefundAdjustment using ORIGINAL earning commission_bps
  → refund_adjustment (source_event_key refund:<provider>:<eventId>)
```

Refunds that occur before earning creation are represented after the earning exists (catch-up key `refund:catchup:payment:<paymentId>`).

## Payout

```text
available_balance_minor > 0
  → cleaner request (Idempotency-Key, amount <= available)
  → payout_active reservation (partial unique index)
  → admin process (requested → processing)
  → PayoutProvider.createPayout (backend-owned amount/currency)
  → signed webhook
  → paid or failed (payout_active false)
```

Cleaner may cancel only `requested`. Admin may reject only `requested`. Processing cannot be cancelled by the cleaner.

Failed/cancelled/rejected requests do not reduce available balance. Paid requests do.

## Provider boundary

`PayoutProvider` is a narrow interface: `createPayout`, `parseAndVerifyWebhook`. `PayoutProviderType` currently has one wire value: `sandbox`. Fake names for unimplemented providers are not added.

Sandbox is allowed only when `APP_ENV` is `development` or `test`. Production returns `503 payout_provider_unavailable`. Production never silently falls back to sandbox even if a secret is present.

Sandbox `provider_payout_id` is `sandbox_payout_` plus secure-random base64url. Not sequential.

`POST /api/v1/dev/payouts/{id}/simulate` signs a webhook and feeds `PayoutWebhookService`. There is no status-update shortcut.

## Webhook authenticity and replay

HMAC-SHA256. Header `X-Sandbox-Payout-Signature`. Exact raw body. Constant-time compare. Unique `(provider, provider_event_id)`. Same event id / different payload hash: `409 payout_webhook_event_conflict`. Amount/currency mismatch: `409 payout_integrity_mismatch` with no mutation. Stale events do not resurrect or downgrade terminal payouts.

## Reconciliation

```text
booking + payment truth
  ↔ earnings ledger
  → GET /api/v1/admin/finance/reconciliation
  → missing_service_earning
  → refund_adjustment_mismatch
```

Admin GET is read-only. TASK 019 does not auto-heal live Atlas documents.

## Flutter honesty

Cleaner earnings show minor units without a global divide-by-100. Gross is not labeled “income received”. Platform fee is not labeled “profit”. Payout request copy states that no bank or wallet destination is collected and that the project uses a development payout workflow. Admin Simulate buttons appear only when `simulation_available == true` and are labeled **Development Sandbox**.

## Notifications and audit

Cleaner notifications: processing, paid, failed, rejected (deterministic dedupe keys; best-effort). Cleaner cancellation does not self-notify.

Audit actions: `payout_processing_started`, `payout_rejected`, optional `payout_sandbox_simulated`. Do not audit webhook secret, signature, or full provider payload.

## Deferred

Real payout provider, bank/wallet destination, KYC, tax, scheduled payouts, payout fees, currency conversion, chargebacks, automated reconciliation repair, accounting export.
