# Viva guide: which files do which job

Use this as a speaking map. Start from **role → screen → controller → API file → backend service → Mongo collection**. Do not memorize every filename.

**Product:** Home Cleaning Service Marketplace  
**Stack:** Flutter (`project/`) + Dart Frog (`backend/`) + MongoDB Atlas  
**Roles:** customer, cleaner, admin

**Demo note (current app):** payment, payout, disputes, earnings, and finance screens are **retired from the three role UIs**. Routes that contain `/payment`, `/payout`, `/dispute`, `/finance`, or `/earnings` redirect home (`app_router.dart` + `AppRoutes.isRetiredCommercePath`). The **backend APIs and leftover Flutter widgets still exist**. If asked “did you implement payment?”, say: ledger and sandbox APIs are implemented; the **client no longer exposes those systems**.

---

## 1. Repository roots

| Path | Job |
|------|-----|
| `project/` | Flutter package (`pubspec.yaml`). Run `flutter run` / `flutter test` here. |
| `backend/` | Dart Frog API. Run `dart_frog dev` / `dart test` here. |
| `documentation/` | Architecture, API, database, ADRs, this viva map. |
| `.github/workflows/ci.yml` | CI: backend analyze+test, Flutter analyze+test. |
| `tools/` | Extra release-check scripts. |

---

## 2. How every feature is layered (say this first)

### Flutter (`project/lib/features/<name>/`)

| Folder | Job |
|--------|-----|
| `presentation/*_screen.dart` | UI the examiner sees. |
| `presentation/*_controller.dart` | Riverpod state: load, mutate, errors. |
| `data/*_api.dart` | HTTP calls (Dio) to `/api/v1/...`. |
| `data/*_models.dart` | JSON parse / domain DTOs on the client. |

Shared client plumbing:

| File | Job |
|------|-----|
| `project/lib/main.dart` | Starts the app, reads `AppConfig`, wraps `ProviderScope`. |
| `project/lib/app/app.dart` | Root `MaterialApp.router`. |
| `project/lib/app/theme/app_theme.dart` | Theme. |
| `project/lib/app/router/app_router.dart` | All GoRouter routes + auth/role redirects. |
| `project/lib/app/router/app_routes.dart` | Path constants; role homes; retired commerce paths. |
| `project/lib/core/config/app_config.dart` | `API_BASE_URL` and related dart-defines. |
| `project/lib/core/network/dio_provider.dart` | HTTP client, attach access token, refresh. |
| `project/lib/core/network/api_envelope.dart` | Parse `{ data, error }` API envelope. |
| `project/lib/core/network/api_failure.dart` | Typed API errors for UI. |
| `project/lib/shared/widgets/` | Dialogs, loading/empty, status chips, sections. |

### Backend (`backend/`)

Dart Frog maps **file path → HTTP path**. Example: `routes/api/v1/auth/login.dart` → `POST /api/v1/auth/login`.

| Layer | Job |
|-------|-----|
| `backend/routes/...` | Thin HTTP: parse body, call a service, return JSON. |
| `backend/routes/.../_middleware.dart` | Auth + role gate for that subtree. |
| `backend/lib/src/features/<x>/application/` | **Business rules** (the “why”). |
| `backend/lib/src/features/<x>/domain/` | Entities, statuses, validation, exceptions. |
| `backend/lib/src/features/<x>/data/` | Mongo repositories and indexes. |
| `backend/lib/src/config/` | Env / `ServerConfig`. |
| `backend/lib/src/database/` | Mongo connection lifecycle. |
| `backend/lib/src/http/` | JSON envelope, CORS, security headers, request IDs. |
| `backend/routes/_middleware.dart` | Global: load config, Mongo, CORS, headers. |

If asked “where is the logic?”, answer **application services**, not the route file.

---

## 3. Cross-cutting backend (security and HTTP)

