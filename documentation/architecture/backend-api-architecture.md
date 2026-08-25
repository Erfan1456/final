# Backend API Architecture

This document describes the Dart Frog backend for the Home Cleaning Service Marketplace.

TASK 013 added role-scoped customer profile, address, cleaner onboarding, and admin review routes. TASK 014 added the public service catalog, cleaner offerings, availability, and customer discovery. TASK 015 added customer/cleaner booking reservation and lifecycle. TASK 016 added a sandbox-backed payment ledger, signed webhooks, refund foundation, and admin transaction inspection. There is no production payment processor, chat, or reviews.

## Current Architecture

```text
Flutter client
     ↓ HTTP
Dart Frog routes
     ↓
MongoDatabase
     ↓
mongo_dart
     ↓
MongoDB Atlas
```

MongoDB credentials exist only on the backend/server environment. Flutter will never receive the MongoDB URI.

See [../database/mongodb-atlas-integration.md](../database/mongodb-atlas-integration.md), [../database/users-collection.md](../database/users-collection.md), [../database/user-sessions-collection.md](../database/user-sessions-collection.md), [../database/customer-profiles-collection.md](../database/customer-profiles-collection.md), [../database/cleaner-profiles-collection.md](../database/cleaner-profiles-collection.md), [../database/addresses-collection.md](../database/addresses-collection.md), [../database/services-collection.md](../database/services-collection.md), [../database/cleaner-services-collection.md](../database/cleaner-services-collection.md), [../database/availability-slots-collection.md](../database/availability-slots-collection.md), [../database/bookings-collection.md](../database/bookings-collection.md), [password-security.md](password-security.md), [auth-token-and-session-security.md](auth-token-and-session-security.md), [authentication-application-flow.md](authentication-application-flow.md), [protected-api-authentication.md](protected-api-authentication.md), [flutter-authentication.md](flutter-authentication.md), [profile-address-and-cleaner-onboarding.md](profile-address-and-cleaner-onboarding.md), [service-availability-and-discovery.md](service-availability-and-discovery.md), [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md), [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md), [../decisions/ADR-007-password-hashing-and-policy.md](../decisions/ADR-007-password-hashing-and-policy.md), [../decisions/ADR-008-access-and-refresh-token-strategy.md](../decisions/ADR-008-access-and-refresh-token-strategy.md), [../decisions/ADR-009-authentication-application-flow.md](../decisions/ADR-009-authentication-application-flow.md), [../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md](../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md), [../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md](../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md), [../decisions/ADR-012-service-offerings-availability-and-discovery.md](../decisions/ADR-012-service-offerings-availability-and-discovery.md), and [../decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md](../decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md).

## Dart Frog Responsibilities

* HTTP server framework
* route discovery from `routes/`
* middleware
* request/response abstraction
* development server (`dart_frog dev`)
* production build support
* shared `MongoDatabase` provider for future data-backed routes

## Folder Responsibilities

### `backend/routes/`

Framework HTTP entrypoints. Dart Frog maps files such as `routes/api/v1/health.dart` to `/api/v1/health`.

Route handlers should stay thin. Business logic should not accumulate here. Future routes should delegate to services and repositories as features appear.

### `backend/lib/src/`

Reusable application/backend implementation, including configuration, environment loading, MongoDB lifecycle, HTTP helpers, users persistence, password-security primitives, and access-token/refresh-session primitives. Feature-specific models, repositories, and services are added only when real functionality requires them.

## API Versioning

The initial REST namespace is:

```text
/api/v1
```

Current implemented routes:

