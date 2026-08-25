# ADR-017 — Cleaner Earnings, Payout Requests, and Financial Reconciliation

## Status
Accepted

## Context

The marketplace already authenticates users, persists roles, books services, records sandbox payments, refunds, chats, notifies, reviews, disputes, and audits. It still lacked a cleaner settlement layer: what a cleaner earned after platform commission, how refunds adjust that ledger, and how a payout request could be reserved, reviewed, and settled in development without claiming a real bank transfer.

TASK 019 needed that layer without a real payout provider, bank-account storage, KYC, tax, currency conversion, chargebacks, scheduled cron jobs, or AI.

## Decision

- **Append-only earnings ledger.** Insert only. No update or delete. Payment remains the charge/refund source of truth; the ledger is an accounting projection.
- **Completed + successful-payment eligibility.** `ensureBookingEarning` no-ops until both are true. Dual triggers (job complete and payment paid) share one service.
- **Commission basis-point snapshot.** `PLATFORM_COMMISSION_BPS` (integer 0–10000) is copied onto the earning. Existing rows are never recalculated. Development/test default is 1500 when unset. Production should set the value explicitly; the process still boots with the documented default so configuration loading stays non-throwing. Invalid explicit values keep the process booting but refuse to snapshot a guessed rate.
- **Integer fee math.** `platform_fee_minor = (gross * commission_bps + 5000) ~/ 10000`. Never `double`.
- **Refund adjustment entries.** Incremental negative rows. Allocation uses the **original** earning `commission_bps`.
- **Negative balances allowed.** Post-payout refunds can put available balance below zero. Future earnings offset the deficit.
- **Per-currency accounting.** Summaries and finance totals never mix currencies. No FX.
- **One active payout per cleaner.** Partial unique index on `cleaner_user_id` where `payout_active == true`.
- **Payout request idempotency.** `Idempotency-Key` plus fingerprint (cleaner, amount, currency). Unique cleaner + key.
- **Provider-neutral payout interface.** `PayoutProvider` with `createPayout` and `parseAndVerifyWebhook`. Enum value `sandbox` only.
- **Dev/test sandbox only.** Production never silently enables sandbox payouts.
- **Signed payout webhook.** HMAC-SHA256, `X-Sandbox-Payout-Signature`, constant-time compare.
- **Payout event replay protection.** Unique `(provider, provider_event_id)` plus payload hash conflict detection.
- **Admin processing/rejection.** Cleaner cannot trigger the provider. Admin process uses backend-owned amount/currency. Simulator uses the signed webhook path.
- **Reconciliation detection.** Read-only admin API. No silent repair of live documents.

## Alternatives Considered

### Recalculate earnings from current booking/payment every request
Rejected because historical commission/refund accounting would not be stable.

### Store cleaner balance directly on cleaner_profiles
Rejected because a mutable aggregate can drift and loses accounting history.

### Clamp negative balances to zero
Rejected because post-payout refunds create a real future offset obligation.

### Use floating-point money
Rejected.

### Combine all currencies
Rejected without exchange-rate infrastructure.

### Let cleaner directly trigger provider payout
Rejected; admin processing remains explicit in the current operational model.

### Store bank details now
Deferred because no real payout provider/KYC system exists.

### Directly mutate payout from sandbox simulation
Rejected; simulator must use the signed webhook path.

### Automatically repair reconciliation issues
Deferred because financial repair should be deliberate and auditable.

## Consequences

Cleaners can view per-currency earnings and request payouts against available balance. Administrators can review, reject, or process requests through a sandbox adapter in development/test. Refunds adjust the ledger using the original commission snapshot. Negative balances remain visible. Finance and reconciliation screens expose platform fees and inconsistencies without claiming profit or exactly-once distributed accounting.

Provider-call failure after `processing` should mark the request `failed` and release reservation where possible. Residual cross-system inconsistency is detectable via reconciliation, not auto-healed.

## Security

- Payment/booking amounts are server-derived. Clients cannot set commission.
- Cleaner identity comes from persisted auth. Body cannot choose cleaner id.
- Amount cannot exceed available balance. Active-payout unique reservation prevents concurrent drain.
- Admin process/reject require persisted admin role.
- Provider amount/currency are backend-owned.
- Sandbox forbidden in production.
- HMAC payout webhook with constant-time compare.
- Provider event replay protected. Signature and secret are not persisted.
- No bank, card, or wallet secret stored. Flutter contains no webhook secret, Mongo URI, or signing secret.
- `backend/.env` remains ignored.

## Deferred Decisions

Real payout provider, bank/wallet destination, KYC, tax, scheduled payouts, payout fees, currency conversion, chargebacks, automated reconciliation repair, accounting export.
