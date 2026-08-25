# ADR-013 — Booking Reservation, Idempotency, and Lifecycle

## Status
Accepted

## Context

TASK 014 made approved cleaners configurable and discoverable. The marketplace still had no transaction: two customers could theoretically target the same slot, and there was no lifecycle for accept/decline/start/complete. TASK 015 needs a first booking model that is safe under concurrent retries without implementing payment.

## Decision

- Book **one complete** availability slot (`start_at`/`end_at`/`duration_minutes` copied from the slot).
- Persist immutable service, pricing, and address snapshots on the booking.
- Compute `quoted_total_minor` with integer round-half-up: `(hourly_rate_minor * duration_minutes + 30) ~/ 60`. The quote is not a payment.
- Embed status history in the booking document so status + history append are one atomic update.
- Store explicit `reservation_active` and update it in the same write as `status`.
- Enforce same-slot exclusivity with a **partial unique** index on `availability_slot_id` where `reservation_active == true`.
- Require customer `Idempotency-Key` and a SHA-256 request fingerprint; uniqueness is the customer+key index with duplicate-key handling.
- Perform conditional repository updates for every lifecycle transition.
- Release the slot (set `reservation_active = false`) on decline/cancel; keep the availability document.
- Reject cleaner update/delete of an actively reserved slot (`availability_reserved`).
- Exclude actively reserved slots from customer discovery via a batched reservation lookup.
- Shape customer vs cleaner DTOs; pending cleaner address is coarse only.
- Paginate booking lists with `_id` descending keyset cursors.

## Alternatives Considered

### Book arbitrary sub-window

Deferred because safe split/remainder allocation needs a more complex transactional scheduler.

### Globally unique `availability_slot_id` on bookings

Rejected because terminal declined/cancelled history must coexist with future rebooking of that slot.

### Client-only double-submit protection

Rejected because correctness requires database enforcement.

### Find idempotency key before insert only

Rejected due to race; uniqueness plus duplicate-key handling is required.

### Separate booking status-history collection

Not selected because embedded history allows atomic status + history update.

### Recompute price from cleaner offering later

Rejected because the rate may change after booking.

### Expose full customer address to pending cleaner

Rejected for privacy.

### Delete cancelled booking

Rejected because lifecycle/audit history must remain.

## Consequences

Customers can create, list, inspect, and cancel eligible bookings. Cleaners can manage assigned jobs without `ApprovedCleanerPolicy` on those routes. Same-slot double-booking is database-enforced. Different-slot overlap remains application-only. Payment still consumes the immutable quote in a later task.

## Security

Booking customer id comes from the authenticated persisted user. Cleaner/service/rate/quote are backend-derived. Address ownership is checked. Public DTOs omit security identity, emails, phones, and Mongo internals. Flutter does not store the idempotency key in secure auth storage and does not contain secrets.

## Deferred Decisions

payment, refund, payout, rescheduling, chat, notifications, reviews, disputes, partial-slot allocation, distributed arbitrary-interval exclusion, cancellation policy/fees, tax, promotions, currency conversion
