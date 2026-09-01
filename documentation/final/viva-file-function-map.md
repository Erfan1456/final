# Viva map: action → frontend → backend

Every row is something the **app can do**. Columns match section 5 style: **Action**, **Frontend**, **Backend**.

**How to read a row**

- **Frontend** = screen the user taps + Riverpod controller + `*_api.dart` HTTP client under `project/lib/`
- **Backend** = Dart Frog route under `backend/routes/api/v1/` + application service under `backend/lib/src/features/`

Shared on almost every call: `project/lib/core/network/dio_provider.dart` (HTTP + JWT), `backend/routes/_middleware.dart` (config, Mongo, CORS). After login, `project/lib/app/router/app_router.dart` sends the user to customer / cleaner / admin home.

**Demo note:** payment, payout, dispute, earnings, and finance are **not in the role menus**. Those URLs redirect home. They are listed last as “API only.”

---

## 1. Start the app

| Action | Frontend | Backend |
|--------|----------|---------|
| Launch app | `project/lib/main.dart`, `project/lib/app/app.dart` | — |
| Read API URL | `project/lib/core/config/app_config.dart` | `backend/lib/src/config/server_config.dart` |
| Restore saved login | `splash_screen.dart`, `auth_controller.dart`, `auth_repository.dart`, `flutter_secure_auth_token_storage.dart` | `routes/api/v1/account/me.dart`, `current_account_service.dart` |
| Open role home | `app_router.dart`, `customer_home_screen.dart` / `cleaner_home_screen.dart` / `admin_home_screen.dart` | — |
| Health / ready (ops, not a button) | — | `routes/api/v1/health.dart`, `routes/api/v1/ready.dart` |

---

## 2. Login system (signup, login, logout, password)

| Action | Frontend | Backend |
|--------|----------|---------|
| Sign up (customer or cleaner) | `signup_screen.dart`, `auth_controller.dart`, `auth_api.dart` | `routes/api/v1/auth/signup.dart`, `authentication_service.dart` |
| Log in | `login_screen.dart`, `auth_controller.dart`, `auth_api.dart` | `routes/api/v1/auth/login.dart`, `authentication_service.dart` |
| Refresh session (automatic) | `auth_interceptor.dart`, `single_flight_refresher.dart`, `auth_repository.dart` | `routes/api/v1/auth/refresh.dart`, `authentication_service.dart` |
| Log out (this device) | `logout_actions.dart`, `auth_controller.dart` | `routes/api/v1/auth/logout.dart`, `authentication_service.dart` |
| Wait for email verification | `verification_pending_screen.dart`, `email_verification_controller.dart` | `routes/api/v1/auth/email-verification/request.dart`, `.../verify.dart`, `account_action_token_service.dart` |
| Forgot password | `forgot_password_screen.dart`, `password_recovery_controller.dart` | `routes/api/v1/auth/password-reset/request.dart` |
| Reset password with token | `reset_password_screen.dart`, `password_recovery_controller.dart` | `routes/api/v1/auth/password-reset/confirm.dart` |
| Open security | `account_security_screen.dart` | — |
| Change password | `change_password_screen.dart`, `account_security_controller.dart` | `routes/api/v1/account/password/change.dart`, `account_security_service.dart` |
| Hash password / issue JWT (not a screen) | — | `argon2id_password_hasher.dart`, `password_policy.dart`, `access_token_service.dart` |
| Session list/revoke APIs (no UI) | redirected away from sessions screen | `routes/api/v1/account/sessions/index.dart`, `.../sessions/[sessionId].dart` |

Email tokens exist; **real inbox delivery is development-only** (`development_account_action_delivery_provider.dart`).

---

## 3. Customer profile and addresses

| Action | Frontend | Backend |
|--------|----------|---------|
| View / save customer profile (name, phone) | `customer_profile_screen.dart`, `customer_profile_controller.dart`, `customer_profile_api.dart` | `routes/api/v1/customer/profile.dart`, `customer_account_service.dart` |
| List addresses | `address_list_screen.dart`, `address_controller.dart`, `address_api.dart` | `routes/api/v1/customer/addresses/index.dart` |
| Add / edit address | `address_form_screen.dart`, `address_controller.dart` | `routes/api/v1/customer/addresses/index.dart`, `addresses/[addressId]/index.dart` |
| Set default address | `address_list_screen.dart`, `address_controller.dart` | `routes/api/v1/customer/addresses/[addressId]/default.dart` |
| Address model | `addresses/data/address.dart` | address domain + repository under `backend/lib/src/features/addresses/` |

Customer home buttons: Profile, Addresses (`customer_home_screen.dart`).

---

## 4. Customer: find a cleaner and book

