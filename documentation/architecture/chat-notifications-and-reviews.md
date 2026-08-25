# Chat, Notifications, and Reviews

TASK 017 adds booking-scoped chat, a persistent in-app notification feed, verified completed-booking reviews, discovery rating aggregation, and admin review moderation.

There are no WebSockets, push notifications, email/SMS, attachments, message edit/delete, typing/presence, review replies, disputes, or payouts.

## Booking chat

```text
Authenticated participant
  → booking membership
  → conversation (one per booking; repairable members)
  → message Idempotency-Key
  → immutable message persist
  → best-effort idempotent notification
  → Flutter REST polling (~5s while the chat screen is mounted)
```

`BookingConversationService` is HTTP-independent. Routes are thin. JWT role alone is not sufficient; the persisted user id must match `customer_user_id` or `cleaner_user_id`. Admin cannot inspect private booking chat. Foreign conversations are `404`.

Messages are writable for `pending` / `confirmed` / `in_progress` and read-only for `completed` / `declined` / `cancelled`. History is retained.

Conversation initialization is not a Mongo multi-document transaction. Unique `booking_id` plus member upserts make it repairable.

REST polling is an intentional first realtime approximation. WebSocket/SSE is deferred.

## Notifications

```text
domain transition
  → NotificationSink.notifyBestEffort
  → NotificationService idempotent insert
  → user+dedupe unique index
  → notification feed
```

Primary booking/payment/message/review mutation remains authoritative. Notification insert is a cross-document **best-effort** side effect. Unexpected notification failure does not roll back the primary operation. There is no transactional outbox and no exactly-once claim.

Flutter maps `resource_type` explicitly (`booking`, `message`, `payment`, `review`). Arbitrary server URLs are not trusted.

## Reviews

```text
completed booking
  → customer PUT review
  → published (unless already hidden)
  → batched discovery aggregate
  → admin hide/unhide
```

One review per booking. Hidden reviews stay hidden after customer edit and are excluded from discovery. Aggregates are computed from published reviews rather than stored on `cleaner_profiles` so they cannot go stale without an outbox/transaction architecture. Public reviewer identity is always `Verified customer`.

## Flutter

Focused Riverpod controllers: `BookingChatController` (5-second mounted polling, no overlapping polls, timer disposed), `NotificationController`, `CustomerReviewController`, `CleanerReviewsController`, `AdminReviewController`. No new packages. Chat send uses `Random.secure()` Idempotency-Key retained through retry of the same logical send.
