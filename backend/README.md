# Home Cleaning Service Marketplace — Backend API

Dart package name: `home_cleaning_marketplace_api`

This directory is the Dart Frog backend API for the Home Cleaning Service Marketplace. It is a sibling of the Flutter client in `../project/`.

Current API version: `/api/v1`

MongoDB Atlas is the persistence provider. `mongo_dart` is the backend driver. A users persistence foundation now exists (account model, repository, unique normalized-email index). Argon2id password hashing primitives exist. Access-token and refresh-session primitives exist (`user_sessions` indexes included). There are still no signup/login/refresh/logout APIs. No real users or session documents were created by TASK 008, TASK 009, or TASK 010.

Do not place a real MongoDB URI, passwords, or other secrets in this package. Flutter never receives the MongoDB connection URI.

## Current endpoints

* `GET /` — service descriptor
* `GET /api/v1/health` — liveness; database-independent
* `GET /api/v1/ready` — readiness; MongoDB ping

No authentication, booking, or other product endpoints exist yet.

## Configuration

Public, non-secret process environment variables currently supported:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated browser origins for CORS

`ALLOWED_ORIGINS` is not a secret. In development, if it is absent, localhost and 127.0.0.1 origins are permitted. Production must set an explicit allow-list and never rely on `Access-Control-Allow-Origin: *`.

Secret / deployment environment variables:

* `MONGODB_URI` — required for database readiness (`GET /api/v1/ready`)
* `ACCESS_TOKEN_SECRET` — HS256 access-token signing secret; not required to start the server until authentication routes exist

There is no default MongoDB URI and no default access-token secret. The process can still start and serve liveness health when `MONGODB_URI` or `ACCESS_TOKEN_SECRET` is missing.

## Local development

Local development may load `backend/.env`. Production and other deployed environments should use real process environment variables instead of a committed file.

`.env` must never be committed. Copy the placeholders from `.env.example`:

```text
APP_ENV=development
ALLOWED_ORIGINS=
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@CLUSTER_HOST/home_cleaning_marketplace
ACCESS_TOKEN_SECRET=<replace-with-a-strong-random-secret>
```

Replace the placeholders with values from your private Atlas configuration. Do not commit the real file.

From this directory:

```bash
dart pub get
dart_frog dev
dart analyze
dart test
```

The development server defaults to port 8080.

When the Flutter Android emulator later calls this API, use `http://10.0.2.2:8080` instead of `http://localhost:8080`, because emulator `localhost` refers to the emulator itself. Do not hardcode `10.0.2.2` into production Flutter code.

## Architecture directories

* `routes/` — Dart Frog HTTP entrypoints
* `lib/src/config/` — environment loading and server configuration
* `lib/src/database/` — MongoDB connection lifecycle and collection names
* `lib/src/features/users/` — user account persistence model and repository
* `lib/src/features/auth/security/` — password policy and Argon2id hashing
* `lib/src/features/auth/tokens/` — access JWT and refresh-token primitives
* `lib/src/features/auth/sessions/` — user session persistence and rotation
* `lib/src/http/` — JSON and CORS helpers
* `tool/` — controlled database index setup
* `test/` — backend tests

Business logic should not accumulate in route handlers. Future features should add services and repositories under `lib/src/` when they are needed.

## Current limitations

* Users persistence foundation (no signup/login APIs)
* Unique `users.email_normalized` index
* Argon2id password hashing primitives (no auth routes)
* Access JWT and refresh-session primitives (no auth routes)
* Approved `user_sessions` indexes
* No authentication HTTP endpoints
* No product resources
* CORS is a small development-oriented foundation, not a complete production security policy
