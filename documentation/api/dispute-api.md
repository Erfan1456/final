# Dispute API

Participant and admin dispute HTTP routes. All timestamps are UTC. Routes are thin; services own authorization and lifecycle.

Admin cannot create a dispute through participant routes.

WebSockets, file uploads, evidence attachments, chargebacks, and legal adjudication are not implemented.

## Participant routes

Allowed roles: `customer` and `cleaner`, **and** the persisted user must be the booking customer or cleaner.

| method | path | notes |
| --- | --- | --- |
| `POST` | `/api/v1/bookings/{bookingId}/dispute` | create; HTTP 201 |
| `GET` | `/api/v1/bookings/{bookingId}/dispute` | existing or `{ "dispute": null }` |
| `POST` | `/api/v1/bookings/{bookingId}/dispute/close` | `resolved` → `closed` only |

### Create body

```json
{
  "category": "service_quality",
  "subject": "Late arrival issue",
  "description": "The cleaner arrived more than two hours late to the job."
}
```

### Create success (201)

```json
{
  "success": true,
  "data": {
    "dispute": {
      "id": "507f1f77bcf86cd7994390d1",
      "booking_id": "507f1f77bcf86cd799439091",
      "category": "service_quality",
      "status": "open",
      "subject": "Late arrival issue",
      "description": "The cleaner arrived more than two hours late to the job.",
      "resolution": null,
      "history": [
        {
          "from_status": null,
          "to_status": "open",
          "actor_user_id": "507f1f77bcf86cd799439011",
          "actor_role": "customer",
          "note": null,
          "created_at": "2026-08-26T06:00:00.000Z"
        }
      ],
      "created_at": "2026-08-26T06:00:00.000Z",
      "updated_at": "2026-08-26T06:00:00.000Z",
      "cleaner_public_name": "Ada Cleaner"
    }
  }
}
```

Customer-facing responses use `cleaner_public_name`. Cleaner-facing responses use `customer_display_name` (profile full name or `"Customer"`).

### GET when none exists (200)

```json
{
  "success": true,
  "data": {
    "dispute": null
  }
}
```

## Eligibility and uniqueness

Eligible booking statuses: `confirmed`, `in_progress`, `completed`, `cancelled`.

`pending` / `declined`: `409 dispute_not_allowed`.

Foreign booking: `404 booking_not_found`.

Second dispute for the same booking: `409 dispute_already_exists` (unique `booking_id`).

Participant close is allowed only when status is `resolved`.

## Validation

| field | rule |
| --- | --- |
| `category` | enum only (see database doc) |
| `subject` | trim, 5–120 code points, no controls |
| `description` | trim, 20–3000 code points, newline/tab allowed |
| `resolution` | admin only; trim, 10–3000 code points |

## Admin dispute routes

Admin role only.

| method | path |
| --- | --- |
| `GET` | `/api/v1/admin/disputes` |
| `GET` | `/api/v1/admin/disputes/{disputeId}` |
| `POST` | `/api/v1/admin/disputes/{disputeId}/review` |
| `POST` | `/api/v1/admin/disputes/{disputeId}/resolve` |
| `POST` | `/api/v1/admin/disputes/{disputeId}/close` |

### List query

`status` (default `open`), `category`, `booking_id`, `customer_user_id`, `cleaner_user_id`, `limit` (default 20, 1–50), `after` (ObjectId cursor). Sort `_id` descending. No offset.

### Resolve body

```json
{
  "resolution": "Both parties were contacted. Operational note recorded."
}
```

Review of an already `under_review` dispute is idempotent 200. Resolved/closed review attempts are `409 invalid_dispute_state`.

Admin detail includes `{ "dispute", "booking" }` with a safe booking summary (id, status, service name, schedule, quoted total, currency). No password/token/provider secrets.

## Error codes

| code | typical status |
| --- | --- |
| `dispute_not_found` | 404 |
| `dispute_already_exists` | 409 |
| `dispute_not_allowed` | 409 |
| `invalid_dispute_state` | 409 |
| `invalid_dispute_subject` | 400 |
| `invalid_dispute_description` | 400 |
| `invalid_dispute_resolution` | 400 |
| `booking_not_found` | 404 |
| `forbidden` | 403 |

Raw Mongo errors are not exposed.
