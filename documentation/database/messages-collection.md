# Messages Collection

This document describes the `messages` collection.

TASK 017 stores immutable plaintext booking-chat messages. There is no edit, delete, attachment, typing indicator, or presence.

## Purpose

One document is one message in one conversation. Sender identity is derived from the authenticated persisted user, never from the request body.

## Document shape

```text
_id                       ObjectId
conversation_id           ObjectId
sender_user_id            ObjectId
sender_role               String     (customer | cleaner)
body                      String
client_idempotency_key    String
created_at                DateTime   (UTC)
```

## Validation

`body` is required. Leading/trailing whitespace is trimmed. After trim: 1–2000 Unicode code points. Newlines and tabs are allowed. Other control characters are rejected. Plain text only. HTML/Markdown is not parsed or stored.

## Idempotency

`POST` requires `Idempotency-Key` (16–128 ASCII, trimmed, not lowercased, no control characters). Uniqueness is `(conversation_id, sender_user_id, client_idempotency_key)`.

Same key from the same sender/conversation:

- same normalized body → existing message (idempotent replay);
- different body → `409 idempotency_key_reused`.

Correctness uses the unique Mongo index. Duplicate-key races load the existing row, compare body, and return replay or conflict.

## Lifecycle

Messages may be sent when the booking is `pending`, `confirmed`, or `in_progress`. `completed`, `declined`, and `cancelled` conversations are read-only (`409 conversation_read_only`). History is not deleted when a booking becomes terminal.

## Public JSON

Safe DTO: `id`, `conversation_id`, `sender_user_id`, `sender_role`, `body`, `created_at`, `is_mine`. `client_idempotency_key` is never returned.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `messages_conversation_id_desc` | `conversation_id`, `_id` desc | no |
| `messages_sender_idempotency_unique` | `conversation_id`, `sender_user_id`, `client_idempotency_key` | yes |

History uses `_id` keyset pagination (`before` / `after`). Offset/skip is not used.

## Security

Do not store recipient email, phone, customer address, password, or token information.