| Action | Frontend | Backend |
|--------|----------|---------|
| Load service catalog (home cleaning types) | `catalog_controller.dart`, `service_catalog_api.dart` | `routes/api/v1/services.dart`, `canonical_service_catalog.dart` |
| Search / list cleaners | `cleaner_discovery_screen.dart`, `discovery_controller.dart`, `discovery_api.dart` | `routes/api/v1/discovery/cleaners/index.dart`, `cleaner_discovery_service.dart` |
| Open cleaner detail + slots | `cleaner_discovery_detail_screen.dart`, `discovery_controller.dart` | `routes/api/v1/discovery/cleaners/[cleanerUserId]/index.dart` |
| Compare cleaners | `cleaner_comparison_screen.dart`, `comparison_controller.dart` | uses discovery detail data (comparison is local) |
| Create booking from a slot | discovery detail → booking flow, `customer_booking_controller.dart`, `booking_api.dart`, `booking_idempotency.dart` | `routes/api/v1/customer/bookings/index.dart`, `customer_booking_service.dart` |
| Booking confirmation | `booking_confirmation_screen.dart` | same create-booking response |
| List my bookings | `customer_booking_list_screen.dart`, `customer_booking_controller.dart` | `routes/api/v1/customer/bookings/index.dart` |
| Open booking detail | `customer_booking_detail_screen.dart` | `routes/api/v1/customer/bookings/[bookingId]/index.dart` |
| Cancel my booking | `customer_booking_detail_screen.dart` | `routes/api/v1/customer/bookings/[bookingId]/cancel.dart` |
| Quote / snapshots (not a button) | `booking_models.dart`, `booking_widgets.dart` | `booking_quotation.dart`, booking repository |

---

## 5. Cleaner: onboarding, services, availability, jobs

| Action | Frontend | Backend |
|--------|----------|---------|
| Start / edit onboarding | `cleaner_onboarding_screen.dart`, `cleaner_onboarding_controller.dart`, `cleaner_profile_api.dart` | `routes/api/v1/cleaner/profile.dart`, `cleaner_onboarding_service.dart` |
| Submit application | same onboarding screen | `routes/api/v1/cleaner/onboarding/submit.dart` |
| Manage services and rates (approved only) | `cleaner_service_management_screen.dart`, `cleaner_service_controller.dart`, `cleaner_service_api.dart` | `routes/api/v1/cleaner/services/index.dart`, `.../services/[serviceId]/index.dart`, `cleaner_service_management_service.dart` |
| List availability | `cleaner_availability_screen.dart`, `availability_controller.dart`, `availability_api.dart` | `routes/api/v1/cleaner/availability/index.dart`, `cleaner_availability_service.dart` |
| Create / edit / delete a window | `cleaner_availability_form_screen.dart`, `availability_window.dart` | `routes/api/v1/cleaner/availability/index.dart`, `.../[slotId]/index.dart`, `availability_validation.dart` |
| Job inbox | `cleaner_booking_list_screen.dart`, `cleaner_booking_controller.dart`, `booking_api.dart` | `routes/api/v1/cleaner/bookings/index.dart`, `cleaner_booking_service.dart` |
| Open job detail | `cleaner_booking_detail_screen.dart` | `routes/api/v1/cleaner/bookings/[bookingId]/index.dart` |
| Accept job | cleaner booking detail | `.../bookings/[bookingId]/accept.dart` |
| Decline job | cleaner booking detail | `.../bookings/[bookingId]/decline.dart` |
| Start job | cleaner booking detail | `.../bookings/[bookingId]/start.dart` |
| Complete job | cleaner booking detail | `.../bookings/[bookingId]/complete.dart` |
| Cancel job | cleaner booking detail | `.../bookings/[bookingId]/cancel.dart` |
| See my public reviews | `cleaner_reviews_screen.dart`, `cleaner_reviews_controller.dart`, `review_api.dart` | `routes/api/v1/cleaner/reviews/index.dart`, `cleaner_review_service.dart` |

Unapproved cleaners cannot take marketplace jobs (enforced in services).

---

## 6. Chat, notifications, reviews (all roles that have the screens)

| Action | Frontend | Backend |
|--------|----------|---------|
| Open booking chat | `booking_chat_screen.dart`, `booking_chat_controller.dart`, `chat_api.dart` | `routes/api/v1/conversations/booking/[bookingId]/index.dart`, `booking_conversation_service.dart` |
| Send / list messages | same | `routes/api/v1/conversations/[conversationId]/messages.dart` |
| Mark conversation read | same | `routes/api/v1/conversations/[conversationId]/read.dart` |
| Open notifications | `notification_center_screen.dart`, `notification_home_link.dart`, `notification_controller.dart`, `notification_api.dart` | `routes/api/v1/notifications/index.dart`, `notification_service.dart` |
| Unread count | notification controller | `routes/api/v1/notifications/unread-count.dart` |
| Mark one / all read | notification center | `notifications/[notificationId]/read.dart`, `notifications/read-all.dart` |
| Customer write review | `customer_review_screen.dart`, `customer_review_controller.dart`, `review_api.dart` (from booking detail) | `routes/api/v1/customer/bookings/[bookingId]/review.dart`, `customer_review_service.dart` |

---

## 7. Admin reporting and operations

