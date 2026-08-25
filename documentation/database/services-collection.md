# Services Collection

This document describes the platform-owned `services` collection.

TASK 014 introduced a canonical marketplace catalog so approved cleaners can offer services without embedding catalog definitions on cleaner profiles. Clients cannot create or edit catalog documents through HTTP. Booking, payment, and admin catalog editors are not implemented.

## Purpose

Stores platform service/category definitions such as Home Cleaning. Additional services can be added later without changing authentication, cleaner profile, discovery, or future booking ownership models.

## Document shape

```text
_id            ObjectId
slug           string     (unique; lowercase hyphenated ASCII)
name           string
description    string     (plain text)
billing_model  string     (enum wire value; currently only hourly)
active         bool       (backend-owned catalog state)
created_at     DateTime   (UTC)
updated_at     DateTime   (UTC)
```

## Canonical Home Cleaning service

Controlled tool `dart run tool/ensure_service_catalog.dart` may create/update **only**:

* slug: `home-cleaning`
* name: `Home Cleaning`
* billing_model: `hourly`
* active: `true`

The tool is idempotent, manually runnable, and is not request middleware or server startup. It does not mutate users, profiles, sessions, cleaner offerings, or availability.

## Validation

* `slug`: lowercase ASCII, 2–60 characters, letters/numbers separated by single hyphens, no leading/trailing hyphen
* `name`: 2–100 Unicode code points after trim; reject control characters
* `description`: 10–500 Unicode code points after trim; plain text; reject HTML
* `billing_model`: domain enum `ServiceBillingModel`; only `hourly` is allowed today
* `active`: catalog visibility; inactive services are omitted from `GET /api/v1/services`

## Indexes

* `services_slug_unique` — unique `slug` ascending
* `services_active_slug` — `active` ascending, `slug` ascending

Index initialization is deliberate via `dart run tool/ensure_database_indexes.dart`.

## Live data policy

TASK 014 may ensure only the canonical `home-cleaning` configuration document and approved index metadata. Automated tests use in-memory fakes. Do not dump unrelated catalog documents.
