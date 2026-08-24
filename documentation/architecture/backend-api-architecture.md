# Backend API Architecture

This document describes the Dart Frog backend for the Home Cleaning Service Marketplace.

TASK 006 established backend infrastructure and a health endpoint. TASK 007 added MongoDB Atlas connectivity and a database-backed readiness endpoint. Authentication and product resources are not implemented.

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

See [../database/mongodb-atlas-integration.md](../database/mongodb-atlas-integration.md), [../database/users-collection.md](../database/users-collection.md), [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md), and [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md).

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

Reusable application/backend implementation, including configuration, environment loading, MongoDB lifecycle, HTTP helpers, and the users persistence feature. Feature-specific models, repositories, and services are added only when real functionality requires them.

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
```

`GET /api/v1/health` is liveness and does not depend on MongoDB. `GET /api/v1/ready` is readiness and performs a MongoDB ping.

## Configuration

Process environment variables:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated CORS origins
* `MONGODB_URI` — Atlas connection URI; required for readiness, never logged

Local development may additionally load `backend/.env`. Process environment values take precedence over file values. Production should use deployment environment variables. Absence of `.env` must not prevent startup.

These public settings are not secrets. `MONGODB_URI` is a secret and must not appear in Git, Flutter, logs, or HTTP responses.

## Security Boundary

```text
MongoDB credentials will exist only on the backend/server environment.
```

Flutter will never receive the MongoDB URI. The Flutter client will call this API over HTTPS/HTTP. Android emulator access to a Windows development server typically uses `http://10.0.2.2:<port>` instead of `http://localhost:<port>`.

## Current State

Backend infrastructure, liveness health, MongoDB connectivity, ping readiness, and a users persistence foundation exist. No authentication HTTP routes or product CRUD exist yet.
