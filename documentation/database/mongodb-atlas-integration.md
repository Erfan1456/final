# MongoDB Atlas Integration

This document describes the Dart Frog backend connectivity foundation for MongoDB Atlas.

TASK 007 established connectivity, configuration, and readiness only. Application models, repositories, CRUD, indexes, migrations, and authentication are not implemented.

## Architecture

```text
Dart Frog backend
      ↓
MongoDatabase
      ↓
mongo_dart
      ↓
MongoDB Atlas
```

The Flutter client never receives a MongoDB connection URI. The database connection exists only in the backend/server environment.

```text
Flutter client
      ↓ HTTP
Dart Frog REST API
      ↓
MongoDB Atlas
```

## Driver

The backend uses:

```text
mongo_dart 0.10.9
```

Local backend environment files are loaded with:

```text
dotenv 4.2.0
```

## Secret Configuration

The Atlas connection string is supplied only as:

```text
MONGODB_URI
```

Rules:

* backend only;
* never Flutter;
* never Git;
* local `backend/.env` is ignored;
* production and other deployed environments should use process environment variables.

A safe placeholder template lives in `backend/.env.example`. That file contains no real username, password, cluster hostname, or copied query parameters.

Do not print, log, or return `MONGODB_URI`.

## Atlas Connection

Atlas URIs use the `mongodb+srv://` scheme. `mongo_dart` requires `Db.create()` for those URLs because SRV host resolution is asynchronous.

The backend does not hard-code a connection URI and does not fabricate localhost MongoDB configuration.

## Lifecycle

`MongoDatabase` is the reusable server-side connection manager.

* **Lazy connection** — opening happens on first readiness/ping use, not because `/` or `/api/v1/health` was requested.
* **Reused shared connection** — Dart Frog provides one `MongoDatabase` instance; requests do not each open a new driver connection.
* **Guarded concurrent initial connection** — simultaneous first-connect callers share one in-flight `Future`.
* **Ping readiness** — connectivity is verified with the driver's ping command (`pingCommand()`), not by opening application collections.
* **Close support** — `close()` exists for tests and controlled shutdown and is safe to call more than once.

No application collection is created, listed, or mutated as part of this integration.

## Health Model

### `GET /api/v1/health`

Liveness. Database-independent.

The process can report healthy even when MongoDB is unconfigured or unreachable.

### `GET /api/v1/ready`

Readiness. MongoDB ping.

* configured and ping succeeds → HTTP 200, `{ "success": true, "data": { "status": "ready" } }`
* unconfigured or ping fails → HTTP 503 with a generic `database_unavailable` error

Responses must not include hostnames, usernames, passwords, URIs, IP addresses, or raw driver errors.

## Current Limitations

Not implemented:

* product models
* repositories
* CRUD
* indexes
* migrations
* authentication
* users, roles, bookings, payments, or messaging
