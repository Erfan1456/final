# Decisions

This directory will record important engineering decisions for the Home Cleaning Service Marketplace and the reasoning behind them.

Examples of decisions that belong here include:

* framework/library selection
* state management
* routing
* backend technology
* database modeling
* authentication strategy
* project architecture
* API design conventions
* deployment decisions

Each significant decision should record:

* decision
* context
* alternatives considered
* reason
* consequences

No such decisions are made in TASK 001. Decision records should be added when those choices are actually made.

## Current documents

* [ADR-001-initial-stack-and-repository-layout.md](ADR-001-initial-stack-and-repository-layout.md) — accepted initial stack and repository-layout baseline. Remaining framework and library choices remain deferred.
* [ADR-002-flutter-package-identity.md](ADR-002-flutter-package-identity.md) — accepted Dart package name `home_cleaning_marketplace`; physical `project/` directory and native platform identifiers remain unchanged.
* [ADR-003-flutter-client-architecture.md](ADR-003-flutter-client-architecture.md) — accepted Flutter client architecture: feature-oriented layering, Riverpod, go_router, and Dio.
* [ADR-004-dart-backend-framework.md](ADR-004-dart-backend-framework.md) — accepted Dart Frog backend in `backend/` as a sibling of the Flutter client.
* [ADR-005-mongodb-driver-and-connection-lifecycle.md](ADR-005-mongodb-driver-and-connection-lifecycle.md) — accepted mongo_dart Atlas connectivity with a reusable lazy connection lifecycle.
* [ADR-006-user-account-persistence-model.md](ADR-006-user-account-persistence-model.md) — accepted `users` collection model, unique normalized-email index, and repository contract.
* [ADR-007-password-hashing-and-policy.md](ADR-007-password-hashing-and-policy.md) — accepted Argon2id hashing, encoded hash storage, and 15–128 Unicode-code-point password policy.
* [ADR-008-access-and-refresh-token-strategy.md](ADR-008-access-and-refresh-token-strategy.md) — accepted HS256 access JWTs, opaque refresh tokens, `user_sessions`, atomic rotation, and replay detection.
* [ADR-009-authentication-application-flow.md](ADR-009-authentication-application-flow.md)
* [ADR-010-flutter-authentication-and-secure-session-storage.md](ADR-010-flutter-authentication-and-secure-session-storage.md) — accepted authentication application service, thin Dart Frog routes, public customer/cleaner signup, generic login failures, dummy-hash missing-user verify, transparent rehash, refresh account-status checks, and idempotent logout.
* [ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md](ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md) — accepted separate profile collections, default-address pointer, 20-address cap, cleaner lifecycle, persisted-role authorization, and Flutter role dashboards.
* [ADR-012-service-offerings-availability-and-discovery.md](ADR-012-service-offerings-availability-and-discovery.md) — accepted platform catalog, integer minor-unit offerings, UTC availability, keyset discovery, and local comparison.
* [ADR-013-booking-reservation-idempotency-and-lifecycle.md](ADR-013-booking-reservation-idempotency-and-lifecycle.md) — accepted complete-slot booking, immutable snapshots, partial unique reservation, and idempotent creation.
* [ADR-014-payment-provider-webhooks-and-refunds.md](ADR-014-payment-provider-webhooks-and-refunds.md) — accepted provider-neutral sandbox payment ledger, signed webhooks, and refund foundation.
* [ADR-015-chat-notifications-and-verified-reviews.md](ADR-015-chat-notifications-and-verified-reviews.md) — accepted booking-scoped chat, in-app notifications, computed discovery ratings, and admin review moderation.
* [ADR-016-disputes-admin-operations-and-audit.md](ADR-016-disputes-admin-operations-and-audit.md) — accepted one dispute per booking, admin user/booking operations, payment-aware admin cancellation, and append-only best-effort audit.
* [ADR-017-cleaner-earnings-payouts-and-reconciliation.md](ADR-017-cleaner-earnings-payouts-and-reconciliation.md) — accepted append-only earnings ledger, commission snapshots, payout reservation, sandbox-only payout provider, signed payout webhooks, and read-only reconciliation.
* [ADR-018-account-recovery-verification-and-session-security.md](ADR-018-account-recovery-verification-and-session-security.md) — accepted hashed account-action tokens, signup without auth, verification enforcement, generic recovery, dev-only delivery, and session security routes.
* [ADR-019-release-candidate-ux-and-acceptance-testing.md](ADR-019-release-candidate-ux-and-acceptance-testing.md) — accepted shared Flutter UX primitives, honest minor-unit/date/status presentation, sandbox labeling, and fake-only cross-role acceptance testing without live Atlas.
* [ADR-020-production-deployment-and-release-readiness.md](ADR-020-production-deployment-and-release-readiness.md) — accepted production config validation, no sandbox fallback in production, HTTPS-only Flutter release API, stable Android application id, Docker packaging, CI without production secrets, release verification tooling, and honest production-provider / scalability claims.
