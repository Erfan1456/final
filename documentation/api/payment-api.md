# Payment API

TASK 016 payment HTTP surface. There is **no production payment processor**. Sandbox is development/test only. Amounts are integer minor units from the booking quote. Clients never send amount or currency on payment start.

See [payment-processing-and-webhooks.md](../architecture/payment-processing-and-webhooks.md) and [ADR-014](../decisions/ADR-014-payment-provider-webhooks-and-refunds.md).

## Customer (JWT, customer role)

### `GET /api/v1/customer/bookings/{bookingId}/payment`

Payment history for an owned booking.

```json
{
  "success": true,
  "data": {
    "current": { "...safe payment..." },
    "attempts": []
  }
}
```

Attempts are sorted by `attempt_number` descending. Foreign bookings are `404`.

### `POST /api/v1/customer/bookings/{bookingId}/payment`

Requires `Idempotency-Key`. Starts payment or returns an identical replay.

- First attempt: `201`
- Identical replay: `200`
- Retry after failed/cancelled with a new key: `201`

Body must not include amount, currency, cleaner, customer, or booking status.

Development/test sandbox pending responses may include:

```json
"sandbox_session": {
  "payment_id": "...",
  "simulation_available": true
}
```

### `POST /api/v1/customer/bookings/{bookingId}/payment/cancel`

Cancels a **pending** payment attempt owned by the customer. Does not cancel the booking. Booking remains `confirmed`.

## Webhook (HMAC, not customer JWT)

### `POST /api/v1/payments/webhooks/sandbox`

Header: `X-Sandbox-Signature` = lowercase hex HMAC-SHA256 of the **exact raw body bytes**.

Canonical event types: `payment.succeeded`, `payment.failed`, `payment.refunded`, `payment.partially_refunded`.

Invalid/missing signature: `401 invalid_webhook_signature`.

## Development simulation

### `POST /api/v1/dev/payments/{paymentId}/simulate`

Available when `APP_ENV` is `development` (tests may inject config). Production returns `404`.

```json
{ "result": "success" }
```

or `"failure"`. The route **does not** mutate payment status directly. It signs a sandbox webhook and processes it through `PaymentWebhookService`.

## Admin (JWT, admin role)

### `GET /api/v1/admin/payments`

Filters: `status`, `provider`, `currency`, `booking_id`, `customer_user_id`, `limit` (default 20, 1–50), `after` (`_id` descending cursor). No offset pagination.

### `GET /api/v1/admin/payments/{paymentId}`

Safe payment metadata, booking/service snapshot name when available, failure metadata, webhook event summaries.

### `GET /api/v1/admin/payments/{paymentId}/events`

Approved event metadata only.

### `POST /api/v1/admin/payments/{paymentId}/refund`

Requires `Idempotency-Key`.

```json
{ "amount_minor": 100000, "reason": "Customer requested a refund." }
```

`amount_minor` may be omitted (remaining refundable). Sandbox refund signs a webhook and processes it through the shared webhook path.

## Safe payment fields

`id`, `booking_id`, `provider`, `status`, `amount_minor`, `currency_code`, `attempt_number`, timestamps, `refunded_amount_minor`. Admin may also include customer/cleaner ids, provider payment id, failure code/message, booking status, service name.

Never returned: `client_idempotency_key`, `request_fingerprint`, webhook secret, signature, raw provider response, card data.

## Error codes

| code | typical HTTP |
| --- | --- |
| `payment_not_found` | 404 |
| `booking_not_payable` | 409 |
| `payment_already_active` | 409 |
| `payment_already_paid` | 409 |
| `payment_provider_unavailable` | 503 |
| `invalid_webhook_signature` | 401 |
| `webhook_event_conflict` | 409 |
| `payment_integrity_mismatch` | 409 |
| `invalid_payment_state` | 409 |
| `payment_refund_failed` | 409 |
| `invalid_refund_amount` | 400 |
| `invalid_refund_reason` | 400 |
| `idempotency_key_reused` | 409 |
| `not_found` (prod simulate) | 404 |

No raw Mongo or provider errors are exposed.
