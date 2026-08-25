# Architecture

This directory will document the system architecture of the Home Cleaning Service Marketplace as it is designed and implemented.

Planned coverage includes:

* system architecture
* Flutter application architecture
* backend architecture
* module boundaries
* dependency direction
* state management architecture
* routing architecture
* authentication architecture
* communication between Flutter and backend
* deployment architecture
* architecture diagrams

No architecture has been chosen in TASK 001. Concrete architecture documents should be added only when those decisions and implementations exist.

## Current documents

* [repository-layout.md](repository-layout.md) — current Git repository layout and the distinction between the Git root and the Flutter package root.
* [flutter-client-architecture.md](flutter-client-architecture.md) — Flutter client feature-oriented architecture, layering, Riverpod, go_router, and Dio.
* [backend-api-architecture.md](backend-api-architecture.md) — Dart Frog backend infrastructure, `/api/v1`, health, readiness, users persistence, password hashing, token/session primitives, and authentication HTTP routes.
* [password-security.md](password-security.md) — Argon2id password hashing, policy, verification, and rehash detection.
* [auth-token-and-session-security.md](auth-token-and-session-security.md) — HS256 access JWTs, opaque refresh tokens, atomic rotation, and replay detection.
* [authentication-application-flow.md](authentication-application-flow.md)
* [protected-api-authentication.md](protected-api-authentication.md)
* [flutter-authentication.md](flutter-authentication.md) — authentication application service, signup/login/refresh/logout flow, dummy-hash login, and transparent rehash.
