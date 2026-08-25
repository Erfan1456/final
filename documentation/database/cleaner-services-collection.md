# Cleaner Services Collection

This document describes the `cleaner_services` collection.

TASK 014 stores a cleaner's offering of a platform service. Full name, bio, phone, email, service name, and service slug are **not** duplicated here; those remain on `users`, `cleaner_profiles`, and `services`.

## Purpose

One document per cleaner + platform service. The row is the stable offering identity future bookings can reference.

## Document shape

```text
_id                 ObjectId
cleaner_user_id     ObjectId   (users._id; never taken from an HTTP body)
service_id          ObjectId   (services._id)
hourly_rate_minor   int        (minor units of currency_code; never float)
currency_code       string     (exactly three ASCII letters, stored uppercase)
is_active           bool
created_at          DateTime   (UTC)
updated_at          DateTime   (UTC)
```

## Money representation

`hourly_rate_minor` is an integer amount in the selected currency's minor unit. TASK 014 does not implement an ISO-4217 decimal-place table and does not convert currencies.

Validation: integer only, minimum 1, maximum 100000000. No negatives, doubles, or string numbers.

## Ownership and approval

A cleaner may mutate offerings only when:

* persisted `users.role == cleaner`
* `account_status == active`
* `cleaner_profiles.onboarding_status == approved`

Owner identity always comes from the authenticated persisted user. Request bodies cannot set `cleaner_user_id`, `service_id` different from the route, `created_at`, or `updated_at`.

The platform service must exist and `active == true`. Otherwise HTTP 404 `service_not_found`.

## Lifecycle

PUT upserts `hourly_rate_minor`, `currency_code`, `is_active`, and `updated_at`. `_id`, `cleaner_user_id`, `service_id`, and `created_at` are preserved.

DELETE performs **logical deactivation** (`is_active = false`). The row is not physically deleted so future booking history can keep a stable offering relationship. PUT may reactivate later.

## Indexes

* `cleaner_services_cleaner_service_unique` — unique `cleaner_user_id` + `service_id`
* `cleaner_services_service_active_id` — `service_id`, `is_active`, `_id`
* `cleaner_services_service_currency_rate_id` — `service_id`, `currency_code`, `is_active`, `hourly_rate_minor`, `_id`

The unique compound index enforces one offering per cleaner/service. Discovery listing uses the service/active/`_id` prefix for keyset pagination. Currency/rate filtering uses the longer compound index.

## Live data policy

TASK 014 must not insert, update, delete, or dump live `cleaner_services` belonging to real cleaners. Automated tests use in-memory fakes. Only approved index metadata may be ensured on Atlas.
