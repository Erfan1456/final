# API

This directory will document the backend API for the Home Cleaning Service Marketplace.

Planned coverage includes:

* API conventions
* endpoint definitions
* HTTP methods
* authentication requirements
* request payloads
* response payloads
* validation
* HTTP status codes
* error formats
* pagination/filtering
* API versioning if adopted later

No endpoints are defined in TASK 001. Endpoint documentation should be added when the API is designed and implemented.

## Current routes

The Dart Frog backend currently implements:

* `GET /` — JSON service descriptor
* `GET /api/v1/health` — liveness; database-independent process check
* `GET /api/v1/ready` — readiness; MongoDB ping
* `POST /api/v1/auth/signup` — public customer/cleaner registration
* `POST /api/v1/auth/login` — password authentication
* `POST /api/v1/auth/refresh` — refresh-token rotation
* `POST /api/v1/auth/logout` — idempotent session revocation
* `GET /api/v1/account/me` — protected current account
* `DELETE /api/v1/account/sessions` — revoke all refresh sessions

See [authentication-api.md](authentication-api.md). `/api/v1/health` remains available even when MongoDB is unconfigured or unreachable. `/api/v1/ready` returns HTTP 200 when ping succeeds and HTTP 503 when the database is unconfigured or unavailable.

Product marketplace endpoints are not implemented. The auth routes are not ready for unrestricted public internet exposure until production rate limiting exists.
