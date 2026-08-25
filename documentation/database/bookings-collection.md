# Bookings Collection

This document describes the `bookings` collection.

TASK 015 stores the marketplace's first transaction: a customer reservation of **one complete** availability slot, immutable service/address/pricing snapshots, and an embedded status history. Payment, chat, notifications, and reviews live in their own collections. Payout, disputes, rescheduling, and recurring bookings are not stored here.

A booking preserves the agreement at creation time. Later edits to `addresses`, `services`, or `cleaner_services` must not change historical booking terms. Snapshots copy only approved booking fields. Passwords, `email_normalized`, JWTs, refresh tokens, session ids, token hashes, Mongo URIs, and `ACCESS_TOKEN_SECRET` are never stored on a booking.

## Purpose

One booking is one reserved availability slot for one customer, one cleaner, and one platform service. The booked interval is exactly the slot:

```text
booking.start_at = availability_slot.start_at
booking.end_at = availability_slot.end_at
booking.duration_minutes = slot duration
```

TASK 015 does not split, shorten, or replace a slot with adjacent remainder windows.

## Document shape

```text
_id                     ObjectId
customer_user_id        ObjectId   (users._id; from auth, never from the body)
cleaner_user_id         ObjectId   (from the slot; never from the body)
availability_slot_id    ObjectId
service_id              ObjectId   (from the slot/offering)
status                  String     (BookingStatus wire value)
reservation_active      bool
duration_minutes        int
hourly_rate_minor       int
quoted_total_minor      int
currency_code           String
service_snapshot        { slug, name, billing_model }
address_snapshot        { label, line1, line2?, city, region, postal_code, country_code }
customer_notes          String?
idempotency_key         String
request_fingerprint     String     (SHA-256 lowercase hex)
start_at                DateTime   (UTC)
end_at                  DateTime   (UTC)
accepted_at             DateTime?
declined_at             DateTime?
started_at              DateTime?
completed_at            DateTime?
cancelled_at            DateTime?
status_history          [ { from_status?, to_status, actor_user_id, actor_role, reason?, created_at } ]
created_at              DateTime   (UTC)
updated_at              DateTime   (UTC)
```

All persisted DateTimes are UTC.

## Status enum

Wire values (lowercase): `pending`, `confirmed`, `in_progress`, `completed`, `declined`, `cancelled`.

`reservation_active` is an explicit concurrency field, updated in the **same** atomic booking document write as `status`:

| status | reservation_active |
| --- | --- |
| pending | true |
| confirmed | true |
| in_progress | true |
| completed | false |
| declined | false |
| cancelled | false |

## Embedded status history

History is embedded so a status transition and history append can occur in one Mongo document update. TASK 015 does not create a separate `booking_status_history` collection.

Creation appends `from_status = null`, `to_status = pending`, actor = customer. Clients cannot supply history entries.

## Quoted total

`quoted_total_minor` is an immutable quotation snapshot, not a payment, charge, authorization, or captured amount. Integer round-half-up to the nearest minor unit:

```text
quoted_total_minor = (hourly_rate_minor * duration_minutes + 30) ~/ 60
```

Example (fake numbers): 250000 minor units/hour × 120 minutes → 500000. 1 minor unit × 30 minutes → 1. No floating-point currency arithmetic. Later payment must consume this snapshot rather than recomputing from a new cleaner rate.

## Idempotency

`idempotency_key` is unique per customer. `request_fingerprint` hashes a deterministic representation of `customer_user_id`, `availability_slot_id`, `address_id`, and trimmed notes (or null). Same key + same fingerprint returns the existing booking. Same key + different fingerprint is a conflict. Correctness relies on the unique customer+key index plus duplicate-key handling, not find-then-insert alone.

## Indexes

1. `bookings_active_availability_slot_unique` — unique `{ availability_slot_id: 1 }` with `partialFilterExpression: { reservation_active: true }`. At most one **active** booking may reference a slot. Historical declined/cancelled bookings of the same slot may coexist. This is the authoritative same-slot double-booking guard.
2. `bookings_customer_idempotency_unique` — unique `{ customer_user_id: 1, idempotency_key: 1 }`.
3. `bookings_customer_id_desc` — `{ customer_user_id: 1, _id: -1 }` for customer keyset lists.
4. `bookings_cleaner_id_desc` — `{ cleaner_user_id: 1, _id: -1 }` for cleaner keyset lists.
5. `bookings_cleaner_active_start` — `{ cleaner_user_id: 1, reservation_active: 1, start_at: 1 }` for overlap pre-checks.

`bookings_availability_active` is **omitted**. The partial unique index already covers active-reservation lookup by slot id. A second index would be redundant for actual query patterns.

Partial unique metadata must include key, `unique: true`, and `partialFilterExpression.reservation_active = true`. A globally unique `availability_slot_id` index would incorrectly block rebooking after release.

## Concurrency

Same-slot exclusivity is database-enforced. Concurrent inserts of two active bookings for one slot: one succeeds; the other maps to a safe `availability_unavailable` without exposing duplicate-key details.

Different-slot interval overlap (`reservation_active == true` AND `existing.start_at < proposed.end_at` AND `existing.end_at > proposed.start_at`) is an **application** pre-check. Complete database-level arbitrary interval exclusion is still not available with a simple Mongo index. TASK 015 does not claim arbitrary interval overlap is database-perfect.

## Reservation release

On decline or cancellation, `reservation_active` becomes false in the same update. The original `availability_slots` document remains. If `start_at` is still in the future, discovery may offer the slot again. TASK 015 does not create a replacement slot and does not delete historical bookings.

Completed bookings set `reservation_active = false`. The slot start is normally already past, so the slot does not return to future discovery.

## Privacy

Customer-facing documents include the customer's own full address snapshot and the cleaner's public name. They never include cleaner email, phone, review metadata, account internals, or security fields.

Cleaner-facing documents include a customer display name from `CustomerProfile.full_name`, or the neutral label `Customer` when no profile exists (never email). Address privacy:

* pending / declined / cancelled: coarse `city`, `region`, `country_code` only
* confirmed / in_progress / completed: full address snapshot

## Future payment relationship

Payment will later consume `hourly_rate_minor`, `quoted_total_minor`, and `currency_code` from this document. TASK 015 creates no payment documents.