| File | Function |
|------|----------|
| `backend/routes/_middleware.dart` | Boot config + Mongo; attach to every request. |
| `backend/lib/src/features/auth/http/access_authenticator.dart` | Validate JWT access token. |
| `backend/lib/src/features/authorization/http/role_middleware.dart` | Require customer / cleaner / admin. |
| `backend/lib/src/features/authorization/role_authorizer.dart` | Role checks used by services. |
| `backend/lib/src/http/json_response.dart` | Standard success/error JSON. |
| `backend/lib/src/http/security_headers.dart` | Security headers. |
| `backend/lib/src/http/cors_headers.dart` | CORS. |
| `backend/routes/api/v1/health.dart` | Liveness. |
| `backend/routes/api/v1/ready.dart` | Readiness (DB). |

---

## 4. Authentication and account security

**What it does:** signup, login, JWT + refresh rotation, logout, email-verify tokens, password reset/change, current user.

### Backend routes

| File | Function |
|------|----------|
| `backend/routes/api/v1/auth/signup.dart` | Create customer or cleaner account (not admin). |
| `backend/routes/api/v1/auth/login.dart` | Issue access + refresh session. |
| `backend/routes/api/v1/auth/refresh.dart` | Rotate refresh token. |
| `backend/routes/api/v1/auth/logout.dart` | End this session. |
| `backend/routes/api/v1/auth/email-verification/request.dart` | Start verify-email. |
| `backend/routes/api/v1/auth/email-verification/verify.dart` | Confirm token. |
| `backend/routes/api/v1/auth/password-reset/request.dart` | Start reset. |
| `backend/routes/api/v1/auth/password-reset/confirm.dart` | Set new password from token. |
| `backend/routes/api/v1/account/me.dart` | Current authenticated user. |
| `backend/routes/api/v1/account/password/change.dart` | Change password while logged in. |
| `backend/routes/api/v1/account/sessions/` | Session list/revoke APIs (UI for this was removed). |

### Backend brain

| File | Function |
|------|----------|
| `authentication_service.dart` | Login, signup, logout, refresh. |
| `auth_composition.dart` | Wires hasher, tokens, sessions. |
| `access_token_service.dart` | JWT access tokens. |
| `argon2id_password_hasher.dart` | Password hashing. |
| `password_policy.dart` | Password rules. |
| `account_security_service.dart` | Change password, sessions. |
| `current_account_service.dart` | `/account/me`. |
| `account_action_token_service.dart` | Email verify / reset tokens. |
| `development_account_action_delivery_provider.dart` | **Does not send real email** (dev delivery). |

### Flutter

| File | Function |
|------|----------|
| `features/auth/data/auth_api.dart` | Auth HTTP. |
| `features/auth/data/auth_repository.dart` | Persist session, refresh. |
| `auth_token_storage.dart`, `flutter_secure_auth_token_storage.dart` | Secure token storage. |
| `auth_interceptor.dart`, `single_flight_refresher.dart` | Attach JWT; one refresh in flight. |
| `features/auth/presentation/auth_controller.dart` | Login/signup/logout state. |
| `login_screen.dart` / `signup_screen.dart` | Auth UI. |
| `splash_screen.dart` | Restore session on launch. |
| `verification_pending_screen.dart` | Wait for email verify. |
| `forgot_password_screen.dart` / `reset_password_screen.dart` | Recovery UI. |
| `account_security_screen.dart` | Change password (sessions UI removed). |
| `logout_actions.dart` | Log out this device. |
| `authenticated_home_screen.dart` | Unused placeholder; real homes are role screens. |

**Role dashboards after login** (`app_router.dart` picks by role):

| File | Function |
|------|----------|
| `features/customer/presentation/customer_home_screen.dart` | Customer home. |
| `features/cleaner/presentation/cleaner_home_screen.dart` | Cleaner home. |
| `features/admin/presentation/admin_home_screen.dart` | Admin home. |

---

## 5. Customer profile and addresses

| Flutter | Backend service / routes | Function |
|---------|--------------------------|----------|
| `customer_profile_screen.dart` + `customer_profile_controller.dart` | `customer_account_service.dart`, `customer/profile.dart` | Name, phone. |
| `customer_profile_api.dart` | Mongo customer profiles | Persist profile. |
| `address_list_screen.dart`, `address_form_screen.dart`, `address_controller.dart` | `customer/addresses/*.dart` | CRUD addresses, set default. |
| `addresses/data/address.dart` | address domain + repository | Address model. |

---

## 6. Cleaner onboarding and admin approval

