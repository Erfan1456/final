# Conversations Collection

This document describes the `conversations` collection.

TASK 017 stores one booking-scoped customer ↔ cleaner conversation. The booking remains the source of truth for participants and lifecycle. Chat does not copy email, phone, address, payment credentials, tokens, or a full booking snapshot onto the conversation.

There is no WebSocket, presence, or admin dispute-chat access in TASK 017.

## Purpose

One conversation per booking. `booking_id` is unique. Repeated initialization returns the existing conversation rather than creating a second row.

## Document shape

```text
_id                 ObjectId
booking_id          ObjectId   (unique)
customer_user_id    ObjectId   (from the booking)
cleaner_user_id     ObjectId   (from the booking)
created_at          DateTime   (UTC)
updated_at          DateTime   (UTC)
last_message_at     DateTime?  (UTC; set on create and on each successful send)
```

## Forbidden fields

Do not store email, phone, address, password, JWT, refresh token, payment credentials, or booking snapshots.

## Creation consistency

Conversation creation also upserts `conversation_members` for the booking customer and cleaner. The backend does not use Mongo multi-document transactions. Creation is repairable:

1. create or find by unique `booking_id`;
2. upsert the customer member;
3. upsert the cleaner member;
4. repeated initialization repairs missing members.

This is not transactionally atomic across collections.

## List policy

`GET /api/v1/conversations` is unpaginated and capped at 50, sorted by `last_message_at` descending then `_id` descending. Keyset pagination for the conversation list is deferred.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `conversations_booking_unique` | `booking_id` | yes |
| `conversations_customer_last_message` | `customer_user_id`, `last_message_at` desc, `_id` desc | no |
| `conversations_cleaner_last_message` | `cleaner_user_id`, `last_message_at` desc, `_id` desc | no |

Role-specific last-message indexes support `listForUser` for customer or cleaner without a collection scan.

## Security

Public JSON never includes email, phone, address, or tokens. Foreign or non-member access is `404 conversation_not_found`. Admin is not a chat participant.
