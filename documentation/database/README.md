# Database

This directory will document the MongoDB design used by the Home Cleaning Service Marketplace.

Planned coverage includes:

* MongoDB database design
* collections
* document structures
* relationships/references
* indexes
* validation
* timestamps
* data lifecycle
* database security
* development vs production considerations

The first implemented collections are `users` and `user_sessions`. TASK 013 added `customer_profiles`, `cleaner_profiles`, and `addresses`. TASK 014 added `services`, `cleaner_services`, and `availability_slots`. TASK 015 added `bookings`. TASK 016 added `payments`, `payment_webhook_events`, and `payment_refund_requests`. TASK 017 added `conversations`, `conversation_members`, `messages`, `notifications`, and `reviews`. TASK 018 added `disputes` and `audit_logs`. TASK 019 added `earnings_ledger`, `payout_requests`, and `payout_provider_events`. TASK 020 added `account_action_tokens`.

## Current documents

* [mongodb-atlas-integration.md](mongodb-atlas-integration.md) — backend connectivity foundation, driver, secrets, lifecycle, and health versus readiness.
* [users-collection.md](users-collection.md) — user account identity collection, email uniqueness index, and repository operations.
* [user-sessions-collection.md](user-sessions-collection.md) — refresh-session documents, hash-only storage, rotation, replay detection, and indexes.
* [customer-profiles-collection.md](customer-profiles-collection.md) — one customer profile per user and default-address pointer.
* [cleaner-profiles-collection.md](cleaner-profiles-collection.md) — cleaner onboarding lifecycle and review metadata.
* [addresses-collection.md](addresses-collection.md) — owned service addresses, 20-address product limit, computed `is_default`.
* [services-collection.md](services-collection.md) — platform catalog and canonical Home Cleaning service.
* [cleaner-services-collection.md](cleaner-services-collection.md) — cleaner offerings, integer minor-unit pricing, logical deactivation.
* [availability-slots-collection.md](availability-slots-collection.md) — UTC open future windows, overlap rules, 180-slot limit.
* [bookings-collection.md](bookings-collection.md) — complete-slot reservation, snapshots, partial unique active-slot index, embedded history.
* [payments-collection.md](payments-collection.md) — payment ledger, attempts, quote amount authority, active/settlement uniqueness.
* [payment-webhook-events-collection.md](payment-webhook-events-collection.md) — signed webhook receipts and event idempotency.
* [payment-refund-requests-collection.md](payment-refund-requests-collection.md) — admin refund command idempotency.
* [conversations-collection.md](conversations-collection.md) — one conversation per booking.
* [conversation-members-collection.md](conversation-members-collection.md) — customer/cleaner read-cursor members.
* [messages-collection.md](messages-collection.md) — immutable plaintext messages and send idempotency.
* [notifications-collection.md](notifications-collection.md) — in-app notifications and user+dedupe uniqueness.
* [reviews-collection.md](reviews-collection.md) — one verified review per completed booking and moderation.
* [disputes-collection.md](disputes-collection.md) — one booking-scoped dispute, embedded history, and admin lifecycle.
* [audit-logs-collection.md](audit-logs-collection.md) — append-only admin audit trail with best-effort writes.
* [earnings-ledger-collection.md](earnings-ledger-collection.md) — append-only cleaner earnings and refund adjustments.
* [payout-requests-collection.md](payout-requests-collection.md) — cleaner payout requests, reservation, and sandbox settlement state.
* [payout-provider-events-collection.md](payout-provider-events-collection.md) — signed payout webhook receipts and event idempotency.
* [account-action-tokens-collection.md](account-action-tokens-collection.md) — hashed one-time verification and password-reset tokens, atomic claim, replacement, and TTL cleanup.
* [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md) — accepted driver and connection-lifecycle decision.
* [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md) — accepted user account persistence model.
* [../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md](../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md) — accepted profile/address/onboarding collections and authorization.
* [../decisions/ADR-012-service-offerings-availability-and-discovery.md](../decisions/ADR-012-service-offerings-availability-and-discovery.md) — accepted catalog, offerings, availability, and discovery.
* [../decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md](../decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md) — accepted complete-slot booking, snapshots, partial unique reservation, and idempotency.
* [../decisions/ADR-014-payment-provider-webhooks-and-refunds.md](../decisions/ADR-014-payment-provider-webhooks-and-refunds.md) — accepted provider-neutral sandbox payment ledger, signed webhooks, and refund foundation.
* [../decisions/ADR-015-chat-notifications-and-verified-reviews.md](../decisions/ADR-015-chat-notifications-and-verified-reviews.md) — accepted booking-scoped chat, in-app notifications, and verified reviews.
* [../decisions/ADR-016-disputes-admin-operations-and-audit.md](../decisions/ADR-016-disputes-admin-operations-and-audit.md) — accepted disputes, admin operations, and append-only audit.
* [../decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md](../decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md) — accepted earnings ledger, payout requests, sandbox payouts, and read-only reconciliation.
