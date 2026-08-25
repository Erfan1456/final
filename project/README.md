# Home Cleaning Service Marketplace — Flutter Client

This directory is the Flutter/Dart mobile client for the Home Cleaning Service Marketplace.

Its Dart package name is `home_cleaning_marketplace`. The physical directory name remains `project/`.

Repository-level documentation lives at [`../documentation/`](../documentation/).

Flutter commands should be executed from this directory.

Authentication is implemented as a vertical slice: secure token storage, signup/login/logout, session restoration, and go_router guards. TASK 013 adds role-aware customer, cleaner, and admin dashboards plus profile, address, onboarding, and approval screens. TASK 014 adds cleaner service/availability management and customer discovery, detail, and local comparison. TASK 015 adds customer booking creation, My Bookings, and cleaner booking requests/jobs. Payments, chat, and reviews are not implemented yet.

See [../documentation/architecture/flutter-authentication.md](../documentation/architecture/flutter-authentication.md), [../documentation/architecture/profile-address-and-cleaner-onboarding.md](../documentation/architecture/profile-address-and-cleaner-onboarding.md), [../documentation/architecture/service-availability-and-discovery.md](../documentation/architecture/service-availability-and-discovery.md), and [../documentation/architecture/booking-reservation-and-lifecycle.md](../documentation/architecture/booking-reservation-and-lifecycle.md).

## Architecture

The client uses:

* Riverpod for state management and dependency injection
* go_router for declarative navigation
* Dio for HTTP transport
* flutter_secure_storage 11.0.0 for the access/refresh token pair

Major `lib/` directories:

* `lib/app/` — application shell, routing, and theme
* `lib/core/` — shared configuration and networking infrastructure
* `lib/features/` — feature-oriented product code, including `auth`, `customer`, `addresses`, `cleaner`, `admin`, `catalog`, `cleaner_services`, `availability`, and `discovery`

`API_BASE_URL` is public runtime configuration supplied at compile time. It is not a secret. The Flutter client must never contain a MongoDB URI, `ACCESS_TOKEN_SECRET`, or other private credentials.

## Android emulator development

With Dart Frog running on the host at port 8080:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the Android emulator route to the host machine. `localhost` inside the emulator is the emulator itself. Debug builds may allow that local HTTP traffic. Production API traffic must use HTTPS.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
