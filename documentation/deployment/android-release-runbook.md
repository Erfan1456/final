# Android Release Runbook

**Flutter package:** `home_cleaning_marketplace`  
**Version name/code:** `1.0.0+1` (from `project/pubspec.yaml`; overridable via `--build-name` / `--build-number`)  
**applicationId / namespace:** `com.homecleaningmarketplace.app`  
**Flutter SDK (documented):** `3.47.1`

## API base URL

Release builds **require** a non-empty HTTPS URL:

```bash
cd project
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

`AppConfig` rejects empty or `http://` values in release mode.  
`--dart-define` is **not** a secret store — anything defined is extractable from the app binary. Never put `MONGODB_URI`, `ACCESS_TOKEN_SECRET`, or webhook secrets in Flutter defines.

## HTTPS and cleartext

* Main manifest sets `android:usesCleartextTraffic="false"` and declares `INTERNET`.
* Debug manifests may allow cleartext to emulator localhost / `10.0.2.2` only.
* Do not re-enable cleartext for release to point at a plain HTTP API.

## Release signing

Signing material stays **outside** git:

1. Create a keystore offline (Android Studio or `keytool`) — do not commit `.jks` / `.keystore`.
2. Create `project/android/key.properties` locally (gitignored pattern via release hygiene checks), for example:

```properties
storePassword=REPLACE_ME
keyPassword=REPLACE_ME
keyAlias=REPLACE_ME
storeFile=D:\\path\\to\\upload-keystore.jks
```

3. `build.gradle.kts` uses the release signing config when `key.properties` exists; otherwise it falls back to **debug signing** so local `flutter build apk --release` still works.

**Debug-signed release APKs are not Play Store distribution ready.**

## Build commands

From `project/`:

```bash
flutter pub get
flutter analyze
flutter test

# APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com

# App Bundle (Play Upload)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

Artifacts appear under `project/build/app/outputs/` (do not commit APK/AAB).

## Versioning

* `version:` in `pubspec.yaml` → `versionName` + `versionCode` (`1.0.0+1`)
* Bump before store uploads; keep backend compatibility documented when APIs change

## Play Console (high level)

1. Create application with package `com.homecleaningmarketplace.app`
2. Complete store listing, content rating, privacy policy URL (legal P0)
3. Upload AAB signed with the upload key
4. Use internal testing track before production
5. Ensure the production API is HTTPS and production-configured

This repository does **not** create Play credentials or service accounts.

## Secret boundaries

| Allowed in app | Forbidden in app |
| --- | --- |
| Public HTTPS API base URL | MongoDB URI |
| Public marketing copy | Access token secret |
| Feature flags that are non-secret | Webhook secrets, keystore passwords |

## Related

* [environment-reference.md](environment-reference.md)
* [../testing/release-verification.md](../testing/release-verification.md)
* [deployment-architecture.md](deployment-architecture.md)
