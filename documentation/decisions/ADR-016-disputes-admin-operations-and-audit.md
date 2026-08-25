# ADR-016 — Disputes, Administrative Operations, and Audit Trail

## Status
Accepted

## Context

The marketplace already authenticates users, persists roles, books services, records sandbox payments, chats, notifies, and reviews. Support staff still lacked a structured way to handle booking problems, moderate customer/cleaner accounts, inspect bookings (including paid ones), and record what an administrator actually did.

TASK 018 needed an operational layer without introducing payouts, a real payment gateway, password recovery, MFA, WebSockets, file evidence, chargebacks, legal adjudication, or AI.

## Decision

- **One dispute per booking.** Unique `booking_id`. A `closed` dispute still occupies the document; TASK 018 does not reopen or spawn issue threads.
- **Eligible booking states** for opening: `confirmed`, `in_progress`, `completed`, `cancelled`. `pending` and `declined` are blocked because no accepted/active service relationship exists.
- **Embedded dispute history** on the dispute document. Status transition and history append are one conditional update. No separate history collection.
- **Participant-only dispute creation.** Customer or cleaner of that booking. Admin reviews; admin cannot impersonate a participant on participant routes.
- **Admin dispute lifecycle:** `open` → `under_review` → `resolved` → `closed`, with admin resolve allowed from `open` or `under_review`. `closed` is terminal.
- **Account suspension / reactivation / deactivation** for customer and cleaner only, using conditional `account_status` updates. Reasons belong in audit logs, not on `users`.
- **Session revocation** after successful suspend or deactivate, through the existing session service. Persisted status remains authoritative if revocation fails.
- **Administrator-account protection.** TASK 018 APIs must not suspend, reactivate, or deactivate admin accounts, including self-target (`403 protected_admin_account`).
- **Admin booking oversight** with keyset pagination, safe operational DTOs, payment summary, and dispute summary.
- **Payment-aware admin cancellation** of `pending`/`confirmed` only. Paid/partially refunded confirmed bookings must refund remaining amount before cancel. Refund failure leaves the booking confirmed.
- **Append-only audit log** (`append` / `listPage` / `findById` only) with an explicit action enum and small safe metadata.
- **Best-effort cross-document audit write** after a successful primary action. Audit failure does not roll back the primary write.
- **Safe audit metadata** (identifiers and status scalars). No secrets, tokens, addresses, message bodies, or provider payloads.
- **Keyset pagination** (`_id` descending, `after` cursor) for admin lists. No offset.

## Alternatives Considered

### Multiple dispute threads per booking
Deferred to reduce operational ambiguity in the initial marketplace workflow.

### Allow admin to create participant dispute
Rejected because admin should review, not impersonate marketplace participants.

### Delete suspended/deactivated user data
Rejected because bookings, payments, reviews, messages, disputes, and audit require historical integrity.

### Put moderation reason on users
Rejected because moderation actions belong in audit history. `users` remains the identity/security entity.

### Allow cancelling paid booking before refund
Rejected due financial inconsistency risk. TASK 016 payment orchestration remains authoritative.

### Mutable audit records
Rejected because the audit trail should be append-only.

### Transactional outbox immediately
Deferred; existing architecture does not yet contain worker/outbox infrastructure.

## Consequences

Support can open, review, resolve, and close one dispute per booking. Admins can list/filter users and bookings, suspend/reactivate/deactivate non-admin accounts, cancel eligible bookings without bypassing refunds, and inspect a best-effort audit trail.

Cross-document audit is not transactionally guaranteed. Notification and audit failures are best-effort and must not undo a successful primary write.

## Security

- Booking participant is derived server-side. Foreign bookings/disputes are hidden (`404`).
- Persisted admin authorization is required for operational APIs. Stale JWT role cannot authorize a non-admin persisted user.
- Admin targets and self-target are protected.
- Sessions are revoked after suspend/deactivate; `account_status != active` rejects persisted-user authorization immediately.
- Payment-aware cancel cannot skip refunds.
- Audit metadata excludes secrets. Audit API is admin-only.
- No new auth stack, password logging, or Flutter secrets. `backend/.env` remains ignored.

## Deferred Decisions

Appeals, evidence uploads, admin chat access, legal workflow, chargebacks, automated fraud detection, AI moderation, distributed outbox, SIEM export, audit retention automation, and admin role hierarchy.
