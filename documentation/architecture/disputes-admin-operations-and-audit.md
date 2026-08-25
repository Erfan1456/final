# Disputes, Administrative Operations, and Audit Trail

TASK 018 adds booking-scoped disputes, admin user moderation, admin booking oversight with payment-aware cancellation, and an append-only audit log.

There are no password recovery, MFA, real payment gateway, push notifications, WebSockets, evidence file uploads, chargebacks, legal adjudication, or AI features. Cleaner earnings and sandbox payout settlement are documented in [earnings-payouts-and-reconciliation.md](earnings-payouts-and-reconciliation.md).

## Participant dispute

```text
booking participant (persisted customer or cleaner)
  → eligible booking (confirmed / in_progress / completed / cancelled)
  → one dispute document per booking
  → status open + history creation entry
  → best-effort notify the other participant (dispute_opened)
  → admin review (open → under_review) → notify both
  → admin resolve (resolution note) → notify both
  → participant or admin close (resolved → closed)
```

`BookingDisputeService` derives participant ids from the booking. Admin cannot create on participant routes. Foreign bookings are `404`. `pending`/`declined` are `409 dispute_not_allowed`.

Embedded history is intentional. Status + history append use a conditional atomic document update. There is no separate history collection.

## Account moderation

```text
persisted admin
  → AdminUserManagementService
  → conditional account_status update
  → revoke all refresh sessions (suspend / deactivate)
  → best-effort audit append
```

Targets: customer and cleaner only. Admin accounts and self-target return `403 protected_admin_account`. Reasons live in audit logs, not on `users`. Deactivation is not deletion.

If session revocation fails after status change, the account remains unavailable. Status is not reverted.

## Admin booking cancellation

```text
persisted admin
  → booking (pending or confirmed only)
  → inspect payment state
  → cancel pending/authorized payment or refund remaining paid amount
  → only then cancel booking (conditional transition)
  → notify customer + cleaner (booking_cancelled)
  → best-effort audit (booking_admin_cancelled)
```

Refund failure leaves a confirmed booking unchanged. TASK 016 financial consistency is not bypassed. History actor is the admin.

## Audit

```text
successful primary admin action
  → AuditSink.append (best-effort)
  → append-only audit_logs row
```

There is no transactional outbox. Audit insert failure does **not** roll back the primary action. TASK 018 does not claim exactly-once audit persistence.

Existing admin actions also emit audit after success: cleaner approve/reject, review hide/unhide, payment refund request. Business state machines are unchanged except this side-effect.

## Flutter

Focused Riverpod controllers: `BookingDisputeController`, `AdminDisputeController`, `AdminUserManagementController`, `AdminBookingOperationsController`, `AdminAuditLogController`. Authenticated Dio only. go_router role guards unchanged in spirit: customer/cleaner dispute paths are role-scoped; admin operational routes are admin-only.

Dispute notifications map `resource_type=dispute` + booking id to `/customer/bookings/:id/dispute` or `/cleaner/bookings/:id/dispute`. Server-provided arbitrary routes are not trusted.

## Deferred

Appeals, evidence uploads, admin chat access, legal workflow, chargebacks, automated fraud detection, AI moderation, distributed outbox, SIEM export, audit retention automation, and admin role hierarchy.
