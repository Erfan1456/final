# Home Cleaning Service Marketplace — Backend API

Dart package name: `home_cleaning_marketplace_api`

This directory is the Dart Frog backend API for the Home Cleaning Service Marketplace. It is a sibling of the Flutter client in `../project/`.

Current API version: `/api/v1`

MongoDB Atlas is the persistence provider. `mongo_dart` is the backend driver. A users persistence foundation now exists (account model, repository, unique normalized-email index). Argon2id password hashing primitives exist. There are still no signup/login APIs. No real users were created by TASK 008 or TASK 009.

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

There is no default MongoDB URI. The process can still start and serve liveness health when `MONGODB_URI` is missing or MongoDB is unreachable.

## Local development

Local development may load `backend/.env`. Production and other deployed environments should use real process environment variables instead of a committed file.

`.env` must never be committed. Copy the placeholders from `.env.example`:

```text
APP_ENV=development
ALLOWED_ORIGINS=
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@CLUSTER_HOST/home_cleaning_marketplace
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
* `lib/src/http/` — JSON and CORS helpers
* `tool/` — controlled database index setup
* `test/` — backend tests

Business logic should not accumulate in route handlers. Future features should add services and repositories under `lib/src/` when they are needed.

## Current limitations

* Users persistence foundation (no signup/login APIs)
* Unique `users.email_normalized` index
* Argon2id password hashing primitives (no auth routes)
* No authentication HTTP endpoints
* No product resources
* CORS is a small development-oriented foundation, not a complete production security policy
