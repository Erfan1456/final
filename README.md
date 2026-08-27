# Home Cleaning Service Marketplace

Flutter + Dart Frog + MongoDB Atlas marketplace connecting customers with
home-cleaning service providers.

## Status

| Gate | Result |
|------|--------|
| Software release ready | Intended outcome of TASK 022 (see final docs) |
| Fully production service ready | **No** — email, payment, and payout providers remain development/sandbox only |

## Architecture

```text
Flutter Android app
        |
      HTTPS
        |
TLS / reverse proxy / load balancer
        |
Dart Frog API (containers)
        |
MongoDB Atlas
```

Roles: **Customer**, **Cleaner**, **Administrator**.

## Major capabilities

- Auth: signup, email verification architecture, JWT + refresh rotation, password reset/change, sessions
- Customer: profile, addresses, discovery, booking, sandbox payment UX, chat, notifications, reviews, disputes
- Cleaner: onboarding/approval, services, availability, jobs, earnings, sandbox payouts
- Admin: approvals, users, bookings, payments/refunds, reviews, disputes, payouts, finance/reconciliation, audit trail
- Release quality: shared UX, acceptance journeys, logout state isolation, CI, Docker packaging

## Honest provider limitations

Production must **not** claim real email delivery, card capture, refunds, or payout transfers. Those flows use development/test providers only.

## Technology

| Layer | Stack |
|-------|--------|
| Mobile | Flutter / Dart (`project/`, package `home_cleaning_marketplace`) |
| API | Dart Frog (`backend/`) |
| Data | MongoDB Atlas (backend only) |

## Repository layout

```text
final/
├── backend/          # Dart Frog API + Dockerfile
├── project/          # Flutter client
├── documentation/    # Architecture, security, deployment, tasks
├── tools/            # release_check.dart
├── .github/workflows # CI (no production secrets)
└── README.md
```

## Local development

Backend:

```bash
cd backend
dart pub get
# copy .env.example → .env (private; never commit)
dart_frog dev
dart analyze
dart test
```

Flutter (Android emulator → host API):

```bash
cd project
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter analyze
flutter test
```

Release builds require HTTPS:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.invalid
```

Android application id: `com.homecleaningmarketplace.app`

## Release verification

```bash
dart tools/release_check.dart
dart tools/release_check.dart --full
```

## Documentation

Start at [`documentation/README.md`](documentation/README.md).

Key final docs:

- [`documentation/final/project-completion-summary.md`](documentation/final/project-completion-summary.md)
- [`documentation/final/production-readiness-gap-register.md`](documentation/final/production-readiness-gap-register.md)
- [`documentation/security/final-security-audit.md`](documentation/security/final-security-audit.md)
- [`documentation/deployment/`](documentation/deployment/)
- [`documentation/decisions/ADR-020-production-deployment-and-release-readiness.md`](documentation/decisions/ADR-020-production-deployment-and-release-readiness.md)

## Security highlights

- Argon2id passwords; JWT access + rotating refresh sessions
- Role-persisted authorization; CORS allow-list (no `*`)
- Idempotency keys; financial ledger + reconciliation
- Secrets only in backend runtime env — never in Flutter/`dart-define`
