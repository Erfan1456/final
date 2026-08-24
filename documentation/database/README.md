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

The first implemented collections are `users` and `user_sessions`. Additional schemas will be documented as they are implemented.

## Current documents

* [mongodb-atlas-integration.md](mongodb-atlas-integration.md) — backend connectivity foundation, driver, secrets, lifecycle, and health versus readiness.
* [users-collection.md](users-collection.md) — user account identity collection, email uniqueness index, and repository operations.
* [user-sessions-collection.md](user-sessions-collection.md) — refresh-session documents, hash-only storage, rotation, replay detection, and indexes.
* [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md) — accepted driver and connection-lifecycle decision.
* [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md) — accepted user account persistence model.
