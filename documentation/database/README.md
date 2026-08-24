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

The first implemented collection is `users`. Additional schemas will be documented as they are implemented.

## Current documents

* [mongodb-atlas-integration.md](mongodb-atlas-integration.md) — backend connectivity foundation, driver, secrets, lifecycle, and health versus readiness.
* [users-collection.md](users-collection.md) — user account identity collection, email uniqueness index, and repository operations.
* [../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md](../decisions/ADR-005-mongodb-driver-and-connection-lifecycle.md) — accepted driver and connection-lifecycle decision.
* [../decisions/ADR-006-user-account-persistence-model.md](../decisions/ADR-006-user-account-persistence-model.md) — accepted user account persistence model.
