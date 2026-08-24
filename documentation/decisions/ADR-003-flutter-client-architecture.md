# ADR-003 — Flutter Client Architecture

## Status

Accepted.

## Context

The application will grow across Customer, Cleaner, and Administrator functionality. It needs testable boundaries, a navigation shell, shared HTTP transport, and a feature-oriented source layout before those product features are implemented.

The Flutter package still had the generated counter template. Architecture choices are being recorded now so feature work does not invent conflicting patterns later.

## Decision

Use:

```text
Feature-oriented layered organization
Riverpod for state management and dependency injection
go_router for navigation
Dio for HTTP transport
Repository/service separation
Optional domain/use-case layer
```

Conceptual layering:

```text
UI / Presentation
        ↓
View Models / State
        ↓
Repositories
        ↓
Services
        ↓
External API / platform
```

The Flutter client never connects directly to MongoDB Atlas. HTTP communication will go to a Dart backend API.

## Alternatives Considered

### Global layer-first organization

Example:

```text
lib/screens/
lib/models/
lib/repositories/
lib/services/
```

Not selected as the primary structure because large applications can become difficult to navigate when code for one feature is spread throughout the project.

### BLoC

Viable but not selected because Riverpod supplies both state management and dependency injection with less architectural duplication for this project.

### Provider/ChangeNotifier only

Viable for simpler applications, but Riverpod was selected for scalable dependency composition, async-state handling, test overrides, and avoiding BuildContext dependency.

### GetIt service locator

Not selected because Riverpod will already provide dependency management and introducing a second DI system is unnecessary.

### Direct `Navigator` calls everywhere

Not selected because centralized declarative routing is more appropriate for future deep links and authentication/role redirection.

### Flutter `http` package

Viable, but Dio selected for richer request configuration, cancellation, interceptors, and future authentication/error-handling requirements.

## Consequences

Advantages:

* feature boundaries remain clear;
* testing and dependency replacement become easier;
* future role-aware routing is supported;
* HTTP transport is centralized below presentation.

Tradeoffs:

* several architecture concepts must be learned;
* `flutter_riverpod`, `go_router`, and `dio` become project dependencies;
* Dio must remain below presentation/repository boundaries;
* unnecessary layers should still be avoided.

TASK 005 installs those packages and bootstraps routing, theme, configuration, and Dio without implementing product features.

## Deferred Decisions

* authentication flow
* token storage
* secure storage package
* role-based routing
* local database/cache
* offline mode
* JSON/model code generation
* API error/result model
* analytics
* push notifications
* final UI design system