| Action | Frontend | Backend |
|--------|----------|---------|
| Approvals list | `cleaner_approval_list_screen.dart`, `admin_cleaner_review_controller.dart`, `admin_cleaner_api.dart` | `routes/api/v1/admin/cleaners/index.dart`, `admin_cleaner_review_service.dart` |
| Approval detail | `cleaner_approval_detail_screen.dart` | `routes/api/v1/admin/cleaners/[userId]/index.dart` |
| Approve cleaner | approval detail | `.../cleaners/[userId]/approve.dart` |
| Reject cleaner | approval detail | `.../cleaners/[userId]/reject.dart` |
| User list | `admin_user_list_screen.dart`, `admin_user_management_controller.dart`, `admin_user_api.dart` | `routes/api/v1/admin/users/index.dart`, `admin_user_management_service.dart` |
| User detail | `admin_user_detail_screen.dart` | `routes/api/v1/admin/users/[userId]/index.dart` |
| Suspend user | user detail | `.../users/[userId]/suspend.dart` |
| Reactivate user | user detail | `.../users/[userId]/reactivate.dart` |
| Deactivate user | user detail | `.../users/[userId]/deactivate.dart` |
| Booking list | `admin_booking_list_screen.dart`, `admin_booking_operations_controller.dart`, `admin_booking_api.dart` | `routes/api/v1/admin/bookings/index.dart`, `admin_booking_operations_service.dart` |
| Booking detail | `admin_booking_detail_screen.dart` | `routes/api/v1/admin/bookings/[bookingId]/index.dart` |
| Admin cancel booking | admin booking detail | `.../bookings/[bookingId]/cancel.dart` |
| Review list | `admin_review_list_screen.dart`, `admin_review_controller.dart`, `review_api.dart` | `routes/api/v1/admin/reviews/index.dart`, `admin_review_moderation_service.dart` |
| Review detail | `admin_review_detail_screen.dart` | `routes/api/v1/admin/reviews/[reviewId]/index.dart` |
| Hide review | review detail | `.../reviews/[reviewId]/hide.dart` |
| Unhide review | review detail | `.../reviews/[reviewId]/unhide.dart` |
| Audit log list | `admin_audit_list_screen.dart`, `admin_audit_log_controller.dart`, `audit_api.dart` | `routes/api/v1/admin/audit-logs/index.dart`, `audit_log_service.dart` |
| Audit log detail | `admin_audit_detail_screen.dart` | `routes/api/v1/admin/audit-logs/[auditLogId]/index.dart` |

Admin home buttons: Approvals, Users, Bookings, Review Moderation, Audit Log, Notifications, Security, Log out (`admin_home_screen.dart`).

Role gates: `backend/lib/src/features/authorization/http/role_middleware.dart` plus `customer/_middleware.dart`, `cleaner/_middleware.dart`, `admin/_middleware.dart`.

---

## 8. Not in the app menus (API still exists)

If asked: **sandbox only, no real money; UI redirects home** (`AppRoutes.isRetiredCommercePath` in `app_routes.dart`).

| Action | Frontend (orphaned / redirect) | Backend |
|--------|--------------------------------|---------|
| Customer pay / cancel / sandbox simulate | `customer_payment_screen.dart`, `customer_payment_controller.dart`, `payment_api.dart` | `customer/bookings/[bookingId]/payment/`, `payments/webhooks/sandbox.dart`, `dev/payments/[paymentId]/simulate.dart`, `customer_payment_service.dart` |
| Admin payments / refund | `admin_payment_list_screen.dart`, `admin_payment_detail_screen.dart` | `admin/payments/`, `admin_payment_service.dart` |
| Open / close dispute | `booking_dispute_screen.dart`, `dispute_api.dart` | `bookings/[bookingId]/dispute/`, `booking_dispute_service.dart` |
| Admin disputes | `admin_dispute_list_screen.dart`, `admin_dispute_detail_screen.dart` | `admin/disputes/`, `admin_dispute_service.dart` |
| Cleaner earnings / payouts | `cleaner_earnings_screen.dart`, `earnings_api.dart` | `cleaner/earnings/`, `cleaner/payouts/`, `earnings_settlement_service.dart`, `cleaner_payout_service.dart` |
| Admin payouts / finance | `admin_payout_screens.dart`, `admin_finance_screens.dart` | `admin/payouts/`, `admin/finance/`, `admin_payout_service.dart`, `admin_finance_service.dart` |

---

## 9. File-name cheat sheet

| Suffix | Meaning |
|--------|---------|
| `*_screen.dart` | UI |
| `*_controller.dart` | Frontend state |
| `*_api.dart` | Frontend HTTP |
| `routes/api/v1/...dart` | One HTTP endpoint |
| `*_service.dart` | Backend business rules |
| `*_repository.dart` | Mongo |
| `_middleware.dart` | Auth / role for that URL prefix |
| `app_router.dart` | Which page opens, who is allowed |

---

## 10. Three-minute viva path

Signup / login → customer profile + address → find cleaner → book → cleaner accept → chat → complete → review. Admin: approve cleaner, users, bookings, reviews, audit. Logout from home. Payment screens are off.
