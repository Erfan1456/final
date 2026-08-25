# ADR-014 — Payment Provider Boundary, Webhooks, and Refunds

## Status
Accepted

## Context

TASK 015 established bookings with immutable quotation snapshots and a confirmed-job lifecycle, but no payment ledger. TASK 016 needs senior-level payment architecture without claiming a production external processor is configured.

## Decision

- Provider-neutral `PaymentProvider` (`createPayment`, `parseAndVerifyWebhook`, `refund`).
- Development/test `SandboxPaymentProvider` only. Production sandbox is prohibited (`503 payment_provider_unavailable`); no silent fallback.
- Booking quote is amount authority. Flutter never supplies amount/currency.
- `payments` collection is the source of truth. Booking payment cache is omitted; no cross-document Mongo transaction.
- Multiple historical attempts; one active (`payment_active`) and one successful settlement (`settlement_recorded`) per booking, enforced with partial unique indexes.
- Idempotent initialization via `Idempotency-Key` + fingerprint + unique customer+key index.
- Signed sandbox webhooks (HMAC-SHA256, `X-Sandbox-Signature`, exact raw body, constant-time compare).
- `payment_webhook_events` unique `(provider, provider_event_id)` plus payload hash for replay/conflict.
- Conditional payment status updates from webhooks; stale/out-of-order events ignored rather than corrupting paid state.
- Refund requests collection with admin idempotency; provider refund always through the webhook path.
- Payment-aware booking cancellation: cancel pending attempts first; refund paid/partially_refunded before booking cancellation; failed refund leaves booking confirmed.
- Admin transaction list/detail/events/refund. Customer payment status, start, cancel, retry, and development sandbox UI when the API says simulation is available.

## Alternatives Considered

### Trust Flutter payment-success response
Rejected.

### Let client provide amount
Rejected.

### Directly mutate payment from sandbox simulation route
Rejected; simulator must use webhook path.

### Store raw card data
Rejected.

### Mark booking paid without payment record
Rejected.

### Process duplicate webhook every time
Rejected.

### Refund after cancelling booking
Rejected because failed refund could leave financial inconsistency.

### Hard-code Stripe now
Not selected because provider/account requirements have not been chosen.

### Mongo `$in` partial unique index for active statuses
Not selected; Atlas in this project already uses boolean partial unique indexes (`reservation_active`). TASK 016 uses `payment_active` and `settlement_recorded`.

## Consequences

The marketplace can exercise payment state machines, webhooks, retries, refunds, and admin inspection without a live processor. A future adapter can implement `PaymentProvider` without replacing the domain. Production cannot accidentally charge through sandbox.

## Security

HMAC webhook authenticity, constant-time signature compare, unique event and payment idempotency, refund command idempotency, conditional state updates, no PCI/card storage, no secrets in Flutter or logs, sandbox forbidden in production. Public DTOs omit keys, fingerprints, signatures, and secrets.

## Deferred Decisions

real gateway adapter, provider-specific SDK, 3DS, PCI hosted elements, payouts, tax, fees, refund settlement latency, chargebacks, disputes, webhook delivery queues/retries, multi-currency conversion.
