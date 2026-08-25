# Booking Reservation and Lifecycle Architecture

TASK 015 is the marketplace's first real transaction workflow. A customer books one complete availability slot. TASK 016 consumes the immutable quote as payment amount authority; booking status itself still does not prove payment.

## Product flow

```text
Customer discovery
        ↓
Selected availability slot (slot id in the public detail DTO)
        ↓
Booking confirmation (owned address + optional notes)
        ↓
Idempotency-Key + request fingerprint
        ↓
Validation (auth customer, owned address, future slot, approved cleaner,
            active service/offering, application overlap pre-check)
        ↓
Booking insert
        ↓
Partial unique active-slot index (authoritative same-slot guard)
```

The booked window is exactly the cleaner-approved slot. TASK 015 does not split or shorten slots.

## Concurrent same-slot attempts

Two customers may concurrently POST the same open slot. One insert succeeds with `reservation_active = true`. The other hits the partial unique index and receives 409 `availability_unavailable`. Application pre-checks are friendly only; correctness is the unique constraint.

Different-slot overlap remains application-enforced. Mongo cannot express arbitrary interval exclusion with a simple index. That limitation is documented; TASK 015 still materially strengthens same-slot reservation.

## Idempotency

Flutter generates one `Idempotency-Key` per logical submit (`Random.secure()`, ≥128 bits, base64url without padding) and keeps it across authenticated Dio refresh retries. A new confirmation visit generates a new key. The key is not stored in secure auth storage.

The unique `(customer_user_id, idempotency_key)` index plus duplicate-key load/compare implements replay (200, same fingerprint) vs 409 `idempotency_key_reused`.

## Conditional transitions

Repository updates never read-then-unconditionally-write. Accept/decline/cancel/start/complete selectors include owner, expected status, and `reservation_active`. Status, reservation flag, timestamp, and history `$push` occur in one document update.

## Reservation release

Decline or cancel sets `reservation_active = false`. The slot document stays. Future unreserved slots reappear in discovery. Confirmed/in-progress reservations stay undiscoverable. Completed is terminal; past slots naturally drop out of future discovery.

## Availability protection

`CleanerAvailabilityService` consults `BookingRepository` before update/delete. An active reservation yields 409 `availability_reserved`. Read remains allowed.

## Discovery exclusion

`CleanerDiscoveryService` batches active reservations with `findActiveByAvailabilitySlotIds` (one lookup per list/detail/filter pass, not N+1). Slots with pending/confirmed/in_progress reservations are removed from `next_available_at`, availability-range filtering, and cleaner-detail future slots. After decline/cancel, a still-future slot may return.

## Privacy DTOs

Customer JSON: full own address, cleaner public name, snapshots, history. No cleaner contact or security fields.

Cleaner JSON: customer display name (profile full name or `Customer`), snapshots, history. Pending/declined/cancelled address is coarse only.

## Flutter flow

* Cleaner detail: **Book This Slot** per future unreserved slot → `/customer/book/:cleanerUserId/:slotId`
* Confirmation: owned addresses, integer quote preview, Confirm Booking
* `/customer/bookings` and `/customer/bookings/:bookingId` with cancel
* Cleaner `/cleaner/bookings` and `/cleaner/bookings/:bookingId` with accept/decline/cancel/start/complete
* Role guards redirect foreign roles; backend authorization remains authoritative

Quoted amounts display as minor units (`BDT 250000 minor units / hour`, `Quoted total: BDT 500000 minor units`) without dividing by 100.
