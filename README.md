# Home Cleaning Service Marketplace

This repository will contain a marketplace application connecting customers with home-cleaning service providers.

Planned principal roles:

* Customer
* Cleaner / Service Provider
* Administrator

Those roles and product features have not been implemented yet. The project is currently in the foundation and development stage.

## Technology Direction

```text
Mobile client: Flutter + Dart
Backend API: Dart + Dart Frog
Database: MongoDB Atlas — backend connectivity foundation implemented
Primary Android development environment: Android Studio / Android Emulator
```

The Dart Frog backend lives in `backend/`. MongoDB Atlas connectivity is implemented in the backend only. Flutter authentication, role-scoped profiles, addresses, cleaner onboarding, admin approval, service catalog, offerings, availability, and customer discovery now exist. Bookings, payments, chat, and reviews are not implemented.

## Intended High-Level Architecture

```text
Flutter mobile client
        ↓
Dart Frog backend API
        ↓
MongoDB Atlas
```

The Flutter client must not contain the MongoDB database URI. Database credentials belong only to backend environment configuration.

## Repository Layout

```text
final/
├── backend/
├── documentation/
├── project/
├── README.md
└── .gitignore
```

`project/` is the Flutter package root. Flutter commands must be run from that directory.

`backend/` is the Dart Frog API package root. Backend commands must be run from that directory.

`documentation/` contains project technical documentation and Cursor task history.

## Running the Current Flutter Project

From the Git repository root:

```bash
cd project
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use a connected device or emulator available on the local machine. This README does not assume that a specific emulator is currently running.

## Running the Current Backend

From the Git repository root:

```bash
cd backend
dart pub get
dart_frog dev
dart analyze
dart test
```

When an Android emulator calls this API on the Windows development host, use `http://10.0.2.2:<port>` instead of `http://localhost:<port>`. Emulator `localhost` is the emulator itself. Debug Android builds may allow that local HTTP exception; production API traffic must use HTTPS. Do not hardcode that emulator address into production Flutter code. `ACCESS_TOKEN_SECRET` is backend-only configuration and must never be placed in Flutter.

## Documentation

Start with [documentation/README.md](documentation/README.md).

Cursor task reports live in [documentation/cursor/](documentation/cursor/).

## Security

* Never commit database credentials.
* Never commit real `.env` files.
* Never place the MongoDB URI inside Flutter client code.
* Secret and environment example files must contain placeholders only.

## Current Status

The repository now has authentication, role-scoped profiles, addresses, cleaner onboarding, admin approval, a platform service catalog, cleaner offerings, availability, and customer discovery/comparison. Bookings, payments, chat, and reviews are not implemented.
