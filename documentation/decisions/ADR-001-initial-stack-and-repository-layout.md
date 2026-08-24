# ADR-001 — Initial Stack and Repository Layout

## Status

Accepted.

## Context

The project requires a Flutter mobile application and secure MongoDB-backed server functionality.

The developer prefers not to introduce another programming language unless necessary.

The Git repository already contains a nested Flutter package at `project/` and a documentation area at `documentation/`. TASK 002 records the agreed baseline without selecting remaining framework and library details.

## Decision

Use:

```text
Flutter + Dart
```

for the mobile client.

Use:

```text
Dart
```

for the backend.

Use:

```text
MongoDB Atlas
```

for database hosting.

Keep:

```text
project/
```

as the Flutter package for now.

Keep documentation at repository-root:

```text
documentation/
```

Future backend code will be a sibling of `project/`, not inside the Flutter client.

The exact Dart backend framework/library is not selected in this decision.

The Flutter client must not connect directly to MongoDB Atlas. The intended communication path is Flutter → HTTPS/API → Dart backend → MongoDB Atlas. The MongoDB connection URI belongs only to backend environment configuration.

## Alternatives Considered

### Flutter directly connecting to MongoDB

Rejected because database credentials/URI must not be embedded in a distributable client application and business/security logic needs a trusted server boundary.

### Node.js / TypeScript backend

Technically viable, but not selected because the current project goal is to remain within Dart where practical.

### Moving Flutter files to Git repository root

Deferred/rejected for now because the existing nested package is valid and reorganizing it provides little benefit at this foundation stage.

## Consequences

Advantages:

* one principal programming language across mobile and backend;
* a clear client/server security boundary;
* documentation and application code remain separated at the repository root;
* the existing Flutter package can continue to be used without a disruptive move.

Tradeoffs:

* additional Dart server-side learning is required;
* the backend framework still needs evaluation;
* Flutter commands must currently be executed from `project/`;
* a backend directory name and internal structure still need a later decision.

## Deferred Decisions

The following are not decided by ADR-001:

* Dart backend framework
* state-management approach
* routing approach
* dependency injection
* API conventions
* authentication implementation
* MongoDB object/document modeling
* deployment provider
* CI/CD
