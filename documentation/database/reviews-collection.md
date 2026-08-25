# Reviews Collection

This document describes the `reviews` collection.

TASK 017 stores one verified customer review per completed booking. Payment status is not a review eligibility condition. Discovery aggregates only `published` reviews. Rating counters are **not** denormalized onto `cleaner_profiles`.

## Purpose

One review per booking (`booking_id` unique). Only the booking customer may create or update. The booking must exist, belong to the customer, and be `completed`.

## Document shape

```text
_id                   ObjectId
booking_id            ObjectId   (unique)
customer_user_id      ObjectId
cleaner_user_id       ObjectId
rating                int        (1–5)
comment               String?
moderation_status     String     (published | hidden)
hidden_reason         String?
hidden_by             ObjectId?
hidden_at             DateTime?
created_at            DateTime   (UTC)
updated_at            DateTime   (UTC)
```

`verified_booking` is computed for JSON. It is not a persisted boolean.

## Validation

Rating is an integer 1–5. Doubles and numeric strings are rejected. Comment is optional, trimmed, empty → null, max 1000 Unicode code points. Newlines/tabs allowed; other control characters rejected.

## Moderation

New reviews are `published`. Admin may hide (required reason 5–500 Unicode code points) or unhide. Customer cannot choose `moderation_status`. Cleaner cannot moderate.

If a customer edits a currently hidden review, content updates and the review **stays hidden**. Hide of an already-hidden review is idempotent 200 without overwriting the original reason. Unhide of an already-published review is idempotent 200.

## Public identity

Public and cleaner-facing reviewer identity is always `Verified customer`. Discovery public JSON does not include `customer_user_id`, profile id, email, phone, address, booking notes, or payment data.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `reviews_booking_unique` | `booking_id` | yes |
| `reviews_cleaner_status_id_desc` | `cleaner_user_id`, `moderation_status`, `_id` desc | no |
| `reviews_customer_id_desc` | `customer_user_id`, `_id` desc | no |
| `reviews_status_rating_id_desc` | `moderation_status`, `rating`, `_id` desc | no |

Discovery list uses one batched `aggregateForCleanerIds` for visible cleaner ids (not N+1). Detail returns the latest 10 published reviews.

## Security

Do not copy customer/cleaner email, phone, address, payment details, or security fields onto a review.
