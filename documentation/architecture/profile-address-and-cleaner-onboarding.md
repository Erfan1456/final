# Profile, Address, and Cleaner Onboarding Architecture

TASK 013 adds role-scoped customer profiles, service addresses, cleaner onboarding, and administrator review. Bookings, payments, chat, reviews, cleaner services/availability, earnings, and discovery remain unimplemented.

## Request path

```text
Flutter authenticated Dio
    ↓ HTTPS / REST + Bearer access JWT
Dart Frog role middleware
    ↓ AccessAuthenticator (JWT verification)
CurrentAuthenticatedUserResolver (users collection)
    ↓ account_status == active
RoleAuthorizer (persisted UserAccount.role)
    ↓ AuthenticatedUserContext
Application service
    ↓
Repository (ownership / conditional selectors)
    ↓
MongoDB Atlas
```

JWT role is **not** used as the sole authorization source. Access tokens may be up to 15 minutes stale. Persisted `users.role` and `account_status` are authoritative for these routes.

See [protected-api-authentication.md](protected-api-authentication.md) and [flutter-authentication.md](flutter-authentication.md).

## Backend features

```text
backend/lib/src/features/authorization/     role middleware and persisted-user authorizer
backend/lib/src/features/customer_profiles/ customer profile domain/data/application
backend/lib/src/features/addresses/         address domain/data
backend/lib/src/features/cleaner_profiles/  onboarding + admin review
```

HTTP handlers stay thin: method, JSON parse, DTO checks, service call, error mapping, safe JSON.

## Customer flow

1. Customer authenticates (TASK 012).
2. `GET /api/v1/customer/profile` may return `null`.
3. `PUT /api/v1/customer/profile` upserts by authenticated `user_id`.
4. Addresses are listed/created independently; default selection requires a profile.
5. Default is a pointer on the customer profile, not a boolean on each address.
6. Deletes that match the default pointer clear it, then delete the address (not a multi-document transaction).

## Address flow

Ownership is `_id` AND `user_id` in every mutating/read selector. The 20-address cap is counted in the application service before insert. HTTP `is_default` is computed at serialization time.

## Cleaner onboarding lifecycle

One `cleaner_profiles` document carries `draft → pending → approved | rejected`. Rejected cleaners edit and resubmit on the same document. Submit/approve/reject use conditional atomic updates. Approval does not change `users.role`.

## Admin review flow

Administrators list applications with `status` (default `pending`), `limit` (1–50, default 20), and `after` ObjectId cursor. Email is joined via a batch `users` lookup, not N+1 per row. Approve/reject record `reviewed_by` as the current admin user id.

Public signup still cannot register `admin`.

## Flutter architecture

Reuse TASK 012:

* `AuthUser` / `AuthController` (session only)
* `authenticatedDioProvider` (Bearer + single-flight refresh)
* Riverpod
* go_router

Feature APIs (`CustomerProfileApi`, `AddressApi`, `CleanerProfileApi`, `AdminCleanerApi`) wrap the shared authenticated Dio. There is no second refresh coordinator.

Controllers:

* `CustomerProfileController`
* `AddressController`
* `CleanerOnboardingController`
* `AdminCleanerReviewController`

Role routing:

```text
restoring        → /splash
unauthenticated  → /login
customer         → /customer/home
cleaner          → /cleaner/home
admin            → /admin/home
```

`/home` redirects to the role home. Opening another role's path redirects to the user's own home. Router guards are UX only. Backend authorization remains authoritative.

Unknown cleaner `onboarding_status` values map to a client `unknown` enum member and do not crash the app.
