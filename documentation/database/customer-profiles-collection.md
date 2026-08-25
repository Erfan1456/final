# Customer Profiles Collection

This document describes the `customer_profiles` collection.

TASK 013 introduced the collection, unique owner index, repository contract, and customer profile HTTP API. Bookings, payments, and service discovery are not stored here.

## Purpose

Stores customer marketplace profile data separately from `users` identity/security records. Exactly one profile may exist per customer user. Signup does **not** create a profile automatically. `GET /api/v1/customer/profile` may return `profile: null` until the customer creates one.

## Document shape

```text
_id                  ObjectId
user_id              ObjectId   (users._id; never taken from an HTTP body)
full_name            string
phone_e164           string?    (simplified E.164, optional)
default_address_id   ObjectId?  (authoritative default address pointer)
created_at           DateTime   (UTC)
updated_at           DateTime   (UTC)
```

Do not store passwords, tokens, sessions, or a duplicated email on this collection.

## Ownership

`user_id` is always the authenticated persisted user id. Request bodies cannot set `user_id`, `default_address_id`, `created_at`, or `updated_at`.

## Default address pointer

`default_address_id` is the single source of truth for the customer's default service address. Address documents do **not** store `is_default`. HTTP list/detail responses compute `is_default` by comparing each address id with this pointer.

Setting a default:

1. verify the address exists and belongs to the authenticated customer;
2. require an existing customer profile (HTTP 409 `customer_profile_required` otherwise);
3. set `customer_profiles.default_address_id`.

Deleting an address that is currently the default:

1. clear `default_address_id` if it still matches the deleted address;
2. delete the owned address.

That clear + delete sequence is **not** a MongoDB multi-document transaction. The application still avoids leaving a dangling `default_address_id` by clearing first when the pointer matches.

## Indexes

* `customer_profiles_user_id_unique` — unique `user_id` ascending

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## Validation (backend-owned)

* `full_name`: required, trim, 2–100 Unicode code points, no control characters. Stored trimmed. Not forced to ASCII or a specific case.
* `phone_e164`: optional. Empty/whitespace becomes `null`. If supplied, `+` followed by 8–15 decimal digits. No OTP, no ownership verification, no second normalized phone field.

## Live data policy

TASK 013 must not insert, update, delete, or dump live customer profile documents. Automated tests use in-memory fakes. Only approved index metadata may be ensured on Atlas.
