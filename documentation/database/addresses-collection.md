# Addresses Collection

This document describes the `addresses` collection.

TASK 013 introduced customer service-address persistence, ownership queries, a 20-address product limit, and CRUD HTTP APIs. Geocoding, maps, cleaner coordinates, and booking location snapshots are not stored here.

## Purpose

Stores customer service addresses owned by a user. Address ownership is always `user_id` from the authenticated persisted identity. Flutter cannot supply a trusted `user_id`.

A customer may create addresses before a customer profile exists. A default address cannot be selected until a profile exists, because `full_name` is required to create a profile.

## Document shape

```text
_id            ObjectId
user_id        ObjectId   (users._id; never taken from an HTTP body)
label          string
line1          string
line2          string?
city           string
region         string
postal_code    string
country_code   string     (ISO 3166-1 alpha-2, stored uppercase)
created_at     DateTime   (UTC)
updated_at     DateTime   (UTC)
```

Do **not** persist:

* `is_default`
* latitude / longitude
* geocoding payloads
* cleaner coordinates
* booking information

`is_default` is a **computed HTTP field** comparing `addresses._id` with `customer_profiles.default_address_id`.

## Ownership queries

Every read, update, and delete selector includes both `_id` and `user_id`. The repository does not load by id and then compare owners in application memory. Unknown and not-owned addresses both map to HTTP 404 `address_not_found`.

## Product limit

Maximum **20** addresses per customer. Before create, the service counts owned addresses. If the count is already 20, HTTP 409 `address_limit_reached`. This is an application-level product limit, not a database-enforced constraint.

Pagination is not required yet because the collection is capped by that limit. List sort is `created_at` descending.

## Default pointer interaction

See [customer-profiles-collection.md](customer-profiles-collection.md). Deleting the current default clears `customer_profiles.default_address_id` when it still matches, then deletes the address. That sequence is not a MongoDB multi-document transaction.

## Indexes

* `addresses_user_id` — `user_id` ascending
* `addresses_user_id_created_at` — `user_id` ascending, `created_at` descending

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## Validation (backend-owned)

* `label`: 1–40 Unicode code points after trim
* `line1`: 1–120
* `line2`: optional, max 120
* `city`: 1–80
* `region`: 1–80
* `postal_code`: 1–20 (not fully internationally validated)
* `country_code`: exactly two ASCII alphabetic characters, normalized to uppercase

## Live data policy

TASK 013 must not insert, update, delete, or dump live address documents. Automated tests use in-memory fakes. Only approved index metadata may be ensured on Atlas.
