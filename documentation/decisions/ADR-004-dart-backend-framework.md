# ADR-004 — Dart Backend Framework

## Status

Accepted.

## Context

The project requires a trusted server between Flutter and MongoDB. Database credentials and business rules must not live in a distributable mobile client.

The developer wants to remain in Dart unless another language becomes necessary.

The backend needs REST routing, middleware, testing, and production deployability.

## Decision

Use:

```text
Dart Frog
```

for the backend.

Keep backend source in:

```text
backend/
```

as a sibling of:

```text
project/
```

The Dart package name is `home_cleaning_marketplace_api`. The initial REST namespace is `/api/v1`. MongoDB integration is deferred to a later task.

## Alternatives Considered

### Flutter directly connecting to MongoDB

Rejected for security and trusted-business-logic reasons. A distributable client must not contain the MongoDB URI.

### Node.js / TypeScript

Technically strong but not selected because the project intentionally remains Dart-first.

### Raw Shelf

Viable and stable, but Dart Frog provides a higher-level backend development workflow while itself building on the Shelf ecosystem.

### Serverpod

Powerful, but not selected because the project's chosen persistence layer is MongoDB Atlas and the current design seeks a comparatively lightweight REST API rather than adopting a larger integrated server ecosystem.

## Consequences

Advantages:

* one principal language across client and server;
* easier knowledge transfer between Flutter/Dart and backend Dart;
* backend can still be containerized and deployed separately;
* Dart Frog includes routing, middleware, a development server, and testable handlers.

Tradeoffs:

* the Dart backend ecosystem is smaller than Node ecosystems;
* some infrastructure will require explicit design;
* MongoDB support will be added through an appropriate Dart driver later.

## Deferred Decisions

* MongoDB driver and database lifecycle implementation
* authentication
* password hashing
* token/session strategy
* API error model
* logging strategy
* observability
* rate limiting
* production hosting
* CI/CD
* WebSocket strategy
