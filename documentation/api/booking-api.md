# Booking API

TASK 015 adds customer booking creation/list/detail/cancel and cleaner accept/decline/cancel/start/complete. Confirmed-booking cancellation is payment-aware (TASK 016): pending attempts are cancelled first; paid bookings require refund before cancel. See [payment-api.md](payment-api.md). TASK 017 booking chat and reviews are documented in [chat-api.md](chat-api.md) and [review-api.md](review-api.md). Disputes, rescheduling, payouts, and recurring bookings are not implemented.

Feature routes require Bearer access JWT verification, persisted user resolution, `account_status == active`, and the **current persisted** `users.role`. JWT `role` is authentication evidence only.

Examples below use **fake** ObjectIds and amounts. They are not live identities.

## Customer — `POST /api/v1/customer/bookings`

Customer role only. Requires header `Idempotency-Key` (ASCII-safe, 16–128 characters after trim, no control characters; not lowercased).

Body (backend derives customer, cleaner, service, rate, quote, status, and timestamps):

```json
{
  "availability_slot_id": "507f1f77bcf86cd799439071",
  "address_id": "507f1f77bcf86cd799439031",
  "customer_notes": "Please use the side entrance."
}
```

`customer_notes` is optional; trim; empty → null; max 500 Unicode code points; plain text; no control characters.

First successful creation: **201**. Identical replay (same key + same fingerprint): **200**. Safe customer DTO may include `idempotent_replay`. Do not expose `request_fingerprint` or the idempotency key in the booking DTO.

Unknown/not-owned address: 404 `address_not_found`. Unavailable/stale slot, inactive/unapproved cleaner, inactive service/offering, or active reservation: 409 `availability_unavailable` (no internal reason). Same key, different request: 409 `idempotency_key_reused`. Missing header: 400 `idempotency_key_required`. Invalid key: 400 `invalid_idempotency_key`.

Fake 201 response excerpt:

```json
{
  "success": true,
  "data": {
    "booking": {
      "id": "507f1f77bcf86cd799439091",
      "status": "pending",
      "cleaner_user_id": "507f1f77bcf86cd799439081",
      "cleaner_full_name": "Ada Cleaner",
      "service_snapshot": {
        "slug": "home-cleaning",
        "name": "Home Cleaning",
        "billing_model": "hourly"
      },
      "address_snapshot": {
        "label": "Home",
        "line1": "1 Test Street",
        "city": "Dhaka",
        "region": "Dhaka",
        "postal_code": "1205",
        "country_code": "BD"
      },
      "duration_minutes": 120,
      "hourly_rate_minor": 250000,
      "quoted_total_minor": 500000,
      "currency_code": "BDT",
      "start_at": "2026-09-01T03:00:00.000Z",
      "end_at": "2026-09-01T05:00:00.000Z",
      "idempotent_replay": false
    }
  }
}
```

## Customer — `GET /api/v1/customer/bookings`

Query: optional `status` (`pending` | `confirmed` | `in_progress` | `completed` | `declined` | `cancelled`), `limit` (default 20, min 1, max 50), `after` (booking ObjectId). Sort `_id` descending; descending cursor is `_id < after`. Response: `items`, `next_cursor`. No offset pagination.

## Customer — `GET /api/v1/customer/bookings/{bookingId}`

Owned booking only. Unknown or foreign: 404 `booking_not_found` (no ownership distinction). Full own address snapshot. Status history included.

## Customer — `POST /api/v1/customer/bookings/{bookingId}/cancel`

Allowed for `pending` or `confirmed` when `start_at > now`. Optional reason (trim, max 500, plain text). Past start, in-progress, or terminal: 409 `invalid_booking_state`.

## Cleaner management

Existing booking-management routes do **not** require `ApprovedCleanerPolicy`. Assigned bookings remain accessible if onboarding state later changes. Persisted active UserAccount/role authorization still applies. Booking **creation** still requires the cleaner to be currently approved.

### `GET /api/v1/cleaner/bookings`

Same `status` / `limit` / `after` keyset as the customer list.

### `GET /api/v1/cleaner/bookings/{bookingId}`

### `POST .../accept` — pending → confirmed; `reservation_active` remains true.

### `POST .../decline` — pending only; required reason 5–500 code points after trim.

### `POST .../cancel` — confirmed only; `start_at > now`; required reason 5–500.

### `POST .../start` — confirmed; `now >= start_at` and `now < end_at`.

### `POST .../complete` — in_progress; may finish before `end_at`. No payout.

Invalid transition: 409 `invalid_booking_state`. Foreign/unknown: 404 `booking_not_found`.

Cleaner pending/declined/cancelled responses expose coarse address only (`city`, `region`, `country_code`). Confirmed / in_progress / completed may include the full snapshot. Customer display name is profile `full_name` or `Customer`.

## Lifecycle

```text
(none) → pending
pending → confirmed | declined | cancelled
confirmed → cancelled | in_progress
in_progress → completed
```

Forbidden include: pending → in_progress/completed; confirmed → declined/completed; in_progress → cancelled; any transition from completed/declined/cancelled.

All mutations use conditional selectors (expected `_id`, owner, status, `reservation_active`). Zero matched updates are resolved as not-found vs invalid state without leaking ownership.

## Availability integration

Cleaner availability UPDATE/DELETE of a slot with an active booking: 409 `availability_reserved`. GET remains allowed.

## Errors

| code | status |
| --- | --- |
| invalid input / invalid_idempotency_key / idempotency_key_required / invalid_customer_notes | 400 |
| booking_not_found / address_not_found | 404 |
| availability_unavailable / invalid_booking_state / idempotency_key_reused / availability_reserved | 409 |
| forbidden (wrong role) | 403 |

Duplicate-key and Mongo internals are never returned.

Wrong role on these routes uses the existing 403 `forbidden` mapping. TASK 013 stale JWT role behavior is unchanged.