```text
GET /
GET /api/v1/health
GET /api/v1/ready
POST /api/v1/auth/signup
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET /api/v1/account/me
DELETE /api/v1/account/sessions
GET /api/v1/customer/profile
PUT /api/v1/customer/profile
GET /api/v1/customer/addresses
POST /api/v1/customer/addresses
GET /api/v1/customer/addresses/<addressId>
PUT /api/v1/customer/addresses/<addressId>
DELETE /api/v1/customer/addresses/<addressId>
PUT /api/v1/customer/addresses/<addressId>/default
GET /api/v1/cleaner/profile
PUT /api/v1/cleaner/profile
POST /api/v1/cleaner/onboarding/submit
GET /api/v1/admin/cleaners
GET /api/v1/admin/cleaners/<userId>
POST /api/v1/admin/cleaners/<userId>/approve
POST /api/v1/admin/cleaners/<userId>/reject
GET /api/v1/services
GET /api/v1/cleaner/services
PUT /api/v1/cleaner/services/<serviceId>
DELETE /api/v1/cleaner/services/<serviceId>
GET /api/v1/cleaner/availability
POST /api/v1/cleaner/availability
GET /api/v1/cleaner/availability/<slotId>
PUT /api/v1/cleaner/availability/<slotId>
DELETE /api/v1/cleaner/availability/<slotId>
GET /api/v1/discovery/cleaners
GET /api/v1/discovery/cleaners/<cleanerUserId>
GET /api/v1/customer/bookings
POST /api/v1/customer/bookings
GET /api/v1/customer/bookings/<bookingId>
POST /api/v1/customer/bookings/<bookingId>/cancel
GET /api/v1/cleaner/bookings
GET /api/v1/cleaner/bookings/<bookingId>
POST /api/v1/cleaner/bookings/<bookingId>/accept
POST /api/v1/cleaner/bookings/<bookingId>/decline
POST /api/v1/cleaner/bookings/<bookingId>/cancel
POST /api/v1/cleaner/bookings/<bookingId>/start
POST /api/v1/cleaner/bookings/<bookingId>/complete
```

`GET /api/v1/health` is liveness and does not depend on MongoDB. `GET /api/v1/ready` is readiness and performs a MongoDB ping. Authentication routes are documented in [../api/authentication-api.md](../api/authentication-api.md). Role-scoped profile, address, onboarding, and admin review routes are documented in [../api/profile-address-onboarding-admin-api.md](../api/profile-address-onboarding-admin-api.md). Catalog, offering, availability, and discovery routes are documented in [../api/services-availability-discovery-api.md](../api/services-availability-discovery-api.md). Booking routes are documented in [../api/booking-api.md](../api/booking-api.md). See also [authentication-application-flow.md](authentication-application-flow.md), [protected-api-authentication.md](protected-api-authentication.md), [profile-address-and-cleaner-onboarding.md](profile-address-and-cleaner-onboarding.md), [service-availability-and-discovery.md](service-availability-and-discovery.md), [booking-reservation-and-lifecycle.md](booking-reservation-and-lifecycle.md), and [../decisions/ADR-009-authentication-application-flow.md](../decisions/ADR-009-authentication-application-flow.md).

## Configuration

Process environment variables:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated CORS origins
* `MONGODB_URI` — Atlas connection URI; required for readiness, never logged
* `ACCESS_TOKEN_SECRET` — HS256 signing secret; required only when the token service is constructed, never logged, no default

Local development may additionally load `backend/.env`. Process environment values take precedence over file values. Production should use deployment environment variables. Absence of `.env` must not prevent startup.

These public settings are not secrets. `MONGODB_URI` and `ACCESS_TOKEN_SECRET` are secrets and must not appear in Git, Flutter, logs, or HTTP responses.

## Security Boundary

```text
MongoDB credentials will exist only on the backend/server environment.
```

Flutter will never receive the MongoDB URI. The Flutter client will call this API over HTTPS/HTTP. Android emulator access to a Windows development server typically uses `http://10.0.2.2:<port>` instead of `http://localhost:<port>`.

## Current State

Backend infrastructure, liveness health, MongoDB connectivity, ping readiness, users persistence, Argon2id password-security primitives, access-token/refresh-session primitives, public authentication HTTP routes, and protected account routes exist.

There is still no chat or review product. Auth endpoints are not ready for unrestricted public internet exposure until production rate limiting is added. TASK 016 payment is a development/test sandbox ledger only; it is not a production card processor.