| Flutter | Backend | Function |
|---------|---------|----------|
| `cleaner_onboarding_screen.dart` + `cleaner_onboarding_controller.dart` | `cleaner_onboarding_service.dart`, `cleaner/profile.dart`, `cleaner/onboarding/submit.dart` | Draft profile, submit for review. |
| `cleaner_profile_api.dart` | cleaner profile repository | Persist onboarding. |
| `cleaner_approval_list_screen.dart`, `cleaner_approval_detail_screen.dart`, `admin_cleaner_review_controller.dart` | `admin_cleaner_review_service.dart`, `admin/cleaners/*` | List pending, approve/reject. |

Without **approved** status, cleaner cannot offer services / take jobs (enforced in services).

---

## 7. Catalog, cleaner services, availability, discovery

| Flutter | Backend | Function |
|---------|---------|----------|
| `catalog_controller.dart` | `services.dart`, `canonical_service_catalog.dart` | Canonical marketplace services (e.g. home cleaning). |
| `cleaner_service_management_screen.dart` + `cleaner_service_controller.dart` | `cleaner_service_management_service.dart`, `cleaner/services/` | Cleaner opts into services and rates. |
| `cleaner_availability_screen.dart`, `cleaner_availability_form_screen.dart`, `availability_controller.dart` | `cleaner_availability_service.dart`, `availability_validation.dart`, `cleaner/availability/` | UTC windows (future start, 60 min–8 h, 30-min steps). |
| `availability_window.dart` | — | Client helper so the form sends a valid window. |
| `cleaner_discovery_screen.dart`, `cleaner_discovery_detail_screen.dart`, `discovery_controller.dart` | `cleaner_discovery_service.dart`, `discovery/cleaners/` | Search approved cleaners + slots. |
| `cleaner_comparison_screen.dart` + `comparison_controller.dart` | discovery detail | Compare cleaners locally. |

---

## 8. Bookings (core marketplace)

Lifecycle (typical): customer creates from a slot → cleaner accept/decline → start → complete; cancel at allowed stages.

| Flutter | Backend | Function |
|---------|---------|----------|
| `customer_booking_list_screen.dart`, `customer_booking_detail_screen.dart`, `customer_booking_controller.dart` | `customer_booking_service.dart`, `customer/bookings/` | Create, list, detail, cancel. |
| `cleaner_booking_list_screen.dart`, `cleaner_booking_detail_screen.dart`, `cleaner_booking_controller.dart` | `cleaner_booking_service.dart`, `cleaner/bookings/{accept,decline,start,complete,cancel}` | Job inbox and transitions. |
| `booking_api.dart`, `booking_models.dart` | booking domain + repository | Snapshots of service, address, quote. |
| `booking_idempotency.dart` | booking create idempotency | Same key does not double-book. |
| `booking_widgets.dart` | — | Shared address/history display. |
| `admin_booking_list_screen.dart`, `admin_booking_detail_screen.dart`, `admin_booking_operations_controller.dart` | `admin_booking_operations_service.dart`, `admin/bookings/` | Admin list/detail/cancel. |

Quote math lives in `booking_quotation.dart` on the backend (immutable snapshot on the booking).

---

## 9. Chat, notifications, reviews (still in the app)

| Flutter | Backend | Function |
|---------|---------|----------|
| `booking_chat_screen.dart` + `booking_chat_controller.dart` | `booking_conversation_service.dart`, `conversations/` | Per-booking messages, mark read. |
| `notification_center_screen.dart` + `notification_controller.dart` | `notification_service.dart`, `notifications/` | Inbox, unread count, mark read. |
| `notification_home_link.dart` | — | Home shortcut to inbox. |
| `customer_review_screen.dart` + `customer_review_controller.dart` | `customer_review_service.dart`, `customer/bookings/.../review` | Customer rates completed job. |
| `cleaner_reviews_screen.dart` + `cleaner_reviews_controller.dart` | `cleaner_review_service.dart`, `cleaner/reviews/` | Public reviews on a cleaner. |
| `admin_review_list_screen.dart`, `admin_review_detail_screen.dart` | `admin_review_moderation_service.dart`, `admin/reviews/{hide,unhide}` | Hide/unhide reviews. |

