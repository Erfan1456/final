# Payment Processing and Webhooks

TASK 016 adds a provider-neutral payment ledger, a development-only sandbox adapter, signed webhooks, refund foundation, and payment-aware confirmed-booking cancellation.

This is **not** a production card processor. There is no Stripe, SSLCommerz, PayPal, or bKash integration. No real money is charged.

## Amount authority

The booking immutable quote is the only amount authority:

```text
quoted_total_minor + currency_code
```

Payment initialization never reads amount from Flutter.

## Provider boundary

`PaymentProvider` is a narrow interface: `createPayment`, `parseAndVerifyWebhook`, `refund`. Application services depend on this interface, not on `SandboxPaymentProvider`. A future real gateway can implement the same interface without replacing the payment domain.

`PaymentProviderType` currently has one wire value: `sandbox`. Fake names for unimplemented providers are not added.

## Sandbox restriction

Sandbox is allowed only when `APP_ENV` is `development` or `test`. Production sandbox initialization fails with `503 payment_provider_unavailable`. Production never silently falls back to sandbox.

`SANDBOX_PAYMENT_WEBHOOK_SECRET` is backend-only, minimum 32 UTF-8 bytes. If absent in local development, sandbox runtime may report unavailable; the rest of the server still boots. Flutter never contains this secret. `ServerConfig.toString()` does not print it.

## Sandbox flow

`createPayment` issues an opaque `sandbox_<secure-random-base64url>` provider payment id. Initial status is `pending`. Flutter receives a safe `sandbox_session` only when simulation is available. The client cannot mutate Mongo payment status.

`POST /api/v1/dev/payments/{id}/simulate` signs a webhook and feeds `PaymentWebhookService`. There is no status-update shortcut.

## Webhook authenticity

HMAC-SHA256 via hashlib. Header `X-Sandbox-Signature`. Input is exact raw HTTP body bytes. Expected signature is lowercase hex. Verification uses hashlib `HashDigest.isEqual` plus a XOR-fold hex helper. Missing/invalid signature: `401 invalid_webhook_signature`.

## Event idempotency

Unique `(provider, provider_event_id)`. Payload SHA-256 is stored. Identical replay acknowledges. Different hash for the same event id is `409 webhook_event_conflict`.

## State machine (out of order)

Webhooks resolve payment by `provider` + `provider_payment_id` and verify amount/currency when present (`409 payment_integrity_mismatch` otherwise; no update).

| event | from | to |
| --- | --- | --- |
| `payment.succeeded` | pending/authorized | paid |
| `payment.failed` | pending/authorized | failed |
| `payment.refunded` | paid/partially_refunded | refunded (full amount) |
| `payment.partially_refunded` | paid/partially_refunded | partially_refunded |

Rules:

- `failed` cannot become `paid` from a stale attempt.
- `payment.failed` after `paid` is ignored; paid is not downgraded.
- Duplicate success is idempotent.
- Duplicate refund event for the same provider event is idempotent.
- Unknown payment is recorded as ignored.

## Booking cancellation orchestration

`BookingCancellationOrchestrator` coordinates confirmed-booking cancel for customer and cleaner:

1. Pending/authorized payment is cancelled first.
2. Paid/partially_refunded requires refund through the provider + webhook path **before** the booking is marked cancelled.
3. If refund fails, the booking remains `confirmed` (`409 payment_refund_failed`).
4. Pending bookings have no payment; TASK 015 cancellation behavior remains.

Do not mark the booking cancelled first and hope refund succeeds later.

## Flutter honesty

Sandbox UI appears only when the API sets `simulation_available == true`. It is labeled **Development Sandbox**. There is no card-number or CVV form. The app does not claim real card, Stripe, or production processing.

TASK 017 notifies the customer after a successful paid, failed, or refunded webhook transition. Invalid signatures, integrity mismatches, ignored unknown payments, and stale no-op events do not notify.

TASK 018 admin cancellation of a confirmed booking reuses this payment-aware orchestration. Refund failure leaves the booking confirmed. A successful refund request also appends a best-effort `payment_refund_requested` audit row without changing financial correctness.

TASK 019 projects completed + successful-payment bookings into an append-only earnings ledger and applies refund adjustments using the original commission snapshot. Payment remains the charge/refund source of truth. See [earnings-payouts-and-reconciliation.md](earnings-payouts-and-reconciliation.md).
