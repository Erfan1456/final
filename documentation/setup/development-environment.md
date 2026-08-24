# Development Environment Snapshot

This is a dated snapshot of the previously audited local development environment. It is not a permanent version requirement. Toolchain versions may change later and should be re-checked when environment documents are updated.

Snapshot date: 2026-08-24

## Audited values

```text
Flutter: 3.47.1 stable
Dart: 3.13.1
Android SDK: 36.1.0
Android AVD available: Pixel_9
Host OS: Windows
```

Additional audit notes:

* Android toolchain was healthy during the repository audit.
* All Android licenses were accepted.
* The Pixel_9 AVD existed but was not running at audit time.
* Chrome configuration had a warning.
* Visual Studio C++ workload was missing.
* The Chrome and Visual Studio warnings do not block Android development.

## Flutter command location

Flutter commands must be run from `project/`.

That directory is the Flutter package root. The Git repository root is one level above it.

## Useful verification commands

```bash
flutter --version
dart --version
flutter doctor -v
flutter devices
flutter emulators
```

These commands inspect the local toolchain. They do not start implementation work.

## MongoDB Atlas

MongoDB Atlas development infrastructure has been configured externally by the user.

No credentials or connection URI belong in this document. Backend connectivity uses `MONGODB_URI` from the server environment or an ignored local `backend/.env`. See [../database/mongodb-atlas-integration.md](../database/mongodb-atlas-integration.md).
