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

Those nested folders are created only when a real feature needs them. Empty architecture folders are not created for unimplemented features. The current `foundation` feature contains only a presentation screen because it has no data, domain, or view-model requirements.

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

TASK 005 registers only the foundation route `/`. Product routes are added when those screens exist.

## Networking

Dio is the HTTP transport for future communication with the Dart backend. It is configured from public `AppConfig` values such as `API_BASE_URL`.

Flutter never directly accesses MongoDB Atlas.

Feature views must not call Dio directly. Future feature services should depend on the shared Dio provider rather than constructing arbitrary clients. TASK 005 does not perform HTTP requests and does not add authentication interceptors or token handling.

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

TASK 005 includes an application smoke test and `AppConfig` unit tests only.

## Domain Layer Policy

The domain/use-case layer is optional. Add it only when justified by complexity, reuse, or coordination across repositories. Do not require one use-case for every trivial repository method.

## Current State

TASK 005 contains only architecture infrastructure and a foundation screen that proves bootstrap, routing, theme, and feature organization. No marketplace product features are implemented.
