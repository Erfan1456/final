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
Backend: Dart — framework not selected yet
Database: MongoDB Atlas
Primary Android development environment: Android Studio / Android Emulator
```

The Dart backend has not been created yet. Unselected packages are not listed here.

## Intended High-Level Architecture

```text
Flutter mobile client
        ↓
Dart backend API
        ↓
MongoDB Atlas
```

The Flutter client must not contain the MongoDB database URI. Database credentials belong only to backend environment configuration.

## Repository Layout

```text
final/
├── documentation/
├── project/
├── README.md
└── .gitignore
```

`project/` is the Flutter package root. Flutter commands must be run from that directory.

`documentation/` contains project technical documentation and Cursor task history.

A backend sibling directory is expected later. It has not been created yet, and its detailed structure will be decided in a later task.

## Running the Current Flutter Project

From the Git repository root:

```bash
cd project
flutter pub get
flutter devices
flutter run
```

Use a connected device or emulator available on the local machine. This README does not assume that a specific emulator is currently running.

## Documentation

Start with [documentation/README.md](documentation/README.md).

Cursor task reports live in [documentation/cursor/](documentation/cursor/).

## Security

* Never commit database credentials.
* Never commit real `.env` files.
* Never place the MongoDB URI inside Flutter client code.
* Secret and environment example files must contain placeholders only.

## Current Status

The repository is still at the foundation stage. Product functionality has not yet been implemented.
