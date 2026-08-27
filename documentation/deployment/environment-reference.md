# Environment Reference

All values below are **placeholders**. Never commit real secrets. Never paste production URIs or signing material into documentation, tickets, or chat logs.

Backend loading: optional `backend/.env` merged with process environment (process wins) via `EnvironmentLoader`. Production containers should inject process env only.

Flutter configuration uses compile-time `--dart-define` (public).

---

## Backend variables

### `APP_ENV`

| Field | Value |
| --- | --- |
| Required | Soft default; **must** be known value |
| Secret? | No |
| Validation | One of `development`, `test`, `production`. Unknown → boot `ConfigurationException` |
| Purpose | Selects sandbox/dev-delivery allowances and production strictness |
| Example | `production` |

Notes: `allowsSandboxPayments` / `allowsSandboxPayouts` / `allowsDevelopmentAccountActions` are true only for `development` or `test`.

---

### `ALLOWED_ORIGINS`

| Field | Value |
| --- | --- |
| Required | **Yes in production** (non-empty). Optional in development |
| Secret? | No |
| Validation | Comma-separated origins; must **not** include `*`. Production empty list fails boot |
| Purpose | CORS allow-list; matched origin echoed; never wildcard |
| Example | `https://admin.example.com,https://app.example.com` |

Development with empty list permits `http://localhost:*` / `http://127.0.0.1:*` style local origins only (see `ServerConfig.isLocalDevelopmentOrigin`).

---

### `MONGODB_URI`

| Field | Value |
| --- | --- |
| Required | **Yes in production**. Optional for local boot (readiness fails without it) |
| Secret? | **Yes** |
| Validation | Non-empty in production |
| Purpose | Atlas connection for the API only |
| Example | `mongodb+srv://USER:PASSWORD@CLUSTER/DB?retryWrites=true&w=majority` |

Never log or return this value. Flutter must never receive it.

---

### `ACCESS_TOKEN_SECRET`

| Field | Value |
| --- | --- |
| Required | **Yes in production** |
| Secret? | **Yes** |
| Validation | Production: non-empty and ≥ **32 UTF-8 bytes**. Token services also enforce minimum length |
| Purpose | HS256 signing key for access JWTs |
| Example | `REPLACE_WITH_CRYPTORANDOM_AT_LEAST_32_BYTES_LONG` |

Rotation invalidates outstanding access JWTs.

---

### `SANDBOX_PAYMENT_WEBHOOK_SECRET`

| Field | Value |
| --- | --- |
| Required | Only when exercising sandbox payments in development/test |
| Secret? | **Yes** |
| Validation | Runtime sandbox init expects ≥32 UTF-8 bytes when used |
| Purpose | HMAC key for sandbox payment webhooks |
| Example | `REPLACE_DEV_ONLY_PAYMENT_WEBHOOK_SECRET_32B_MIN` |

Ignored for enabling sandbox in production (sandbox not allowed).

---

### `SANDBOX_PAYOUT_WEBHOOK_SECRET`

| Field | Value |
| --- | --- |
| Required | Only when exercising sandbox payouts in development/test |
| Secret? | **Yes** |
| Validation | ≥32 UTF-8 bytes when sandbox payouts used |
| Purpose | HMAC key for sandbox payout webhooks |
| Example | `REPLACE_DEV_ONLY_PAYOUT_WEBHOOK_SECRET_32B_MIN` |

---

### `PLATFORM_COMMISSION_BPS`

| Field | Value |
| --- | --- |
| Required | **Explicit required in production** |
| Secret? | No |
| Validation | Integer `0`–`10000`. Invalid explicit value → default used but marked invalid; production boot requires explicit valid value |
| Purpose | Platform commission snapshot for new earnings (basis points) |
| Example | `1500` (= 15%) |

Changing this does not rewrite historical earnings rows.

---

### `PORT`

| Field | Value |
| --- | --- |
| Required | Optional |
| Secret? | No |
| Validation | Absent → `8080`. Explicit value must be a decimal integer `1`–`65535`. Explicit empty / non-numeric / `0` / negative / `>65535` → **startup failure** (non-zero exit). Does not silently fall back to `8080` for an invalid explicit value. |
| Purpose | HTTP listen port inside container/host |
| Example | `8080` |

Validated by the repository-owned Dart Frog custom entrypoint (`backend/main.dart` → `PortConfig`) **before** the socket binds. Dockerfile sets `ENV PORT=8080` and exposes `8080`.

**Honesty note:** Dart Frog’s generated `build/bin/server.dart` still contains `int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080` before calling the custom `run` hook. The supported production path (Docker image / compiled server built with `backend/main.dart`) re-validates in that hook and exits non-zero for invalid explicit `PORT` before serving. Do not treat the generated `tryParse` fallback alone as the production policy.

---

## Flutter variables

### `API_BASE_URL`

| Field | Value |
| --- | --- |
| Required | **Yes for release builds** |
| Secret? | **No** (public; extractable from the binary) |
| Validation | Release: absolute `https://` URI with host. Debug may use `http://` for emulator (`http://10.0.2.2:8080`) |
| Purpose | Dio base URL for the API |
| Example | `https://api.example.com` |

Pass at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

### dart-define is not a secret store

Anything supplied via `--dart-define` can be recovered from the shipped app. Backend secrets belong only in server environment / secret managers.

---

## Android signing (local files, not env vars)

| File | Secret? | Purpose |
| --- | --- | --- |
| `project/android/key.properties` | Yes | Points release build at keystore |
| Upload keystore (`.jks` / `.keystore`) | Yes | Play signing |

Do not commit these files. See [android-release-runbook.md](android-release-runbook.md).

---

## Example files

* Backend template: `backend/.env.example` (empty placeholders)
* Real `backend/.env` must remain gitignored
