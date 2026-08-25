# Cleaner Profiles Collection

This document describes the `cleaner_profiles` collection.

TASK 013 introduced the collection, indexes, onboarding lifecycle, cleaner HTTP API, and administrator review API. Cleaner services, availability, earnings, bookings, payments, chat, and reviews are not stored here.

## Purpose

Stores cleaner onboarding/profile data separately from `users` identity/security records. Exactly one cleaner profile exists per cleaner user. That single document owns the current onboarding lifecycle. Signup does **not** create a cleaner profile. `GET /api/v1/cleaner/profile` may return `profile: null` until onboarding starts.

## Document shape

```text
_id                 ObjectId
user_id             ObjectId   (users._id; never taken from an HTTP body)
full_name           string
phone_e164          string?    (simplified E.164, optional)
bio                 string     (plain text)
years_experience    int        (0–50 inclusive)
service_area        string     (human-readable text, not GIS)
onboarding_status   string     (draft | pending | approved | rejected)
submitted_at        DateTime?  (UTC)
reviewed_at         DateTime?  (UTC)
reviewed_by         ObjectId?  (admin users._id)
rejection_reason    string?
created_at          DateTime   (UTC)
updated_at          DateTime   (UTC)
```

Wire `onboarding_status` values are lowercase. Domain code uses `CleanerOnboardingStatus` rather than scattering raw strings.

Do not store passwords, tokens, sessions, verification uploads, coordinates, or service catalog entries here.

## Ownership and role

`user_id` is always the authenticated persisted cleaner user. Approving or rejecting onboarding **does not** change `users.role`. The user remains `cleaner` before and after review. Rejection does not suspend or deactivate the account.

## Onboarding lifecycle

```text
(no document)
    ↓ PUT profile
draft  ←→  (edits allowed)
    ↓ POST submit
pending  (edits locked; admin reviews)
    ↓ approve
approved (edits locked; service/availability setup is later work)
    ↓ reject from pending
rejected (edits allowed)
    ↓ POST submit
pending  (clears rejection_reason, reviewed_at, reviewed_by)
```

Allowed cleaner edits: `draft`, `rejected`.

Locked from cleaner editing: `pending`, `approved` (HTTP 409 `cleaner_profile_locked`).

Approved status is never silently downgraded to draft.

## State-transition concurrency

Submit, approve, and reject use **conditional Mongo selectors** that include the expected `onboarding_status`. They do not read status and then perform an unconditional update.

Conceptually:

* submit: `user_id == current` and `onboarding_status ∈ {draft, rejected}`
* approve/reject: `user_id == target` and `onboarding_status == pending`

If the conditional update matches no document, application logic distinguishes missing profile versus invalid state without racing a second writer into an illegal transition.

## Indexes

* `cleaner_profiles_user_id_unique` — unique `user_id` ascending
* `cleaner_profiles_status_id` — `onboarding_status` ascending, `_id` ascending (admin queue + cursor pagination)

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## Validation (backend-owned)

* `full_name`: required, trim, 2–100 Unicode code points, no control characters
* `phone_e164`: optional simplified E.164 (`+` and 8–15 digits)
* `bio`: required, trim, 20–1000 Unicode code points, plain text (not HTML)
* `years_experience`: integer 0–50 inclusive; string numbers and doubles are rejected
* `service_area`: required, trim, 2–120 Unicode code points
* reject `reason`: required, trim, 5–500 Unicode code points

## Live data policy

TASK 013 must not insert, update, delete, or dump live cleaner profile documents. Automated tests use in-memory fakes. Only approved index metadata may be ensured on Atlas. No real Atlas admin user is created by this task.
