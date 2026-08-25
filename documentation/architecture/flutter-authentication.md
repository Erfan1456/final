# Flutter Authentication

This document describes the Flutter authentication vertical slice: secure token storage, Dio clients, single-flight refresh, Riverpod session state, and go_router guards.

See [protected-api-authentication.md](protected-api-authentication.md), [flutter-client-architecture.md](flutter-client-architecture.md), [../api/authentication-api.md](../api/authentication-api.md), and [../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md](../decisions/ADR-010-flutter-authentication-and-secure-session-storage.md).

## Layering

```text
Flutter UI
   ↓
AuthController
   ↓
AuthRepository
   ↓
AuthApi
   ↓
Plain Dio / Authenticated Dio
   ↓
Dart Frog API
```

Identity is **not** decoded from the access JWT in Flutter. `GET /api/v1/account/me` is authoritative for the current account.

## Authenticated refresh path

```text
Authenticated Dio
   ↓ 401
Single-flight refresh coordinator
   ↓
POST /auth/refresh using Plain Dio
   ↓
FlutterSecureStorage
   ↓
retry original request
```

`POST /api/v1/auth/refresh` is never processed through the authenticated interceptor. A retried request carries `extra['auth_retry'] = true` so it is retried at most once.

## Secure token-pair storage

Flutter stores **only** authentication credentials in platform secure storage:

* access token
* refresh token

They are stored as **one JSON value** under one stable key (`auth.token_pair`):

```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

Corrupt or malformed JSON is cleared and treated as no session. Startup must not crash.

Do not store password, password hash, MongoDB URI, `ACCESS_TOKEN_SECRET`, or user profile JSON.

Never print the stored value. Never log it. Never put it in SharedPreferences. Never hard-code development tokens.

`flutter_secure_storage` 11.0.0 is the approved storage package. Default plugin options are used. Biometric storage is not configured.

## Session restoration

App startup:

```text
secure storage
    ↓
token pair exists?
    ↓
NO → unauthenticated → Login
YES
    ↓
GET /api/v1/account/me
    ↓
access token valid → authenticated
401 because access expired
    ↓
single refresh attempt
    ↓
store rotated token pair
    ↓
retry current-user request
    ↓
authenticated
```

If refresh fails:

* delete local secure tokens
* become unauthenticated
* redirect to Login

## Automatic refresh and concurrency

Refresh tokens **rotate**. Multiple concurrent HTTP 401 responses must not each send the same refresh token.

`SingleFlightRefresher` keeps at most one in-flight refresh `Future`. Concurrent protected 401s wait for that result.

On success:

* persist the new token pair
* retry waiting requests with the new access token

On failure:

* clear stored credentials once
* emit one `sessionExpired` event
* do not enter a refresh loop

## Session-expiry event

The network interceptor reports `sessionExpired` through a small Riverpod-provided broadcast stream (`AuthSessionEventBus`). `AuthController` subscribes and becomes unauthenticated. The interceptor does not depend on UI widgets.

## Logout behavior

`logout`:

1. read the refresh token
2. attempt `POST /api/v1/auth/logout`
3. **always** clear local storage in `finally`
4. become unauthenticated even if the network is unavailable

`logoutAll`:

1. call protected `DELETE /api/v1/account/sessions` if possible
2. clear local storage afterward
3. local device becomes unauthenticated

Do not preserve tokens after the user explicitly logs out.

The access JWT used for logout-all may remain valid for up to 15 minutes on the server. Flutter still deletes local tokens immediately.

## Routing guards

Routes:

* `/splash` — session restoration only
* `/login`
* `/signup`
* `/home` — authenticated account placeholder

Rules:

* restoring → `/splash`
* unauthenticated → `/login`
* unauthenticated may access `/login` and `/signup`
* authenticated → `/home`
* authenticated visiting `/login`, `/signup`, or `/splash` → `/home`

A stable `GoRouter` instance uses `refreshListenable` so redirects react to auth state without recreating the router.

## Dio clients

**Plain Dio** is used for signup, login, refresh, and logout. It does not attach Bearer tokens and does not refresh.

**Authenticated Dio** is used for `/account/me`, logout-all, and future protected APIs. It attaches `Authorization: Bearer <access-token>` and handles expired access tokens through the single-flight refresher.

They share `BaseOptions` / `API_BASE_URL`. There is no `LogInterceptor` that prints headers or bodies.

`API_BASE_URL` is compile-time public configuration via `String.fromEnvironment`. If it is missing, the app still boots. Auth submissions show a safe configuration error instead of crashing.

## Android emulator development

From `backend/`:

```bash
dart_frog dev
```

From `project/`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` is the Android emulator route to the host machine. `localhost` inside the emulator is the emulator itself.

Debug-only Android network security config may permit cleartext HTTP to `10.0.2.2`, `localhost`, and `127.0.0.1`. Release / `src/main` configuration is not weakened. Production API must use HTTPS.

## Screens

* **Splash** — app name, progress indicator, “Restoring session…”
* **Login** — email, obscured password; no 15-character minimum before submit
* **Signup** — email, password, Customer/Cleaner role; no Admin option
* **Authenticated home** — safe email, role, verification status; Log out; Log out all devices

Marketplace, bookings, payments, and cleaner lists are not part of this slice.
