# Setup

This directory will document environment setup and local development instructions for the Home Cleaning Service Marketplace.

Planned coverage includes:

* prerequisite software
* Flutter/Dart environment
* Android Studio/emulator setup
* MongoDB Atlas setup
* backend environment setup
* environment variables
* local development startup
* platform-specific setup
* troubleshooting

Do not record credentials, MongoDB connection strings, API keys, tokens, passwords, or other secrets in this documentation.

Backend process environment variables currently used for local development are documented in [../backend/README.md](../../backend/README.md): `APP_ENV`, `ALLOWED_ORIGINS`, `MONGODB_URI`, and `ACCESS_TOKEN_SECRET`. Local development may use an ignored `backend/.env`; production should use process environment variables. See [../database/mongodb-atlas-integration.md](../database/mongodb-atlas-integration.md). The backend can start without `ACCESS_TOKEN_SECRET`; authentication then returns HTTP 503 `authentication_unavailable`. Never record the secret value here. `ACCESS_TOKEN_SECRET` must never be placed in Flutter.

Android emulator access to a backend running on the Windows development host typically uses `http://10.0.2.2:<port>` instead of `http://localhost:<port>`. Debug Android builds may allow that local HTTP exception. Production API traffic must use HTTPS. See [development-environment.md](development-environment.md).

## Current documents

* [development-environment.md](development-environment.md) — dated local toolchain snapshot, not permanent version requirements.
