# Home Cleaning Service Marketplace — Backend API

Dart package name: `home_cleaning_marketplace_api`

This directory is the Dart Frog backend API for the Home Cleaning Service Marketplace. It is a sibling of the Flutter client in `../project/`.

Current API version: `/api/v1`

MongoDB Atlas is the persistence provider. `mongo_dart` is the backend driver. Users persistence, Argon2id password hashing, access-token/refresh-session primitives, public authentication HTTP routes, account recovery/verification routes, and protected account routes now exist:

* `POST /api/v1/auth/signup` — creates account and issues verification; does not return tokens
* `POST /api/v1/auth/login`
* `POST /api/v1/auth/refresh`
* `POST /api/v1/auth/logout`
* `POST /api/v1/auth/email-verification/request`
* `POST /api/v1/auth/email-verification/verify`
* `POST /api/v1/auth/password-reset/request`
* `POST /api/v1/auth/password-reset/confirm`
* `GET /api/v1/account/me`
* `GET /api/v1/account/sessions`
* `DELETE /api/v1/account/sessions`
* `DELETE /api/v1/account/sessions/{sessionId}`
* `POST /api/v1/account/password/change`
* `GET`/`PUT /api/v1/customer/profile`
* customer address CRUD and default-address pointer
* `GET`/`PUT /api/v1/cleaner/profile`
* `POST /api/v1/cleaner/onboarding/submit`
* admin cleaner list, detail, approve, and reject
* public service catalog, cleaner offerings, availability, and customer discovery

TASK 015–019 may ensure approved booking, payment, conversation, notification, review, dispute, audit, earnings, payout, and user-listing indexes through the controlled index tool. It does not create live bookings, conversations, messages, notifications, reviews, disputes, audit rows, earnings, payout requests, users, or availability fixtures.

Do not place a real MongoDB URI, passwords, or other secrets in this package. Flutter never receives the MongoDB connection URI.

## Current endpoints

* `GET /` — service descriptor
* `GET /api/v1/health` — liveness; database-independent
* `GET /api/v1/ready` — readiness; MongoDB ping
* `POST /api/v1/auth/signup` — public customer/cleaner registration (verification required; no tokens returned)
* `POST /api/v1/auth/login` — password authentication (requires verified email)
* `POST /api/v1/auth/refresh` — refresh-token rotation
* `POST /api/v1/auth/logout` — idempotent session revocation
* `POST /api/v1/auth/email-verification/request` — enumeration-resistant verification re-request
* `POST /api/v1/auth/email-verification/verify` — consume verification token
* `POST /api/v1/auth/password-reset/request` — enumeration-resistant reset request
* `POST /api/v1/auth/password-reset/confirm` — consume reset token
* `GET /api/v1/account/me` — protected current account
* `GET /api/v1/account/sessions` — list owned active sessions
* `DELETE /api/v1/account/sessions` — revoke all refresh sessions
* `DELETE /api/v1/account/sessions/{sessionId}` — revoke one owned session
* `POST /api/v1/account/password/change` — authenticated password change
* `GET`/`PUT /api/v1/customer/profile`
* `GET`/`POST /api/v1/customer/addresses`
* `GET`/`PUT`/`DELETE /api/v1/customer/addresses/{addressId}`
* `PUT /api/v1/customer/addresses/{addressId}/default`
* `GET`/`PUT /api/v1/cleaner/profile`
* `POST /api/v1/cleaner/onboarding/submit`
* `GET /api/v1/admin/cleaners`
* `GET /api/v1/admin/cleaners/{userId}`
* `POST /api/v1/admin/cleaners/{userId}/approve`
* `POST /api/v1/admin/cleaners/{userId}/reject`
* `GET /api/v1/services`
* `GET`/`PUT`/`DELETE /api/v1/cleaner/services[/{serviceId}]`
* `GET`/`POST`/`PUT`/`DELETE /api/v1/cleaner/availability[/{slotId}]`
* `GET /api/v1/discovery/cleaners[/{cleanerUserId}]`
* `GET`/`POST /api/v1/customer/bookings`
* `GET /api/v1/customer/bookings/{bookingId}`
* `POST /api/v1/customer/bookings/{bookingId}/cancel`
* `GET /api/v1/cleaner/bookings`
* `GET /api/v1/cleaner/bookings/{bookingId}`
* `POST /api/v1/cleaner/bookings/{bookingId}/accept|decline|cancel|start|complete`
* customer/cleaner booking-scoped conversations and messages
* in-app notifications list/unread-count/read/read-all
* `GET`/`PUT /api/v1/customer/bookings/{bookingId}/review`
* `GET /api/v1/cleaner/reviews`
* admin review list/detail/hide/unhide
* participant booking dispute create/get/close
* admin disputes, users, bookings, and audit-log list/detail
* cleaner earnings summary/ledger and payout request/list/cancel
* admin payouts process/reject, finance summary, reconciliation, cleaner finance
* sandbox payout webhook and development payout simulate (dev only)

