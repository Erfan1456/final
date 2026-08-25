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

The first implemented collections are `users` and `user_sessions`. TASK 013 added `customer_profiles`, `cleaner_profiles`, and `addresses`. Additional schemas will be documented as they are implemented.

## Current documents

* [mongodb-atlas-integration.md](mongodb-atlas-integration.md) — backend connectivity foundation, driver, secrets, lifecycle, and health versus readiness.
* [users-collection.md](users-collection.md) — user account identity collection, email uniqueness index, and repository operations.
* [user-sessions-collection.md](user-sessions-collection.md) — refresh-session documents, hash-only storage, rotation, replay detection, and indexes.
* [customer-profiles-collection.md](customer-profiles-collection.md) — one customer profile per user and default-address pointer.
* [cleaner-profiles-collection.md](cleaner-profiles-collection.md) — cleaner onboarding lifecycle and review metadata.
* [addresses-collection.md](addresses-collection.md) — owned service addresses, 20-address product limit, computed `is_default`.
* [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md) — accepted driver and connection-lifecycle decision.
* [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md) — accepted user account persistence model.
* [../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md](../decisions/ADR-011-role-scoped-profiles-addresses-and-cleaner-onboarding.md) — accepted profile/address/onboarding collections and authorization.
