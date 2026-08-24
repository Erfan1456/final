# ADR-005 — MongoDB Driver and Connection Lifecycle

## Status

Accepted.

## Context

The Dart Frog backend requires secure MongoDB Atlas access while keeping the database completely behind the server boundary.

Flutter must never receive a MongoDB connection URI. The backend needs a reusable connection lifecycle, local developer configuration that does not commit secrets, and a readiness check that does not mutate application data.

## Decision

* use mongo_dart 0.10.9;
* Atlas SRV URI supplied only through backend environment;
* use dotenv for local backend development only;
* deployment environments should use process environment variables;
* maintain one reusable lazy `MongoDatabase` lifecycle;
* health and readiness remain separate.

`Db.create()` is used because Atlas connection strings use `mongodb+srv://`.

## Alternatives Considered

### Flutter connecting directly to MongoDB

Rejected.

A distributable client must not contain database credentials. The trusted server remains the only MongoDB client.

### REST backend without a reusable connection

Rejected because opening a database connection for every request is wasteful and does not scale.

### Hard-coded connection URI

Rejected for security.

### Only process environment variables locally

Viable and preferred in deployment, but an ignored `.env` file is adopted for local developer convenience.

### ORM/ODM layer now

Deferred because there are no product models yet.

## Consequences

* the Flutter/server security boundary remains intact;
* local backend setup can use `backend/.env` without committing secrets;
* the backend now depends on the `mongo_dart` driver;
* connection lifecycle must be managed (lazy open, reuse, concurrent first-connect, close);
* real product repositories remain future work;
* `/api/v1/health` stays a process liveness check;
* `/api/v1/ready` is the database-backed readiness check and may return HTTP 503.

## Security

* `MONGODB_URI` lives only in the backend environment.
* `backend/.env` is Git-ignored.
* `backend/.env.example` contains placeholders only.
* The URI is not logged, not returned by HTTP, and not included in `toString` output.
* API clients receive a generic `database_unavailable` error rather than raw driver exceptions.
* Network Access and Atlas credentials are not changed by application code.

## Deferred Decisions

* collection model structure
* indexes
* schema validation
* repository implementations
* transactions
* migrations
* seed strategy
* test database strategy
* production connection tuning
