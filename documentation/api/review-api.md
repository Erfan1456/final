# Review API

TASK 017 verified completed-booking customer reviews, cleaner list, admin hide/unhide, and discovery aggregates.

See [chat-notifications-and-reviews.md](../architecture/chat-notifications-and-reviews.md) and [ADR-015](../decisions/ADR-015-chat-notifications-and-verified-reviews.md).

## Customer (JWT, customer role)

### `GET /api/v1/customer/bookings/{bookingId}/review`

Owned completed-booking review, or `{ "review": null }`. Foreign booking: `404`. Non-completed owned booking: `409 review_not_allowed`. Customer JSON includes `moderation_status` and computed `verified_booking: true`.

### `PUT /api/v1/customer/bookings/{bookingId}/review`

Body: `{ "rating": 5, "comment": "..." }`. First create: `201`. Update: `200`. Hidden reviews stay hidden after customer edit. First create notifies the cleaner (`review_received`). Subsequent edits do not.

Rating must be integer 1–5. Payment status is not required.

## Cleaner (JWT, approved cleaner role)

### `GET /api/v1/cleaner/reviews`

Query: `status` (`published` / `hidden`, default all), `limit` (default 20, 1–50), `after`. Sort `_id` descending. Reviewer is always `Verified customer`. No customer email/phone/address. Hidden reviews may show `moderation_status` without admin identity unless needed.

## Admin (JWT, admin role)

### `GET /api/v1/admin/reviews`

Query: `status`, `rating` (1–5), `cleaner_user_id`, `limit` (default 20, 1–50), `after`. Sort `_id` descending.

### `GET /api/v1/admin/reviews/{reviewId}`

Admin DTO including ids needed to moderate. No customer security/private contact fields beyond ids.

### `POST /api/v1/admin/reviews/{reviewId}/hide`

Body: `{ "reason": "..." }` (required, 5–500 Unicode code points). `published` → `hidden`. Already hidden: idempotent 200 without overwriting the original reason.

### `POST /api/v1/admin/reviews/{reviewId}/unhide`

`hidden` → `published`; clears `hidden_reason`, `hidden_by`, `hidden_at`. Already published: idempotent 200. No notification on hide/unhide.

## Discovery

List/detail include `rating_average` (double or null) and `review_count` (0 when none). Detail also includes latest 10 published public reviews: `rating`, `comment`, `created_at`, `verified_booking: true`, `reviewer_display_name: "Verified customer"`. Hidden reviews are excluded. Aggregates are computed from `reviews`, not stored on `cleaner_profiles`.

## Error codes

| code | typical HTTP |
| --- | --- |
| `booking_not_found` | 404 |
| `review_not_found` | 404 |
| `review_not_allowed` | 409 |
| `invalid_review_rating` | 400 |
| `invalid_review_comment` | 400 |
| `invalid_review_reason` | 400 |
| `invalid_review_state` | 409 |

No raw Mongo errors.
