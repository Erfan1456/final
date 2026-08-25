# Notification API

TASK 017 persistent in-app notification feed. No push, email, SMS, or WebSockets.

See [chat-notifications-and-reviews.md](../architecture/chat-notifications-and-reviews.md) and [ADR-015](../decisions/ADR-015-chat-notifications-and-verified-reviews.md).

Shared authenticated routes for active `customer`, `cleaner`, and `admin`. Persisted current user is resolved. The HTTP body cannot choose `user_id`.

## `GET /api/v1/notifications`

Query: `unread` (optional bool), `limit` (default 20, 1–50), `after` (notification ObjectId). Sort: `_id` descending. Keyset: `_id < after`. No offset pagination.

Safe JSON only. `dedupe_key` is omitted.

## `GET /api/v1/notifications/unread-count`

Returns `{ "unread_count": N }` for the authenticated user.

## `POST /api/v1/notifications/{notificationId}/read`

Marks one owned notification read. Unknown or not-owned: `404 notification_not_found`.

## `POST /api/v1/notifications/read-all`

Marks all owned notifications read. Returns `updated_count` and remaining `unread_count`.

## Event integrations

Created after successful primary mutations, best-effort:

| event | recipient | type |
| --- | --- | --- |
| booking created | cleaner | `booking_requested` |
| cleaner accepts | customer | `booking_confirmed` |
| cleaner declines | customer | `booking_declined` |
| customer or cleaner cancels | the other participant | `booking_cancelled` |
| cleaner starts | customer | `job_started` |
| cleaner completes | customer | `job_completed` |
| payment paid / failed / refunded | customer | `payment_paid` / `payment_failed` / `payment_refunded` |
| first successful message | the other participant | `message_received` |
| first review create | cleaner | `review_received` |

Idempotent booking-create, message, webhook, and review-edit replays do not duplicate notifications. Invalid/stale payment webhooks do not notify.

Booking/payment/message notifications use `resource_type: booking` and the booking id so Flutter can open a role-appropriate booking surface. Review notifications use `resource_type: review`. Flutter maps those types explicitly and never trusts an arbitrary URL string.

## Error codes

| code | typical HTTP |
| --- | --- |
| `notification_not_found` | 404 |

No raw Mongo errors.