---

## 10. Admin users and audit (still in the app)

| Flutter | Backend | Function |
|---------|---------|----------|
| `admin_user_list_screen.dart`, `admin_user_detail_screen.dart`, `admin_user_management_controller.dart` | `admin_user_management_service.dart`, `admin/users/{suspend,reactivate,deactivate}` | Moderate accounts. |
| `admin_audit_list_screen.dart`, `admin_audit_detail_screen.dart`, `admin_audit_log_controller.dart` | `audit_log_service.dart`, `admin/audit-logs/` | Who did what (sensitive actions). |

---

## 11. Payment, payout, disputes, finance, earnings (API exists; UI retired)

Say: **implemented on the server; hidden in the Flutter role dashboards.**

| Area | Flutter (orphaned / redirect) | Backend brain | Routes |
|------|-------------------------------|---------------|--------|
| Customer pay | `customer_payment_screen.dart`, `customer_payment_controller.dart` | `customer_payment_service.dart`, webhook + HMAC | `customer/bookings/.../payment/`, `payments/webhooks/sandbox.dart`, `dev/payments/.../simulate.dart` |
| Admin pay/refund | `admin_payment_*_screen.dart` | `admin_payment_service.dart` | `admin/payments/` |
| Disputes | `booking_dispute_screen.dart`, admin dispute screens | `booking_dispute_service.dart`, `admin_dispute_service.dart` | `bookings/.../dispute/`, `admin/disputes/` |
| Cleaner earnings/payouts | `cleaner_earnings_screen.dart`, earnings controller | `earnings_settlement_service.dart`, `cleaner_payout_service.dart` | `cleaner/earnings/`, `cleaner/payouts/` |
| Admin payouts/finance | `admin_payout_screens.dart`, `admin_finance_screens.dart` | `admin_payout_service.dart`, `admin_finance_service.dart` | `admin/payouts/`, `admin/finance/` |

Sandbox limitation for viva: **no real cards or bank transfers**; simulation + HMAC webhooks only.

---

## 12. MongoDB: which collection matches which feature

Full schemas live under `documentation/database/`. Short map:

| Concern | Typical collections (see `documentation/database/`) |
|---------|-----------------------------------------------------|
| Auth | users, user sessions, account action tokens |
| Profiles | customer profiles, cleaner profiles, addresses |
| Supply | marketplace services, cleaner service offerings, availability slots |
| Demand | bookings |
| Chat | conversations, messages |
| Social | notifications, reviews |
| Commerce (API) | payments, refunds, webhook events, disputes, earnings, payouts |
| Admin | audit logs |

Indexes: `*_indexes.dart` next to each repository.

---

## 13. Tests (if asked “how do you know it works?”)

| Location | Job |
|----------|-----|
| `backend/test/src/features/` | Domain + service unit tests. |
| `backend/test/routes/` | HTTP route tests. |
| `project/test/features/` | Widget tests per feature. |
| `project/test/acceptance/` | Full-app journeys (customer / cleaner / admin). |
| `project/test/app/router/` | Role redirect and retired-path tests. |
| `.github/workflows/ci.yml` | Same analyze+test on GitHub. |

---

## 14. Suggested viva walkthrough (3 minutes)

1. **Two apps:** Flutter talks HTTPS to Dart Frog; Dart Frog talks to Atlas.  
2. **Three roles:** router sends each user to a different home.  
3. **Happy path:** signup/login → customer profile + address → discovery → book slot → cleaner accept → chat → complete → review.  
4. **Admin:** approve cleaners, moderate users/reviews, bookings, audit.  
5. **Security:** Argon2id passwords, JWT access + rotating refresh, role middleware.  
6. **Honesty:** email and money providers are development/sandbox; payment UI is currently off in the app.

---

## 15. If they point at a file and ask “what is this?”

- `*_screen.dart` → UI  
- `*_controller.dart` → client state  
- `*_api.dart` → HTTP  
- `routes/api/v1/...dart` → one HTTP endpoint  
- `*_service.dart` under `application/` → business rules  
- `*_repository.dart` → Mongo  
- `*_middleware.dart` → auth/role for that URL prefix  
- `app_router.dart` → navigation and “who can open this page”
