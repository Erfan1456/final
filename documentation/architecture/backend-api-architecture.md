# Backend API Architecture

This document describes the Dart Frog backend for the Home Cleaning Service Marketplace.

TASK 006 established backend infrastructure and a health endpoint only. Authentication, product resources, and MongoDB integration are not implemented.

## Current Architecture

```text
Flutter client
     ↓ HTTP
Dart Frog routes
     ↓
Application/backend layers
     ↓
Future MongoDB integration
```

MongoDB credentials will exist only on the backend/server environment. Flutter will never receive the MongoDB URI.

## Dart Frog Responsibilities

* HTTP server framework
* route discovery from `routes/`
* middleware
* request/response abstraction
* development server (`dart_frog dev`)
* production build support

## Folder Responsibilities

### `backend/routes/`

Framework HTTP entrypoints. Dart Frog maps files such as `routes/api/v1/health.dart` to `/api/v1/health`.

Route handlers should stay thin. Business logic should not accumulate here. Future routes should delegate to services and repositories as features appear.

### `backend/lib/src/`

Reusable application/backend implementation, including configuration and HTTP helpers. Feature-specific models, repositories, and services are added only when real functionality requires them.

## API Versioning

The initial REST namespace is:

```text
/api/v1
```

Current implemented routes:

```text
GET /
GET /api/v1/health
```

## Configuration

Current non-secret process environment variables:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated CORS origins

These are public server settings, not secrets. Database URIs and authentication secrets are not part of TASK 006 configuration.

## Security Boundary

```text
MongoDB credentials will exist only on the backend/server environment.
```

Flutter will never receive the MongoDB URI. The Flutter client will call this API over HTTPS/HTTP. Android emulator access to a Windows development server typically uses `http://10.0.2.2:<port>` instead of `http://localhost:<port>`.

## Current State

Only backend infrastructure and a health endpoint exist. No authentication or database integration exists yet.
