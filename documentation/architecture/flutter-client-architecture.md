# Flutter Client Architecture

This document describes the Flutter client architecture for the Home Cleaning Service Marketplace.

TASK 005 established infrastructure and a foundation screen only. Marketplace features such as authentication, booking, cleaner search, and API integration are not implemented.

## Architecture Goals

* scalability as Customer, Cleaner, and Administrator functionality grows
* maintainability through feature isolation
* testability via replaceable dependencies
* clear dependency boundaries
* avoiding business logic in widgets

## High-Level Flow

```text
View
  ↓
View Model
  ↓
Repository
  ↓
Service
  ↓
Dart backend API
```

An optional domain/use-case layer may sit between view models and repositories when logic combines multiple repositories, becomes complex, or is reused. It is not required for every feature or every repository method.

Flutter never directly accesses MongoDB Atlas. Database credentials and URIs belong only to backend environment configuration.

## Folder Strategy

```text
lib/app/        application shell: bootstrap widget, routing, theme
lib/core/       cross-cutting infrastructure shared by features
lib/features/   product functionality, grouped by feature
```

`lib/app/` owns the running application: `HomeCleaningMarketplaceApp`, `go_router` configuration, and the Material theme boundary.

`lib/core/` owns shared infrastructure such as public runtime configuration and the Dio HTTP client. Feature-specific business code does not belong here.

`lib/features/` owns product code. A mature feature may eventually resemble:

```text
features/
└── authentication/
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── services/
    ├── presentation/
    │   ├── views/
    │   ├── view_models/
    │   └── widgets/
    └── domain/               ← optional, only when justified
        └── use_cases/
```

Those nested folders are created only when a real feature needs them. Empty architecture folders are not created for unimplemented features.

Authentication now lives under `features/auth/`. Customer, address, cleaner, admin, catalog, cleaner_services, availability, and discovery feature folders exist. See [flutter-authentication.md](flutter-authentication.md), [profile-address-and-cleaner-onboarding.md](profile-address-and-cleaner-onboarding.md), and [service-availability-and-discovery.md](service-availability-and-discovery.md).

## State Management

Riverpod provides:

* application state management
* view-model state
* asynchronous state
* dependency injection
* test overrides

Future feature view models may use `Notifier` or `AsyncNotifier` when they have real presentation logic. Fake view models are not created merely to demonstrate Riverpod.

## Routing

`go_router` provides declarative navigation, a route hierarchy, and a boundary for later deep linking and authentication/role redirects.

TASK 012 registers `/splash`, `/login`, `/signup`, and a compatibility `/home` redirect. TASK 013 adds role destinations `/customer/home`, `/cleaner/home`, and `/admin/home` plus profile, address, onboarding, and admin approval screens. TASK 014 adds cleaner service/availability management and customer discovery, detail, and comparison routes. TASK 015 adds `/customer/book/:cleanerUserId/:slotId`, `/customer/bookings`, `/customer/bookings/:bookingId`, `/cleaner/bookings`, and `/cleaner/bookings/:bookingId`. Router guards are UX only; backend authorization remains authoritative. Payments, chat, and reviews remain unimplemented.

## Networking

Dio is the HTTP transport for communication with the Dart backend. It is configured from public `AppConfig` values such as `API_BASE_URL`.

Plain Dio is used for public auth calls. Authenticated Dio attaches Bearer tokens and performs single-flight refresh. See [flutter-authentication.md](flutter-authentication.md).

`API_BASE_URL` is public runtime configuration, not a secret. MongoDB URIs, passwords, tokens, and private credentials must never be placed in the Flutter client.

## Dependency Rules

Dependencies should generally flow inward/downward:

```text
View
 ↓
View Model
 ↓
Repository abstraction
 ↓
Repository implementation
 ↓
Service
 ↓
External system
```

Allowed:

* views depend on view models and shared UI
* view models depend on repository abstractions
* repository implementations depend on services
* services depend on Dio / platform APIs

Forbidden:

* lower layers importing feature presentation classes
* widgets calling Dio or embedding business/data logic
* Flutter source containing MongoDB connection details

## Testing Strategy

As features are implemented, tests should cover:

* service tests for external API/platform wrappers
* repository tests for data coordination and rules
* view-model tests for presentation state and commands
* widget/view tests for rendering and user interaction
* integration tests for composed flows

TASK 012 includes authentication unit, interceptor, repository, controller, router, and widget tests in addition to the earlier application smoke test and `AppConfig` tests.

## Domain Layer Policy

The domain/use-case layer is optional. Add it only when justified by complexity, reuse, or coordination across repositories. Do not require one use-case for every trivial repository method.

## Current State

TASK 015 adds booking model/API/controller/widget/router tests. Payments, chat, and reviews are not implemented.
