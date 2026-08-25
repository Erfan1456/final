# Chat API

TASK 017 booking-scoped customer ↔ cleaner chat. REST only. No WebSockets, attachments, edit/delete, typing, or presence.

See [chat-notifications-and-reviews.md](../architecture/chat-notifications-and-reviews.md) and [ADR-015](../decisions/ADR-015-chat-notifications-and-verified-reviews.md).

Shared authenticated routes. Allowed persisted roles: `customer`, `cleaner`. Admin is forbidden. JWT is verified, then the current persisted active user is resolved. Conversation access requires the user id to equal `customer_user_id` or `cleaner_user_id`. Unknown or non-member conversations return `404 conversation_not_found` (not 403).

## `POST /api/v1/conversations/booking/{bookingId}`

Create-or-return the conversation for an owned booking. First creation: `201`. Existing: `200`. Missing members are repaired.

## `GET /api/v1/conversations`

Authenticated user's conversations. Sort: `last_message_at` desc, `_id` desc. Unpaginated cap: 50.

Summary fields: `id`, `booking_id`, `other_party_display_name`, `other_party_role`, `booking_status`, `last_message_preview`, `last_message_at`, `unread_count`.

Display name: customer sees cleaner profile `full_name`; cleaner sees customer profile `full_name` or `Customer`. No email, phone, address, or account internals.

## `GET /api/v1/conversations/{conversationId}`

Conversation detail for a participant. Includes `read_only` from booking status.

## `GET /api/v1/conversations/{conversationId}/messages`

Query: `limit` (default 50, 1–100), `before`, `after`. `before` and `after` together: `400 invalid_message_cursor`. Neither cursor: latest page in chronological display order. Keyset on `_id`. No offset/skip.

Safe message JSON: `id`, `conversation_id`, `sender_user_id`, `sender_role`, `body`, `created_at`, `is_mine`. Never `client_idempotency_key`.

## `POST /api/v1/conversations/{conversationId}/messages`

Requires `Idempotency-Key`. Body: `{ "body": "..." }`. Sender is the authenticated user.

- First: `201`
- Same key + same body: `200`
- Same key + different body: `409 idempotency_key_reused`
- Terminal booking: `409 conversation_read_only`

Writable booking statuses: `pending`, `confirmed`, `in_progress`.

## `POST /api/v1/conversations/{conversationId}/read`

Optional body `{ "message_id": "..." }`. Omitted: mark through latest message. Updates only the authenticated member.

## Error codes

| code | typical HTTP |
| --- | --- |
| `conversation_not_found` | 404 |
| `conversation_read_only` | 409 |
| `invalid_message` | 400 |
| `invalid_message_cursor` | 400 |
| `idempotency_key_required` | 400 |
| `invalid_idempotency_key` | 400 |
| `idempotency_key_reused` | 409 |
| `forbidden` | 403 |

No raw Mongo errors.
