# Disputes Collection

This document describes the `disputes` collection.

TASK 018 stores **one dispute document per booking**. A closed historical dispute still occupies that unique `booking_id`; TASK 018 does not reopen or create a second thread.

## Purpose

Booking participants (customer or cleaner) may open a structured operational dispute for an established service relationship. Administrators review and resolve. This is not a court finding, chargeback, or legal adjudication.

## Document shape

```text
_id                 ObjectId
booking_id          ObjectId   (unique)
customer_user_id    ObjectId
cleaner_user_id     ObjectId
opened_by_user_id   ObjectId
opened_by_role      String     (customer | cleaner)
category            String
status              String
subject             String
description         String
resolution          String?
resolved_by         ObjectId?
resolved_at         DateTime?
created_at          DateTime   (UTC)
updated_at          DateTime   (UTC)
history             [
  from_status       String?
  to_status         String
  actor_user_id     ObjectId
  actor_role        String
  note              String?
  created_at        DateTime   (UTC)
]
```

Do not store passwords, JWTs, refresh tokens, payment credentials, full `UserAccount`, full address documents, webhook secrets, or Mongo URIs on a dispute.

## Status lifecycle

| from | to | actor |
| --- | --- | --- |
| none | `open` | booking participant |
| `open` | `under_review` | admin |
| `open` or `under_review` | `resolved` | admin |
| `resolved` | `closed` | participant or admin |

`closed` is terminal. Invalid transitions return `409 invalid_dispute_state`. Status change and history append happen in the same conditional document update.

Creation history: `from_status` is null, `to_status` is `open`, actor is the participant.

## Category

Allowed wire values only:

* `service_quality`
* `cleaner_no_show`
* `customer_no_show`
* `payment_issue`
* `booking_issue`
* `conduct`
* `other`

## Eligibility

Only `booking.customer_user_id` or `booking.cleaner_user_id` may create. Admin cannot impersonate a participant on participant routes.

Eligible booking statuses: `confirmed`, `in_progress`, `completed`, `cancelled`.

`pending` and `declined` return `409 dispute_not_allowed` (no accepted/active service relationship).

A foreign booking is `404 booking_not_found`.

## Validation

* Subject: required, trim, 5–120 Unicode code points, no control characters, plain text.
* Description: required, trim, 20–3000 Unicode code points, newline/tab allowed, other controls rejected.
* Admin resolution: required, trim, 10–3000 Unicode code points, newline/tab allowed.

## Participant privacy

Customer-facing JSON may include booking id, category, subject, description, status, resolution, history, timestamps, and cleaner public display name. It must not include cleaner email, phone, or account internals.

Cleaner-facing JSON uses the same operational fields. Customer identity is the customer profile full name when available, otherwise `"Customer"`. It must not include customer email, phone, or a fuller address than booking lifecycle already permits.

Admin JSON may include customer/cleaner user ids and booking operations data. No password, session, or security fields.

## Indexes

| name | keys | unique | reason |
| --- | --- | --- | --- |
| `disputes_booking_unique` | `booking_id` | yes | one document per booking |
| `disputes_status_id_desc` | `status`, `_id` desc | no | admin list default `open` + cursor |
| `disputes_customer_id_desc` | `customer_user_id`, `_id` desc | no | customer/admin filter |
| `disputes_cleaner_id_desc` | `cleaner_user_id`, `_id` desc | no | cleaner/admin filter |
| `disputes_category_status_id_desc` | `category`, `status`, `_id` desc | no | admin category+status filter |

## Admin operations

Admin list defaults to status `open`. Keyset pagination uses `_id` descending with `after` cursor. Limit default 20, range 1–50.

Conditional atomic selectors:

* review: `open` → `under_review` (already `under_review` is idempotent 200)
* resolve: `open` or `under_review` → `resolved`
* close: `resolved` → `closed` (resolution is retained)

## Notifications

Best-effort via existing `NotificationService`. Failure does not roll back the dispute write.

* created → other participant: `dispute_opened`
* admin review → customer and cleaner: `dispute_under_review`
* admin resolve → customer and cleaner: `dispute_resolved`
* close → `dispute_closed` (implemented)

Resource type is `dispute`. Resource id is the **booking id** so Flutter can open the role-appropriate dispute screen without trusting arbitrary URLs.

## Security

Participant ids are derived from the booking, not from the request body. Foreign bookings are hidden as not found. Admin cannot create through participant routes.