See [../documentation/api/authentication-api.md](../documentation/api/authentication-api.md), [../documentation/api/profile-address-onboarding-admin-api.md](../documentation/api/profile-address-onboarding-admin-api.md), [../documentation/api/services-availability-discovery-api.md](../documentation/api/services-availability-discovery-api.md), [../documentation/api/booking-api.md](../documentation/api/booking-api.md), [../documentation/api/payment-api.md](../documentation/api/payment-api.md), [../documentation/api/chat-api.md](../documentation/api/chat-api.md), [../documentation/api/notification-api.md](../documentation/api/notification-api.md), [../documentation/api/review-api.md](../documentation/api/review-api.md), [../documentation/api/dispute-api.md](../documentation/api/dispute-api.md), [../documentation/api/admin-operations-api.md](../documentation/api/admin-operations-api.md), [../documentation/api/earnings-and-payout-api.md](../documentation/api/earnings-and-payout-api.md), and [../documentation/architecture/protected-api-authentication.md](../documentation/architecture/protected-api-authentication.md). These auth endpoints require production rate limiting before unrestricted internet exposure. WebSockets, push notifications, password recovery, MFA, AI moderation, a production payment processor, and a real payout provider are still absent. Sandbox payouts do not transfer real money.

## Configuration

Public, non-secret process environment variables currently supported:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated browser origins for CORS
* `PLATFORM_COMMISSION_BPS` — integer 0–10000; not a secret; development/test default 1500 when unset

`ALLOWED_ORIGINS` is not a secret. In development, if it is absent, localhost and 127.0.0.1 origins are permitted. Production must set an explicit allow-list and never rely on `Access-Control-Allow-Origin: *`.

Secret / deployment environment variables:

* `MONGODB_URI` — required for database readiness (`GET /api/v1/ready`)
* `ACCESS_TOKEN_SECRET` — HS256 access-token signing secret; required to issue tokens from auth routes. The process can still start without it. Auth routes then return HTTP 503.
* `SANDBOX_PAYMENT_WEBHOOK_SECRET` — backend-only HMAC secret for sandbox payment webhooks (minimum 32 UTF-8 bytes)
* `SANDBOX_PAYOUT_WEBHOOK_SECRET` — backend-only HMAC secret for sandbox payout webhooks (minimum 32 UTF-8 bytes)

There is no default MongoDB URI and no default access-token secret. The process can still start and serve liveness health when `MONGODB_URI` or `ACCESS_TOKEN_SECRET` is missing. Missing sandbox secrets report those adapters unavailable without blocking boot.

## Local development

Local development may load `backend/.env`. Production and other deployed environments should use real process environment variables instead of a committed file.

`.env` must never be committed. Copy the placeholders from `.env.example`:

