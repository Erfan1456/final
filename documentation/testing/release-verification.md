# Release Verification

Local gate for repository hygiene and optional analyze/test sweeps before a release candidate is reviewed.

**Tool:** `tools/release_check.dart` (Dart SDK only; run from anywhere inside the repo — it walks up to the git root).

## Commands

```bash
# From repository root (recommended)
dart tools/release_check.dart           # hygiene + backend analyze + backend test
dart tools/release_check.dart --quick   # hygiene only
dart tools/release_check.dart --full    # hygiene + backend analyze/test + flutter analyze/test
```

## What it checks

### Always

* Expected directories exist: `backend/`, `project/`, `documentation/`
* `backend/.env` is gitignored
* Tracked files do not include forbidden artifacts such as:
  * `backend/.env`
  * `*.apk` / `*.aab`
  * `*.jks` / `*.keystore`
  * `key.properties`
  * build trees / tmp task prompt dumps matched by the script’s rules

### Default (without `--quick`)

* `dart analyze` in `backend/`
* `dart test` in `backend/`

### `--full`

* Also `flutter analyze` and `flutter test` in `project/`

## Expected results

```text
[PASS] ...
Release check PASSED
```

Any `[FAIL]` → exit code `1` and `Release check FAILED`.

The tool **never** prints secret values, **never** connects to Atlas, and **never** mutates application data.

## Manual complements (not inside the script)

| Check | Command / action |
| --- | --- |
| Flutter debug APK | `cd project && flutter build apk --debug` |
| Flutter release APK | `flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com` |
| App bundle | `flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com` |
| Docker image | `cd backend && docker build -t home-cleaning-api:local .` |
| Production config tests | covered by backend `dart test` (configuration validation / provider unavailable) |
| CI | Push/PR → `.github/workflows/ci.yml` |

## Artifact cleanup

* Delete local APK/AAB/keystore copies from shared folders after testing
* Do not commit `project/build/` outputs
* Keep `key.properties` and keystores outside git

## Known warnings

* Gradle may emit Java restricted-method warnings during Android builds while still succeeding
* Release builds without `key.properties` use debug signing — fine for local verification, **not** Play-ready
* Format/analyze failures must be fixed; do not bypass with `--no-verify` style habits in git hooks if added later

## Related

* [continuous-integration.md](continuous-integration.md)
* [../deployment/android-release-runbook.md](../deployment/android-release-runbook.md)
* [../deployment/backend-container-runbook.md](../deployment/backend-container-runbook.md)
* [acceptance-testing.md](acceptance-testing.md)
* [manual-release-candidate-checklist.md](manual-release-candidate-checklist.md)
