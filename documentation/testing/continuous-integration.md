# Continuous Integration

**Workflow file:** `.github/workflows/ci.yml`  
**Name:** `CI`

## Triggers

* `pull_request` (all branches)
* `push` to `main`

Concurrency group `ci-${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`.

## Jobs

### Backend (`backend/`)

1. Checkout
2. Setup Dart SDK `3.13.1` (`dart-lang/setup-dart`)
3. `dart pub get`
4. `dart format --output=none --set-exit-if-changed .`
5. `dart analyze`
6. `dart test`

Working directory: `backend`.

### Flutter (`project/`)

1. Checkout
2. Setup Flutter `3.47.1` stable (`subosito/flutter-action`, cache enabled)
3. `flutter pub get`
4. `dart format --output=none --set-exit-if-changed lib test`
5. `flutter analyze`
6. `flutter test`
7. `flutter build apk --debug`

Working directory: `project`.

## Explicit non-goals

| Item | CI behavior |
| --- | --- |
| Live MongoDB Atlas | **Not** used |
| Production secrets | **Not** configured |
| Release-signed APK/AAB | **Not** built |
| Docker image push | **Not** performed |
| Cloud deploy | **Not** performed |
| Real email/payment/payout providers | **Not** exercised |

Debug APK verifies the Android toolchain compiles; it is not a store artifact.

## Build artifact behavior

* Debug APK is produced inside the GitHub runner workspace and discarded with the job (not published by this workflow).
* No GitHub Releases upload is defined in `ci.yml`.
* Developers produce release artifacts locally or in a future dedicated signing pipeline with secrets stored in the platform secret store — not in this repository.

## Local parity

```bash
# backend/
dart format --output=none --set-exit-if-changed .
dart analyze
dart test

# project/
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Repo-root hygiene: [release-verification.md](release-verification.md).
