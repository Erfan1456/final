# Conversation Members Collection

This document describes the `conversation_members` collection.

TASK 017 stores participant read-cursor rows for booking chat. Allowed member roles are `customer` and `cleaner` only. Admin cannot be a booking-chat participant.

## Purpose

Exactly two intended members per conversation: the booking customer and the booking cleaner. Members are upserted during conversation initialization so a missing row can be repaired.

## Document shape

```text
_id                     ObjectId
conversation_id         ObjectId
user_id                 ObjectId
role                    String     (customer | cleaner)
last_read_message_id    ObjectId?
last_read_at            DateTime?
created_at              DateTime   (UTC)
updated_at              DateTime   (UTC)
```

## Read state

`POST /api/v1/conversations/{conversationId}/read` updates only the authenticated member's `last_read_message_id` and `last_read_at`. The other participant is never updated. TASK 017 does not expose per-message read receipts to the sender.

Unread count is the number of messages in the conversation where `sender_user_id` is not the current user and the message `_id` is newer than `last_read_message_id`.

## Indexes

| name | keys | unique |
| --- | --- | --- |
| `conversation_members_conversation_user_unique` | `conversation_id`, `user_id` | yes |

`conversation_members_user_conversation` (`user_id`, `conversation_id`) is omitted. Conversation lists query `conversations` by participant user id. Member reads always use `(conversation_id, user_id)`, which the unique index covers.

## Security

Member rows do not store email, phone, address, or tokens. Admin cannot join as a member.
