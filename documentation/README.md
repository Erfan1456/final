# Documentation

This directory is the central technical documentation repository for the Home Cleaning Service Marketplace.

Documentation here is intended to grow alongside the product. It records Cursor development work, architecture, setup, database design, APIs, features, engineering decisions, and workflows. Nothing in this tree implies that a given architecture, backend, database, API, or product feature has already been implemented.

Documentation must evolve together with the implementation. A feature is not considered fully documented if its implementation changes but its corresponding documentation remains outdated.

## Documentation areas

### `cursor/`

Stores the historical record of Cursor development tasks.

Each Cursor task must eventually have its own numbered report describing the prompt, objective, files changed, commands executed, verification, and related outcomes.

### `architecture/`

Stores system architecture documentation, diagrams, module relationships, application layering, component responsibilities, and major structural explanations.

Current documents:

* [repository-layout.md](architecture/repository-layout.md)
* [flutter-client-architecture.md](architecture/flutter-client-architecture.md)
* [backend-api-architecture.md](architecture/backend-api-architecture.md)
* [password-security.md](architecture/password-security.md)
* [auth-token-and-session-security.md](architecture/auth-token-and-session-security.md)
* [authentication-application-flow.md](architecture/authentication-application-flow.md)
* [protected-api-authentication.md](architecture/protected-api-authentication.md)
* [flutter-authentication.md](architecture/flutter-authentication.md)
* [profile-address-and-cleaner-onboarding.md](architecture/profile-address-and-cleaner-onboarding.md)
* [service-availability-and-discovery.md](architecture/service-availability-and-discovery.md)
* [booking-reservation-and-lifecycle.md](architecture/booking-reservation-and-lifecycle.md)
* [payment-processing-and-webhooks.md](architecture/payment-processing-and-webhooks.md)
* [chat-notifications-and-reviews.md](architecture/chat-notifications-and-reviews.md)
* [disputes-admin-operations-and-audit.md](architecture/disputes-admin-operations-and-audit.md)
* [earnings-payouts-and-reconciliation.md](architecture/earnings-payouts-and-reconciliation.md)

### `setup/`

Stores environment setup and development setup instructions, such as Flutter, Dart, Android Studio, MongoDB Atlas, backend setup, environment variables, and local execution instructions.

Current documents:

* [development-environment.md](setup/development-environment.md)

### `database/`

Stores MongoDB architecture, collections, schemas/models, indexes, relationships/references, validation rules, migrations or migration-equivalent strategies, and database decisions.

Current documents:

* [mongodb-atlas-integration.md](database/mongodb-atlas-integration.md)
* [users-collection.md](database/users-collection.md)
* [user-sessions-collection.md](database/user-sessions-collection.md)
* [customer-profiles-collection.md](database/customer-profiles-collection.md)
* [cleaner-profiles-collection.md](database/cleaner-profiles-collection.md)
* [addresses-collection.md](database/addresses-collection.md)
* [services-collection.md](database/services-collection.md)
* [cleaner-services-collection.md](database/cleaner-services-collection.md)
* [availability-slots-collection.md](database/availability-slots-collection.md)
* [bookings-collection.md](database/bookings-collection.md)
* [payments-collection.md](database/payments-collection.md)
* [payment-webhook-events-collection.md](database/payment-webhook-events-collection.md)
* [payment-refund-requests-collection.md](database/payment-refund-requests-collection.md)
* [conversations-collection.md](database/conversations-collection.md)
* [conversation-members-collection.md](database/conversation-members-collection.md)
* [messages-collection.md](database/messages-collection.md)
* [notifications-collection.md](database/notifications-collection.md)
* [reviews-collection.md](database/reviews-collection.md)
* [disputes-collection.md](database/disputes-collection.md)
* [audit-logs-collection.md](database/audit-logs-collection.md)
* [earnings-ledger-collection.md](database/earnings-ledger-collection.md)
* [payout-requests-collection.md](database/payout-requests-collection.md)
* [payout-provider-events-collection.md](database/payout-provider-events-collection.md)

### `api/`

Stores backend API documentation including endpoints, requests, responses, validation, authentication requirements, errors, and API conventions.

Current documents:

* [authentication-api.md](api/authentication-api.md)
* [profile-address-onboarding-admin-api.md](api/profile-address-onboarding-admin-api.md)
* [services-availability-discovery-api.md](api/services-availability-discovery-api.md)
* [booking-api.md](api/booking-api.md)
* [payment-api.md](api/payment-api.md)
* [chat-api.md](api/chat-api.md)
* [notification-api.md](api/notification-api.md)
* [review-api.md](api/review-api.md)
* [dispute-api.md](api/dispute-api.md)
* [admin-operations-api.md](api/admin-operations-api.md)
* [earnings-and-payout-api.md](api/earnings-and-payout-api.md)

### `features/`

Stores documentation explaining how each product feature works technically and functionally.

### `decisions/`

Stores important technical decisions and the reasoning behind them.

Current documents:

* [ADR-001-initial-stack-and-repository-layout.md](decisions/ADR-001-initial-stack-and-repository-layout.md)
* [ADR-003-flutter-client-architecture.md](decisions/ADR-003-flutter-client-architecture.md)
* [ADR-004-dart-backend-framework.md](decisions/ADR-004-dart-backend-framework.md)
* [ADR-005-mongodb-driver-and-connection-lifecycle.md](decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md)
* [ADR-006-user-account-persistence-model.md](decisions/ADR-006-user-account-persistence-model.md)
* [ADR-007-password-hashing-and-policy.md](decisions/ADR-007-password-hashing-and-policy.md)
* [ADR-008-access-and-refresh-token-strategy.md](decisions/ADR-008-access-and-refresh-token-strategy.md)
* [ADR-009-authentication-application-flow.md](decisions/ADR-009-authentication-application-flow.md)
* [ADR-010-flutter-authentication-and-secure-session-storage.md](decisions/ADR-010-flutter-authentication-and-secure-session-storage.md)
* [ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md](decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md)
* [ADR-012-service-offerings-availability-and-discovery.md](decisions/ADR-012-service-offerings-availability-and-discovery.md)
* [ADR-013-booking-reservation-idempotency-and-lifecycle.md](decisions/ADR-013-booking-reservation-idempotency-and-lifecycle.md)
* [ADR-014-payment-provider-webhooks-and-refunds.md](decisions/ADR-014-payment-provider-webhooks-and-refunds.md)
* [ADR-015-chat-notifications-and-verified-reviews.md](decisions/ADR-015-chat-notifications-and-verified-reviews.md)
* [ADR-016-disputes-admin-operations-and-audit.md](decisions/ADR-016-disputes-admin-operations-and-audit.md)
* [ADR-017-cleaner-earnings-payouts-and-reconciliation.md](decisions/ADR-017-cleaner-earnings-payouts-and-reconciliation.md)

### `workflows/`

Stores development, testing, Git, release, deployment, and other engineering workflows.

Current documents:

* [cursor-development-workflow.md](workflows/cursor-development-workflow.md)
