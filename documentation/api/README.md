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

`/api/v1/health` remains available even when MongoDB is unconfigured or unreachable. `/api/v1/ready` returns HTTP 200 when ping succeeds and HTTP 503 when the database is unconfigured or unavailable.

These are infrastructure routes only. Authentication and product endpoints are not implemented.
