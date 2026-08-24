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
* `GET /api/v1/health` — JSON health check

These are infrastructure routes only. Authentication and product endpoints are not implemented.
