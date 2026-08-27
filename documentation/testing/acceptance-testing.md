# Acceptance testing

How cross-feature Flutter acceptance tests are structured for the Home Cleaning Service Marketplace.

## Architecture

Acceptance tests live under:

```text
project/test/acceptance/
```

They pump the real `HomeCleaningMarketplaceApp` (go_router + Riverpod) with:

- `SeededAuthController` from `project/test/helpers/auth_test_fakes.dart`
- seeded feature controllers from `project/test/helpers/feature_test_fakes.dart`
- helpers in `acceptance_harness.dart`

Tests exercise **router + screens + meaningful state transitions** together. They do not replace lower-level unit/widget tests.

Optional Flutter SDK `integration_test` is allowed but not required. Prefer `project/test/acceptance/` widget acceptance tests.

## Why no live Atlas

Acceptance fixtures are **fake only**.

Live MongoDB Atlas mutation is rejected for acceptance because it:

- pollutes shared development data
- is non-reproducible across machines
- risks leaking real emails, tokens, payment/payout records into fixtures
- couples CI to network and secrets

Backend service tests may use in-memory fakes; Flutter acceptance must not point at production backends or real Atlas.

## Fake / test seams

| Seam | Role |
| --- | --- |
| `SeededAuthController` | Auth status, login/logout, session expiry |
| `featureControllerOverrides()` | Default empty/safe feature states |
| Per-test `extraOverrides` | Seed approved onboarding, errors, discovery items, etc. |
| `pumpAcceptanceApp` | Full app shell with overrides |

Obvious fake emails/ids only (for example `person@example.com`, fixed ObjectId-looking hex strings from helpers).

## Customer journey

`customer_journey_test.dart` covers a pragmatic path:

unauthenticated → signup → verification-pending → authenticated customer home → discovery / bookings / notifications / security / booking chat-review-dispute → logout

Also asserts foreign role routes redirect to customer home.

## Cleaner journey

`cleaner_journey_test.dart` covers:

approved cleaner home → onboarding / services / availability / bookings / chat / earnings / payout request (sandbox banner) / payout history / reviews / notifications / security → logout

Foreign customer/admin routes redirect home.

## Admin journey

`admin_journey_test.dart` covers:

admin home → approvals / users / bookings / payments / disputes / reviews / payouts / finance / reconciliation / audit / notifications / security → logout

Foreign customer/cleaner routes redirect home.

## Role routing matrix

Covered in acceptance failure/routing tests and existing `project/test/app/router/app_router_test.dart`:

| Auth | Allowed | Redirect |
| --- | --- | --- |
| Unauthenticated | login, signup, verify-email-pending, forgot/reset password | protected → login |
| Customer | customer + shared notifications/security | cleaner/admin → customer home |
| Cleaner | cleaner + shared notifications/security | customer/admin → cleaner home |
| Admin | admin + shared notifications/security | customer/cleaner ops → admin home |
| Session invalidated | — | login |

Backend authorization remains required; UI guards are not sufficient alone.

## Failure-path coverage

`failure_and_routing_acceptance_test.dart` includes:

- `AppErrorState` Try Again presentation
- discovery network-ish error text
- unauthenticated protected → login
- foreign role redirect
- session invalidation → login
- `email_not_verified` guidance on login

Additional mutation failures (booking conflict, payment, payout balance, dispute) remain covered primarily by feature widget/controller tests.

## Duplicate-submit coverage

Important mutations (booking create, payment start, payout request, review save, dispute create, password change, message send) disable submit while in-flight in their screens/controllers. Prefer feature-level tests for rapid-tap protections; acceptance journeys assert logout and navigation rather than every mutation race.

## Logout state isolation

`logout_state_cleanup_test.dart` keeps one `ProviderScope` across logout→login and proves prior-user bookings, chat, notifications, profile, earnings, and admin markers are not visible to the next identity. Production controllers watch authenticated user id (`auth_identity.dart`) so the same root scope cannot leak user-scoped state.

## Session revoke confirmations

`session_management_screen_test.dart` covers destructive confirmation for revoke-all, revoke-other, and revoke-current (cancel keeps session; confirm runs revoke path; current-session confirm clears local auth).

## Responsive / accessibility checks

`responsive_accessibility_test.dart` pumps:

Login, Signup, CustomerHome, CleanerHome, AdminHome, AccountSecurity

at `Size(360, 640)` with text scale ≈ `2.0`, capturing overflow via `FlutterError.onError`.

## Commands

From the repository root:

```bash
cd project
flutter test test/acceptance
flutter test test/shared/presentation/app_formatters_test.dart
flutter test
```

Do not configure these tests against a live API base URL or Atlas URI.