```text
APP_ENV=development
ALLOWED_ORIGINS=
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@CLUSTER_HOST/home_cleaning_marketplace
ACCESS_TOKEN_SECRET=<replace-with-a-strong-random-secret>
SANDBOX_PAYMENT_WEBHOOK_SECRET=
SANDBOX_PAYOUT_WEBHOOK_SECRET=
PLATFORM_COMMISSION_BPS=1500
```

Replace the placeholders with values from your private Atlas configuration. Do not commit the real file.

From this directory:

```bash
dart pub get
dart_frog dev
dart analyze
dart test
```

The development server defaults to port 8080.

When the Flutter Android emulator calls this API, use `http://10.0.2.2:8080` instead of `http://localhost:8080`, because emulator `localhost` refers to the emulator itself. Do not hardcode `10.0.2.2` into production Flutter code. Debug Android builds may allow that local HTTP exception. Production API traffic must use HTTPS. `ACCESS_TOKEN_SECRET` is backend-only configuration; never put it in Flutter.

## Architecture directories

* `routes/` — Dart Frog HTTP entrypoints
* `lib/src/config/` — environment loading and server configuration
* `lib/src/database/` — MongoDB connection lifecycle and collection names
* `lib/src/features/users/` — user account persistence model and repository
* `lib/src/features/account/` — current-account use cases for protected routes
* `lib/src/features/authorization/` — persisted-user role authorization
* `lib/src/features/customer_profiles/` — customer profile application/repository
* `lib/src/features/addresses/` — owned service addresses
* `lib/src/features/cleaner_profiles/` — cleaner onboarding and admin review
* `lib/src/features/services/` — platform catalog
* `lib/src/features/cleaner_services/` — cleaner offerings
* `lib/src/features/availability/` — UTC availability slots
* `lib/src/features/bookings/` — booking reservation and lifecycle
* `lib/src/features/payments/` — sandbox payment ledger and webhooks
* `lib/src/features/earnings/` — append-only earnings ledger and settlement
* `lib/src/features/payouts/` — payout requests, sandbox provider, and webhooks
* `lib/src/features/finance/` — admin finance summary and reconciliation
* `lib/src/features/chat/` — booking-scoped conversations and messages
* `lib/src/features/notifications/` — in-app notification feed
* `lib/src/features/reviews/` — verified reviews and admin moderation
* `lib/src/features/account/` — account security use cases
* `lib/src/features/account_actions/` — hashed one-time verification/reset tokens and delivery boundary
* `lib/src/features/auth/application/` — authentication use cases
* `lib/src/features/auth/http/` — auth JSON parsing, Bearer verification, and error mapping
* `lib/src/features/auth/security/` — password policy and Argon2id hashing
* `lib/src/features/auth/tokens/` — access JWT and refresh-token primitives
* `lib/src/features/auth/sessions/` — user session persistence and rotation
* `lib/src/http/` — JSON and CORS helpers
* `tool/` — controlled database index setup
* `test/` — backend tests

Business logic should not accumulate in route handlers. Future features should add services and repositories under `lib/src/` when they are needed.

## Current limitations

* Unique `users.email_normalized` index
* Argon2id password hashing
* Access JWT and refresh-session primitives
* Approved `user_sessions` and `account_action_tokens` indexes
* Public authentication HTTP routes (signup without tokens, login, refresh, logout)
* Account recovery/verification routes and protected account security routes
* Protected account routes (`GET /account/me`, session list/revoke, password change)
* Role-scoped customer profile and address routes
* Cleaner onboarding and admin review routes
* Platform service catalog, cleaner offerings, availability, customer discovery, and booking reservation/lifecycle
* Sandbox payment ledger, signed webhooks, and refund foundation
* Booking-scoped chat, in-app notifications, verified reviews, and admin moderation
* Approved indexes for profiles, catalog, bookings, payments, conversations, messages, notifications, reviews, disputes, audit, earnings, and payouts
* No production email delivery, payment or payout processor, WebSockets, or push notifications
* No production rate limiting yet
* CORS is a small development-oriented foundation, not a complete production security policy
