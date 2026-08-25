# Services, Availability, and Discovery API

TASK 014 adds a public service catalog, approved-cleaner service offerings, future availability slots, and customer-only discovery. TASK 015 books those slots. TASK 016 adds sandbox payments. TASK 017 adds published-review aggregates on discovery. Maps, geocoding, and admin catalog editors are not implemented. Discovery list/detail exclude slots with an active booking reservation via a batched lookup. See [booking-api.md](booking-api.md) and [review-api.md](review-api.md).

All timestamps in requests must be ISO-8601 strings with an explicit timezone/offset. The backend normalizes to UTC. Timezone-less values are rejected.

Feature routes (except the public catalog) require Bearer access JWT verification, persisted user resolution, `account_status == active`, and the **current persisted** `users.role`. JWT `role` is authentication evidence only.

## Public catalog — `GET /api/v1/services`

Public. No JWT. Returns **active** services only.

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "507f1f77bcf86cd799439051",
        "slug": "home-cleaning",
        "name": "Home Cleaning",
        "description": "Hourly professional cleaning for occupied homes, including living spaces, kitchens, bathrooms, and bedrooms.",
        "billing_model": "hourly"
      }
    ]
  }
}
```

Wrong method: HTTP 405. Inactive services, Mongo metadata, and timestamps are omitted.

## Cleaner services

Approved cleaner only. Unapproved cleaners receive HTTP 403 `cleaner_not_approved`.

### `GET /api/v1/cleaner/services`

Returns the authenticated cleaner's offerings joined with safe catalog fields.

### `PUT /api/v1/cleaner/services/{serviceId}`

Upsert body (fake data):

```json
{
  "hourly_rate_minor": 250000,
  "currency_code": "BDT",
  "is_active": true
}
```

`hourly_rate_minor` must be an integer 1–100000000. `currency_code` is three ASCII letters, stored uppercase. Body cannot set `cleaner_user_id`, a different `service_id`, or timestamps. Inactive/missing platform service: 404 `service_not_found`.

### `DELETE /api/v1/cleaner/services/{serviceId}`

Logical deactivation (`is_active = false`). Returns the current offering.

## Cleaner availability

Approved cleaner only. Requires an **active** offering for the slot's service.

### `GET /api/v1/cleaner/availability`

Query: optional `from`, `to`, `service_id`. Defaults: `from = now`, `to = now + 90 days`. Maximum range 180 days. Sort `start_at` ascending. Only the authenticated cleaner's slots.

### `POST /api/v1/cleaner/availability`

Fake example (not a runtime assumption):

```json
{
  "service_id": "507f1f77bcf86cd799439051",
  "start_at": "2026-09-01T09:00:00+06:00",
  "end_at": "2026-09-01T11:00:00+06:00"
}
```

Duration 60 minutes–8 hours in 30-minute increments. Overlap: 409 `availability_overlap`. More than 180 future slots: 409 `availability_limit_reached`. Adjacent boundaries are allowed.

### `GET` / `PUT` / `DELETE /api/v1/cleaner/availability/{slotId}`

Owned future slots only. Foreign, unknown, and already-started slots: 404 `availability_not_found`. PUT may change `service_id`, `start_at`, and `end_at` under the same rules. DELETE physically removes the open future slot. If an active booking references the slot: 409 `availability_reserved`. GET remains allowed.

## Customer discovery

Customer role only. Cleaner and admin receive 403 `forbidden`.

Eligibility: active cleaner account, approved onboarding, active platform service, active offering. Optional availability window requires at least one overlapping future slot for that service.

### `GET /api/v1/discovery/cleaners`

Query:

* `service` — slug; default `home-cleaning`
* `currency` — optional three-letter code, normalized uppercase
* `max_rate_minor` — optional positive integer; compared within one currency
* `min_experience` — optional integer 0–50
* `available_from` / `available_to` — optional pair, explicit timezone, `from < to`, max 31 days
* `limit` — default 20, min 1, max 50
* `after` — `cleaner_services._id` cursor

Keyset pagination, `_id` ascending. Not a ranking algorithm.

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "cleaner_user_id": "507f1f77bcf86cd799439081",
        "full_name": "Ada Cleaner",
        "bio_excerpt": "Reliable cleaner for apartments.",
        "years_experience": 4,
        "service_area": "Dhaka North",
        "service": {
          "id": "507f1f77bcf86cd799439051",
          "slug": "home-cleaning",
          "name": "Home Cleaning"
        },
        "hourly_rate_minor": 250000,
        "currency_code": "BDT",
        "next_available_at": "2026-09-01T03:00:00.000Z"
      }
    ],
    "next_cursor": null
  }
}
```

### `GET /api/v1/discovery/cleaners/{cleanerUserId}`

Query `service` defaults to `home-cleaning`. Returns safe profile, offering, and up to 60 future slots for that service in the next 30 days. Ineligible/unknown cleaners: the same 404 `cleaner_not_found`.

## Privacy

Customer discovery never includes:

* email
* phone_e164
* reviewed_by / rejection_reason / review timestamps
* account_status internals
* password, token, or session fields

## Query strategy

Discovery pages `cleaner_services` then batch-fetches users, profiles, availability, and **active booking reservations** (`findActiveByAvailabilitySlotIds`). It does not loop one cleaner → one profile → one user → one slot → one booking. Page size is at most 50. Reserved slots (pending/confirmed/in_progress) are excluded from `next_available_at`, availability-range filters, and cleaner-detail future slots.

## Errors

| Situation | HTTP | code |
| --- | --- | --- |
| validation | 400 | `invalid_input`, `invalid_hourly_rate`, `invalid_currency_code`, `invalid_availability_window` |
| unapproved cleaner mutating services/availability | 403 | `cleaner_not_approved` |
| missing platform service | 404 | `service_not_found` |
| missing offering | 404 | `cleaner_service_not_found` |
| missing/foreign/started slot | 404 | `availability_not_found` |
| ineligible discovery target | 404 | `cleaner_not_found` |
| overlap | 409 | `availability_overlap` |
| reserved slot update/delete | 409 | `availability_reserved` |
| 180 future slots | 409 | `availability_limit_reached` |
| wrong persisted role | 403 | `forbidden` |

Raw Mongo errors are never returned.
