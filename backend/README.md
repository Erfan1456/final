# Home Cleaning Service Marketplace — Backend API

Dart package name: `home_cleaning_marketplace_api`

This directory is the Dart Frog backend API for the Home Cleaning Service Marketplace. It is a sibling of the Flutter client in `../project/`.

Current API version: `/api/v1`

MongoDB Atlas connectivity is planned but not implemented. Do not place a MongoDB URI, passwords, or other secrets in this package.

## Current endpoints

* `GET /` — service descriptor
* `GET /api/v1/health` — health check

No authentication, booking, or other product endpoints exist yet.

## Configuration

Public, non-secret process environment variables currently supported:

* `APP_ENV` — defaults to `development` when absent
* `ALLOWED_ORIGINS` — comma-separated browser origins for CORS

`ALLOWED_ORIGINS` is not a secret. In development, if it is absent, localhost and 127.0.0.1 origins are permitted. Production must set an explicit allow-list and never rely on `Access-Control-Allow-Origin: *`.

`MONGODB_URI` is not active configuration yet.

## Local development

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
* `lib/src/config/` — non-secret server configuration
* `lib/src/http/` — JSON and CORS helpers
* `test/` — backend tests

Business logic should not accumulate in route handlers. Future features should add services and repositories under `lib/src/` when they are needed.

## Current limitations

* No MongoDB integration
* No authentication
* No product resources
* CORS is a small development-oriented foundation, not a complete production security policy
