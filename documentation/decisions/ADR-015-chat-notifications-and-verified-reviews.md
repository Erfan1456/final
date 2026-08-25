# ADR-015 — Booking-Scoped Chat, In-App Notifications, and Verified Reviews

## Status
Accepted

## Context

TASK 016 established a sandbox payment ledger and booking lifecycle, but the marketplace still had no post-booking communication, in-app notification feed, or verified reviews. TASK 017 needs those trust and communication surfaces without introducing WebSockets, push providers, or a transactional outbox.

## Decision

- One conversation per booking (`conversations.booking_id` unique).
- Customer and cleaner members only; admin is not a booking-chat participant.
- Idempotent, repairable conversation initialization (find/create conversation, upsert both members). Not a Mongo multi-document transaction.
- Immutable plaintext messages; sender from authenticated persisted user.
- Message `Idempotency-Key` uniqueness on `(conversation_id, sender_user_id, client_idempotency_key)`.
- Booking lifecycle controls writing: `pending`/`confirmed`/`in_progress` writable; `completed`/`declined`/`cancelled` read-only.
- REST polling (~5 seconds, mounted chat screen only) instead of WebSockets.
- Member read cursor (`last_read_message_id`); no per-message receipts to the sender.
- Persistent in-app notifications only.
- Deterministic notification dedupe on `(user_id, dedupe_key)`.
- Best-effort cross-document notification creation after successful primary mutation; failure does not roll back the primary operation.
- One verified review per completed booking; payment status is not required.
- Review moderation `published` / `hidden`; customer edit of a hidden review stays hidden.
- Hidden reviews excluded from discovery.
- Computed rating aggregates (`aggregateForCleanerIds`); no stored `rating_average`/`review_count` on cleaner profiles.
- Neutral public reviewer identity: `Verified customer`.
- Admin-only hide/unhide.

## Alternatives Considered

### Global direct messages independent of booking
Rejected because chat should be tied to marketplace relationship and privacy.

### WebSockets immediately
Deferred because REST polling can exercise conversation semantics without new realtime infrastructure/dependencies.

### Editable/deletable messages
Deferred to preserve simpler audit/history semantics.

### Push notifications now
Deferred because external push provider/device-token management is not yet configured.

### Transactional notification outbox now
Deferred; current notifications are idempotent best-effort side effects and the limitation is explicit.

### Stored cleaner rating_average/review_count
Not selected because cross-document aggregate updates could become stale without transaction/outbox infrastructure.

### Allow reviews before completion
Rejected because review must represent a verified completed service.

### Expose customer identity publicly with review
Rejected for privacy.

## Consequences

Customers and cleaners can message about a booking, see in-app event notices, and publish a verified review that affects discovery. Admins can hide harmful public content without granting chat inspection. Exactly-once notification delivery, realtime sockets, and push are explicitly out of scope.

## Security

Booking-participant authorization, persisted-user authority, foreign conversation 404, admin excluded from private chat, message sender not body-overridable, notification ownership, no client-chosen `user_id`, safe notification contents, explicit Flutter resource mapping, completed-booking review ownership, hidden reviews absent from discovery, admin-only moderation, neutral public reviewer identity, no customer contact/address/payment in public review JSON.

## Deferred Decisions

WebSockets/SSE, push notifications, email/SMS, attachments, message moderation, typing/presence, admin dispute-chat access, review replies, review reporting, appeals, transactional outbox, stored rating aggregates, review analytics.
