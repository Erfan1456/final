# ADR-011 — Role-Scoped Profiles, Addresses, and Cleaner Onboarding

## Status

Accepted

## Context

TASK 012 authenticates callers with Bearer access JWTs and exposes `/account/me` plus session revocation. The marketplace still had no customer profile, no service addresses, no cleaner onboarding, and no administrator approval queue. JWT `role` can be up to 15 minutes stale. Customer and cleaner data must not overload the `users` security identity document. Default-address selection must not allow multiple simultaneous defaults. Cleaner review must survive concurrent submit/approve/reject.

## Decision

* Store customer marketplace data in `customer_profiles` (exactly one document per customer user).
* Store cleaner onboarding data in `cleaner_profiles` (exactly one document per cleaner user).
* Store service addresses in a separate `addresses` collection owned by `user_id`.
* Keep `default_address_id` on the customer profile rather than `is_default` on every address.
* Enforce a maximum of 20 customer addresses in application code.
* Represent cleaner onboarding as `draft | pending | approved | rejected` on the single cleaner profile.
* Perform submit/approve/reject with conditional atomic Mongo selectors.
* Authorize role-scoped routes from the current persisted `UserAccount` after Bearer verification, not from the JWT role claim alone.
* Record admin review metadata (`reviewed_at`, `reviewed_by`, `rejection_reason`) on the cleaner profile without changing `users.role`.
* Page the admin queue with `status`, `limit`, and an `_id` cursor (`after`).
* Keep admin out of public signup. TASK 013 only supports an already-provisioned administrator.
* Give Flutter role-aware dashboards (`/customer/home`, `/cleaner/home`, `/admin/home`) as UX guards only.

## Alternatives Considered

### Store profile fields directly on users

Rejected because role-specific data/lifecycle would overload security identity.

### Persist is_default on every address

Not selected because a profile pointer provides one authoritative default.

### Create one onboarding record per submission

Not selected for current workflow; one cleaner profile carries current lifecycle.

### Authorize only using JWT role

Rejected because claims can become stale before access-token expiry.

### Read status then perform unconditional onboarding update

Rejected due concurrency race.

### Allow cleaner edits while pending

Rejected for current review integrity.

## Consequences

* Customer profile and addresses can exist independently except default selection, which requires a profile.
* Address HTTP `is_default` is computed and never persisted.
* Clearing the default pointer then deleting an address is not a multi-document transaction; the application still avoids a dangling pointer.
* Cleaners remain `users.role = cleaner` whether draft, pending, approved, or rejected.
* Stale JWT role cannot grant another role's routes while the persisted role differs.
* Flutter feature APIs inherit TASK 012 single-flight refresh through authenticated Dio.
* Bookings, payments, chat, reviews, services, availability, and geospatial search remain out of scope.

## Security

* Request-body `user_id` cannot override the authenticated owner.
* Address selectors include `_id` and `user_id`.
* Password hashes, token hashes, and refresh sessions are never serialized on these APIs.
* Wrong-role responses use generic 403 `forbidden`.
* Admin routes are not exposed by public signup.
* Flutter stores no MongoDB URI and no `ACCESS_TOKEN_SECRET`.
* Feature clients do not log tokens or passwords.

## Deferred Decisions

* verification-document uploads
* cleaner service catalog
* cleaner availability
* booking
* payment
* chat
* review
* admin user management
* disputes
* geospatial search
* address geocoding
* phone verification
