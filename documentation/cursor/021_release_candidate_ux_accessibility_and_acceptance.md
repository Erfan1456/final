# Cursor Task 021 — Release-Candidate UX, Accessibility, and Acceptance

## Metadata

- Task ID: 021
- Task title: Release-Candidate UX, Accessibility, Resilience, Cross-Role Acceptance Journeys, and Application Hardening
- Date: 2026-08-27
- Git branch: main (TASK 021 uncommitted for ChatGPT review)
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Objective

Turn the completed marketplace implementation into a cohesive release-candidate Flutter UX with shared presentation primitives, consistent loading/empty/error states, accessibility and responsive hardening, honest money/date/status presentation, cross-role acceptance journeys (no live Atlas), and documentation. No new business features, no AI, no deployment.

## Pre-Task Verification

- Branch: `main`
- Working tree: clean at start
- HEAD: TASK 020 checkpoint (`e227b2c` / account recovery)
- `documentation/cursor/020_...md` Status: SUCCESS
- `backend/.env` gitignored
- Backend baseline: `dart analyze` clean; **502 passed**
- Flutter baseline: `flutter analyze` clean; **370 passed**; debug APK success

## Dependencies

- No new Flutter third-party packages
- No new backend packages
- `integration_test` not required (acceptance covered under `test/acceptance/`)

## UX Inventory

Prior state: minimal Material 3 seed theme; no shared widgets layer; ad hoc ISO/local date strings; developer-facing minor-unit money; role homes as flat button lists; duplicated loading/empty/error patterns.

## Shared UI Foundation

Added under `project/lib/shared/`:

- presentation: spacing, layout constraints, date/time, money, status labels
- widgets: page scaffold helpers, async loading/empty/error, status chip, loading/danger buttons, confirmation dialog, sections, development banner, key/value row

## Theme and Layout

Extended `AppTheme` with Material 3 component themes (app bar, cards, inputs, buttons, chips, dialogs, snackbars). Form max width ~600, detail ~800, dashboard ~1100, page padding 16.

## Status Presentation

Central `AppStatusLabels` for booking/payment/payout/dispute/review/onboarding with safe unknown/unsupported fallbacks. `AppStatusChip` always includes text. Onboarding enum gained `.label`.

## Money Presentation

`formatMinorUnits` / re-exported `formatPaymentAmount` / `formatQuotedTotal` — no `/100`, no currency conversion.

## Date and Time Presentation

`formatAppDateTime` / `formatLocalDateTime` → local device time as `27 Aug 2026, 6:30 PM` style (SDK only).

## Loading / Empty / Error States

Shared `AppLoadingState`, `AppEmptyState`, `AppErrorState`, `AppAsyncContent`.

Empty states verified/added for: customer bookings; cleaner booking requests; chat; notifications; cleaner reviews; earnings; payout history; admin approvals; admin disputes; admin payouts. Dispute-none remains create-form CTA (clear intent). Representative GET screens expose safe error + Try Again (customer bookings / AppErrorState acceptance).

## Form Hardening Audit

Inspected major forms (signup, login, profile, address, onboarding, services, availability, booking, payment sandbox, review, dispute, admin moderation/cancel reasons, refund, payout, password recovery/change): required fields labeled; email trim; duplicate submit disabled via submitting/saving flags or loading buttons; backend authoritative; destructive flows use reason dialogs or `showAppConfirmationDialog` where applicable. No contradictory client-only validation added.

## Duplicate Submission Coverage

| Operation | Production guard | Test file / test name | Result |
|-----------|------------------|----------------------|--------|
| Booking create | `CustomerBookingController.submit` early-return on `submitting` + Confirm disabled | `customer_booking_controller_test.dart` → `submit reuses one idempotency key and ignores duplicate presses` | PASS |
| Message send | `BookingChatController.send` early-return on `sending` + Send disabled | `booking_chat_controller_test.dart` → `send reuses one key and ignores duplicate presses` | PASS |
| Payment start | `CustomerPaymentController.startPayment` early-return on `submitting` | `customer_payment_controller_test.dart` → `start reuses one key and ignores duplicate presses` | PASS |
| Payout request | `CleanerEarningsController.requestPayout` early-return on `saving` | `cleaner_earnings_controller_test.dart` → `request payout keeps one idempotency key and guards duplicates` | PASS |
| Review save | `CustomerReviewController.save` early-return on `saving` | `review_controller_test.dart` → `save ignores duplicate presses while in flight` | PASS |
| Dispute create | `BookingDisputeController.create` early-return on `saving` | `booking_dispute_controller_test.dart` → `create ignores duplicate presses while in flight` | PASS |
| Password change | `AccountSecurityController.changePassword` early-return on `isSubmitting` + UI disable | `account_security_controller_test.dart` → `changePassword ignores duplicate presses while in flight` | PASS |

Idempotency-Key ops (booking/message/payment/payout) keep one logical key for in-flight duplicates; chat also covers failed-send key retention. No blanket auto POST retries.

## Destructive Confirmation Audit

| Action | Confirmation | Notes |
|--------|--------------|-------|
| Cancel booking | Reason dialog (`promptBookingReason`) | Existing |
| Deactivate / suspend user | Reason dialog | Existing |
| Reject payout | Reason dialog | Existing |
| Cancel payout | `showAppConfirmationDialog` | Added TASK 021C |
| Hide review | Reason dialog | Existing |
| Close dispute | `showAppConfirmationDialog` | Added TASK 021C |
| Revoke all sessions | `showAppConfirmationDialog` — “Sign out all devices?” | TASK 021C + widget test |
| Revoke another session | `showAppConfirmationDialog` — “Revoke session?” | TASK 021C + widget test |
| Revoke current session | `showAppConfirmationDialog` — “End this session?” (ends session; must sign in again) | TASK 021C2 + widget test |
| Admin paid cancel | Does not claim refund success before backend | Preserved |

## Chat UX Audit

| Point | Evidence |
|-------|----------|
| Initial loading | `AppLoadingState` on first load |
| Empty messages | `AppEmptyState` "No messages yet." |
| Chronological + own/other | Existing chat screen/tests |
| Terminal read-only | Existing notice + composer hidden |
| Send disabled empty/submitting | Production + chat widget/controller tests |
| Plain text | Existing |
| Poll no full reset / older preserve / poll error silent / dispose stops poll | Existing controller tests |
| Accessibility | Send semantics label |
| No WebSocket | Confirmed |

## Customer Acceptance Journey (1–20)

| Stage | Test / assertion |
|------|------------------|
| 1 Unauthenticated | `customer unauthenticated paths…` → LoginScreen |
| 2 Signup | Create account path |
| 3 Verification-pending | Verify email route |
| 4 Dev verification harness | token query → Verification token field |
| 5 Login | `customer login from unauthenticated reaches home` |
| 6 Customer home | Customer Home chrome |
| 7 Profile/address | Customer profile + Addresses routes |
| 8 Discovery | Find Cleaners + rating 4.8 |
| 9 Cleaner detail | Ada Cleaner detail |
| 10 Service/availability | Book slot → Confirm booking |
| 11 Booking review | Confirm booking screen |
| 12 Booking detail | Booking details |
| 13 Payment experience | Payment route |
| 14 Paid state | Paid status visible |
| 15 Chat | Hello message |
| 16 Notifications | Notifications |
| 17 Review action | Review route |
| 18 Dispute eligible | Dispute route |
| 19 Security | Account security |
| 20 Logout | LoginScreen after Log out |

## Cleaner Acceptance Journey (1–18)

| Stage | Test / assertion |
|------|------------------|
| 1 Login | `cleaner login from unauthenticated reaches cleaner home` |
| 2 Home | Cleaner Home |
| 3 Onboarding/approval | Onboarding route + approved seed |
| 4 Services | Services route |
| 5 Availability | Availability route |
| 6 Booking list | Booking Requests / Jobs |
| 7 Booking detail | Job details |
| 8 Accept | Accept button (pending seed) |
| 9 Chat | Chat route |
| 10 Start job | Start Job (confirmed seed) |
| 11 Complete job | Complete Job (in_progress seed) |
| 12 Earnings | Earnings & Payouts |
| 13 Payout request | Request payout + Development Sandbox |
| 14 Payout history | Payout history |
| 15 Reviews | My Reviews |
| 16 Notifications | Notifications |
| 17 Security | Account security |
| 18 Logout | LoginScreen |

## Admin Acceptance Journey (1–16)

| Stage | Test / assertion |
|------|------------------|
| 1 Login | `admin login from unauthenticated reaches admin home` |
| 2 Dashboard | Admin Home sections |
| 3 Approvals | Cleaner approvals |
| 4 Users | Users |
| 5 Bookings | Bookings |
| 6 Payments | Payments |
| 7 Refund/detail | Payment detail + Refund |
| 8 Disputes | Disputes |
| 9 Review moderation | Review Moderation |
| 10 Payout queue | Payouts |
| 11 Finance | Finance |
| 12 Reconciliation | Reconciliation |
| 13 Audit log | Audit Log |
| 14 Notifications | Notifications |
| 15 Security | Account security |
| 16 Logout | LoginScreen |

## Failure Acceptance Coverage

| Failure path | Test file / name | User-visible assertion | Result |
|--------------|------------------|------------------------|--------|
| Network load → Try Again | `failure_and_routing_acceptance_test.dart` → `AppErrorState presents safe message and Try Again` (+ discovery network message) | Try Again increments | PASS |
| Unauthenticated protected → login | `unauthenticated protected route redirects to login` | LoginScreen | PASS |
| email_not_verified | `email_not_verified login error shows verification guidance` | Verify your email CTA | PASS |
| account unavailable | `account_unavailable login shows safe message without home` | Safe message; no home | PASS |
| Booking conflict | `booking conflict error is user-visible on confirmation` | Safe conflict message | PASS |
| Payment failure | `payment failure status is visible on payment screen` | Failed status | PASS |
| Insufficient payout balance | `insufficient payout balance error is visible` | insufficient/balance text | PASS |
| Dispute invalid state | `dispute_not_allowed error is visible on dispute screen` | Safe dispute message | PASS |
| Current session revoke → login | `current session revoke redirects to login via expireSession` | LoginScreen | PASS |

## Router Role Matrix / Deep Links

Covered by `app_router_test.dart` + acceptance foreign-role / unauthenticated / session tests: public auth allowed; protected→login; foreign role→own home; shared notifications/security; deep links for customer booking/chat, cleaner booking, admin payment/payout/dispute, account security.

## Responsive Matrix

| Screen | 360×640 | ~2.0 text | Test |
|--------|---------|-----------|------|
| Login | Yes | Yes | `responsive_accessibility_test.dart` |
| Signup | Yes | Yes | same |
| Customer Home | Yes | Yes | same |
| Cleaner Home | Yes | Yes | same |
| Admin Home | Yes | Yes | same |
| Booking Detail | Yes | Yes | same |
| Chat | Yes | Yes | same |
| Earnings | Yes | Yes | same |
| Admin Finance | Yes | Yes | same |
| Account Security | Yes | Yes | same |
| Payment | N/A (text-scale required) | Yes | same |
| Dispute Detail | N/A (text-scale required) | Yes | same |

No global FlutterError suppression; text scaling not clamped.

## State Cleanup

Production keeps a **single root `ProviderScope`** for the app lifetime (`lib/main.dart`). Logout does **not** recreate the container. Isolation is enforced by watching authenticated user identity in user-scoped controllers (`watchAuthIdentityKey` / `watchHasAuthSession` in `auth_identity.dart`): when auth becomes unauthenticated or the user id changes, controller `build()` resets to empty and reloads for the new session.

Regression tests keep that **same** `ProviderScope` across USER A → logout → USER B login (`pumpPersistentAcceptanceApp`).

| State category | Production isolation mechanism | Production-lifecycle test | Result |
|----------------|--------------------------------|---------------------------|--------|
| Bookings | Auth-user-id watch in `CustomerBookingController.build` clears/reloads on identity change | `logout_state_cleanup_test.dart` — same scope; prior `Ada Cleaner` gone | PASS |
| Chat | Auth-user-id watch in `BookingChatController.build` resets to idle | same file — prior chat marker gone | PASS |
| Notifications | Auth-user-id watch in `NotificationController.build` clears items | same file — prior notification marker gone | PASS |
| Profile | Auth-user-id watch in `CustomerProfileController.build` clears/reloads | same file — prior profile marker gone | PASS |
| Earnings | Auth-user-id watch in `CleanerEarningsController.build` clears/reloads | same file — prior balance gone | PASS |
| Admin data | Auth-user-id watch in `AdminCleanerReviewController.build` clears/reloads | same file — prior admin queue marker gone | PASS |

## Manual Code-Driven Smoke Review

Code/test review (no emulator taps) of customer/cleaner/admin homes, login/signup/security, booking, chat, payment, earnings, admin finance for loading/empty/error/back/status/money-date/a11y/small-screen. TASK 021C closed remaining empty/confirmation/chat gaps. TASK 021C2 closed current-session revoke confirmation. TASK 021C3 proved logout isolation on the real single-scope auth lifecycle.

## Final Verification

| Check | Result |
|-------|--------|
| Backend `dart analyze` | **No issues found!** |
| Backend `dart test` | **502 passed** |
| Dart Frog routes | Present (no backend runtime change) |
| Flutter `flutter analyze` | **No issues found!** |
| Flutter `flutter test` | **433 passed** (≥ 433) |
| Acceptance/shared + related focus | Included in full suite |
| `flutter build apk --debug` | **Success** |
| Live GET | Not required (no backend runtime change) |
| Commit | **None** — uncommitted |

## TASK 021C Note

TASK 021C was a narrow compliance correction: duplicate-submit tests, nine failure paths, complete journey stages, responsive matrix, empty/confirmation/chat UX, logout cleanup evidence, and report matrices. The authoritative original TASK 021 prompt remains embedded below unchanged.

## TASK 021C2 Note

TASK 021C2 added six-category logout isolation evidence and explicit current-session revoke confirmation. Exact Cursor Prompt below is unchanged.

## TASK 021C3 Note

TASK 021C3 verified production keeps one root `ProviderScope` across logout/login, bound the six user-scoped controllers to authenticated user identity, and rewrote logout isolation tests to keep the same provider container across USER A → logout → USER B (no test-only scope reset). Exact Cursor Prompt below is unchanged.

## Exact Cursor Prompt

~~~~text
# TASK 021 — Release-Candidate UX, Accessibility, Resilience, Cross-Role Acceptance Journeys, and Application Hardening

Repository:

D:\freelance\erfankhan_cse489\final

TASK 020 must be committed before starting this task.

======================================================================
OBJECTIVE
======================================================================

The marketplace now contains the major functional implementation:

AUTH / ACCOUNT SECURITY
- signup;
- email verification;
- login/logout;
- refresh rotation/replay protection;
- password recovery;
- password change;
- session management.

CUSTOMER
- profile;
- addresses;
- cleaner discovery;
- comparison;
- cleaner details;
- booking;
- payment;
- booking lifecycle visibility;
- chat;
- notifications;
- reviews;
- disputes.

CLEANER
- onboarding;
- service configuration;
- availability;
- booking requests;
- job lifecycle;
- chat;
- reviews;
- disputes;
- earnings;
- payout requests.

ADMIN
- cleaner approval;
- payment/refund operations;
- reviews moderation;
- disputes;
- users;
- bookings;
- audit log;
- payouts;
- finance/reconciliation.

TASK 021 is NOT primarily a new business-feature task.

TASK 021 must turn the current implementation into a cohesive,
release-candidate-quality portfolio application.

Implement and verify:

1. CONSISTENT APPLICATION UX
2. SHARED DESIGN SYSTEM / COMPONENTS
3. LOADING / EMPTY / ERROR / SUCCESS STATES
4. SAFE FORM AND SUBMISSION BEHAVIOR
5. RESPONSIVE LAYOUTS
6. ACCESSIBILITY
7. SAFE MONEY / DATE / STATUS PRESENTATION
8. NETWORK / API FAILURE RESILIENCE
9. ROLE NAVIGATION CONSISTENCY
10. CROSS-FEATURE ACCEPTANCE JOURNEYS
11. ROUTER / AUTH / SESSION REGRESSION
12. BACKEND RESPONSE-CONTRACT AUDIT
13. USER-FACING DEVELOPMENT / SANDBOX HONESTY
14. FINAL MANUAL ACCEPTANCE CHECKLIST

This task must make the application feel like ONE product instead of a
collection of independently implemented feature screens.

======================================================================
DO NOT IMPLEMENT
======================================================================

Do NOT add:

- AI;
- MFA;
- OAuth/social login;
- production email provider;
- real payment provider;
- real payout provider;
- bank details;
- tax;
- KYC;
- push notifications;
- WebSockets;
- analytics SDK;
- crash-reporting SDK;
- remote feature flags;
- a new backend language;
- a new Flutter state manager;
- a new Flutter router;
- a new networking stack;
- a new UI framework;
- large animation libraries;
- a design-system package;
- an icon package;
- a date-formatting dependency merely for presentation;
- currency conversion;
- production deployment configuration.

Deployment/production-infrastructure work is reserved for the final task.

No AI features.

======================================================================
EXPECTED BASELINE
======================================================================

After TASK 020 checkpoint:

Backend:

dart analyze:
clean

dart test:
502 passed

Flutter:

flutter analyze:
clean

flutter test:
370 passed

Android debug APK:
successful

Verify these exact baselines before changing anything.

Dart Frog CLI:

dart pub global run dart_frog_cli:dart_frog list

Do not rely on plain:

dart_frog list

because it may not be directly on PATH.

======================================================================
DEPENDENCY POLICY
======================================================================

BACKEND:

No new direct dependency expected.

FLUTTER:

No new third-party dependency expected.

One exception is permitted ONLY if integration_test is not already configured:

dev_dependencies:

  integration_test:
    sdk: flutter

This is a Flutter SDK testing dependency, not a third-party runtime dependency.

Do NOT add any other package without stopping first.

Do NOT run:

dart pub upgrade
flutter pub upgrade

======================================================================
UX PRINCIPLES
======================================================================

The final application should consistently communicate:

WHAT AM I LOOKING AT?
WHAT CAN I DO NEXT?
IS SOMETHING LOADING?
DID MY ACTION SUCCEED?
CAN I TRY AGAIN?
IS THIS DEVELOPMENT / SANDBOX ONLY?
WHAT DOES THIS STATUS MEAN?

Avoid:

- raw backend vocabulary where a clearer user-facing term exists;
- blank screens;
- indefinite spinners with no context;
- duplicate submit actions;
- unexplained disabled buttons;
- raw exception text;
- technical ObjectId-heavy presentation where a user-friendly label exists;
- inconsistent padding/button hierarchy;
- inconsistent status naming;
- fake success states;
- fake ratings;
- fake payment/payout claims.

======================================================================
SHARED FLUTTER DESIGN FOUNDATION
======================================================================

Audit:

project/lib/src/app/theme/

and existing shared UI primitives.

Create or extend a SMALL internal design foundation.

Prefer reusable components under a clear location such as:

project/lib/src/shared/widgets/
project/lib/src/shared/presentation/

or the existing project convention.

Do not create a huge abstract design-system framework.

Useful shared components may include:

AppPageScaffold
AppSection
AppAsyncContent
AppLoadingState
AppEmptyState
AppErrorState
AppSuccessBanner
AppStatusChip
AppPrimaryButton
AppDangerButton
AppLoadingButton
AppConfirmationDialog
AppFormPage
AppPaginationFooter
AppInfoCard
AppKeyValueRow

Use only components that reduce real duplication.

Do not mechanically wrap every Text or Card.

======================================================================
SPACING / PAGE WIDTH
======================================================================

Establish consistent layout conventions.

Recommended:

small spacing:
8

normal:
16

section:
24

large:
32

Do not necessarily expose every value as a global token if unnecessary.

For phone screens:

normal horizontal padding around 16.

For wide screens/tablets:

center primary content and constrain readable forms/details.

Reasonable max widths:

forms:
~600

detail pages:
~800

admin lists/dashboard:
may use wider responsive area.

Do not allow forms to stretch edge-to-edge across a wide desktop-sized test
surface.

======================================================================
MATERIAL 3 CONSISTENCY
======================================================================

Keep:

Material 3.

Audit:

buttons
cards
dialogs
chips
text fields
navigation
app bars
snackbars

for consistent visual hierarchy.

Do not replace Flutter Material controls with custom canvas UI.

Do not introduce a visual style that harms readability.

======================================================================
THEME
======================================================================

Audit current theme.

Provide consistent:

ColorScheme
text hierarchy
input decoration
button styling
card treatment
dialog treatment
error styling

using Material theme facilities.

Do not hardcode dozens of colors in individual feature screens.

Do not need custom fonts.

Respect platform text scaling.

======================================================================
ROLE HOME EXPERIENCE
======================================================================

Audit:

CustomerHomeScreen
CleanerHomeScreen
AdminHomeScreen

or current equivalents.

Each role home should clearly provide:

- role identity;
- primary next actions;
- current operational sections;
- notification access;
- security/profile/settings access;
- important financial/workflow links.

Do not hide major features in obscure nested navigation.

CUSTOMER HOME should make primary paths easy to find:

Find a Cleaner
My Bookings
Notifications
Profile / Addresses
Security

CLEANER HOME:

Dashboard / Booking Requests
Services
Availability
My Reviews
Earnings & Payouts
Notifications
Profile
Security

ADMIN HOME:

Approvals
Users
Bookings
Payments
Payouts
Disputes
Review Moderation
Finance
Audit Log
Notifications
Security

Use grouping/sections where the list is long.

Do not build a completely new routing architecture.

Preserve existing deep links/routes.

======================================================================
APP BAR / BACK NAVIGATION CONSISTENCY
======================================================================

Audit feature screens.

Ensure:

- meaningful titles;
- back navigation works consistently;
- no duplicate nested AppBars;
- destructive actions are not placed ambiguously;
- notifications/security entry points are predictable.

Do not break go_router guards.

======================================================================
STATUS PRESENTATION
======================================================================

Create a consistent user-facing status presentation mechanism.

Examples:

BOOKING

pending:
Pending

confirmed:
Confirmed

in_progress:
In Progress

completed:
Completed

declined:
Declined

cancelled:
Cancelled

PAYMENT

pending:
Pending

authorized:
Authorized

paid:
Paid

failed:
Failed

cancelled:
Cancelled

partially_refunded:
Partially Refunded

refunded:
Refunded

PAYOUT

requested:
Requested

processing:
Processing

paid:
Paid

failed:
Failed

cancelled:
Cancelled

rejected:
Rejected

DISPUTE

open:
Open

under_review:
Under Review

resolved:
Resolved

closed:
Closed

REVIEWS

published:
Published

hidden:
Hidden

Do not scatter status-label logic through dozens of widgets.

Unknown status:

display safe:

Unknown

or:

Unsupported Status

depending context.

Never crash because backend introduces an unknown enum.

======================================================================
MONEY PRESENTATION
======================================================================

The backend intentionally stores:

minor units

without globally assuming every currency has two decimal places.

TASK 021 must preserve that correctness.

Create a consistent technical presentation helper.

Examples:

BDT 250000 minor units

USD 1200 minor units

unless currency metadata already exists in the project.

Do NOT globally divide by 100.

Do NOT pretend to perform currency conversion.

Where useful, label:

Amount
Quoted Total
Platform Fee
Available Balance

clearly.

======================================================================
DATE / TIME PRESENTATION
======================================================================

Audit raw DateTime.toString() usage in user-facing screens.

Create a small safe local presentation helper using Dart SDK only unless an
existing formatter already exists.

Requirements:

- parse server UTC correctly;
- convert to local device time for normal human-facing schedule display;
- clearly distinguish UTC only where technically necessary;
- consistent format;
- do not display microseconds;
- handle invalid/missing values safely.

Example acceptable format:

27 Aug 2026, 6:30 PM

If implementing month names manually, keep it small/tested.

Do NOT add intl merely for this task.

======================================================================
LOADING STATES
======================================================================

Audit every major asynchronous page.

Do not leave:

blank body
tiny spinner with no context
stale action button while submitting

for important operations.

Use consistent loading UX.

Initial full-page load:

centered progress + optional meaningful text.

Button submission:

disable button
show progress in button or adjacent state
prevent duplicate taps.

Pagination:

keep existing content visible
show Load More progress separately.

Background chat polling:

do NOT replace whole screen with spinner.

Notification unread refresh:

do not block navigation.

======================================================================
EMPTY STATES
======================================================================

Create useful empty states.

Examples:

CUSTOMER BOOKINGS

"No bookings yet."
"Find a cleaner to create your first booking."

CLEANER BOOKING REQUESTS

"No booking requests right now."

CHAT

"No messages yet."
"Send a message about this booking."

NOTIFICATIONS

"No notifications yet."

REVIEWS

"No reviews yet."

DISPUTES

"No dispute has been opened for this booking."

EARNINGS

"No earnings have been recorded yet."

PAYOUTS

"No payout requests yet."

ADMIN QUEUES

"No pending cleaner approvals."
"No open disputes."
"No requested payouts."

Empty states should not look like errors.

======================================================================
ERROR STATES
======================================================================

Audit major screens for:

initial load errors
pagination errors
mutation errors
auth/session errors.

Initial load:

show clear error + Try Again when retry is safe.

Pagination failure:

keep existing items
show safe inline error
allow retry.

Mutation failure:

do not discard loaded data unnecessarily.

Never show:

DioException.toString()
stack trace
Mongo wording
provider raw errors
HTML
secret-looking data.

Use existing safe error mapper.

Extend only where needed.

======================================================================
NETWORK FAILURE RESILIENCE
======================================================================

Do NOT implement blind automatic retries for unsafe mutations.

Especially do not automatically replay arbitrary:

POST
PUT
DELETE

unless existing idempotency semantics explicitly make retry safe and the
existing API/controller already handles that logical operation.

For normal GET failures:

user-triggered retry is appropriate.

For chat send/payment/payout/booking creation:

retain existing idempotency keys and logical-request semantics.

Do not generate a new idempotency key merely because auth refresh occurred.

======================================================================
AUTHENTICATION FAILURE UX
======================================================================

Verify consistently:

expired/revoked session
→ secure storage cleared when required
→ login

suspended/deactivated account
→ safe unavailable message
→ no protected app access

current session manually revoked
→ login

password changed/reset
→ login

Do not leave protected screen visible after auth becomes invalid.

======================================================================
FORM HARDENING
======================================================================

Audit major forms:

signup
login
profile
address
cleaner onboarding
service offering
availability
booking
payment sandbox action
review
dispute
admin moderation reason
admin cancellation reason
refund
payout
password recovery
password change.

Ensure where applicable:

- trim inputs consistent with backend domain;
- required fields are clear;
- backend remains authoritative;
- submitting disables duplicate action;
- keyboard submit does not bypass validation;
- error clears/updates appropriately after correction;
- destructive confirmations are explicit.

Do not create client validation that contradicts backend.

======================================================================
PASSWORD FORMS
======================================================================

For:

signup
reset
change

ensure:

- obscured by default;
- show/hide control;
- confirm password where appropriate;
- PasswordPolicy help is readable;
- no password printed into errors/logs;
- focus traversal sensible.

Do not add password-strength package.

======================================================================
DESTRUCTIVE ACTION UX
======================================================================

Require confirmation where appropriate:

cancel booking
deactivate user
suspend user
reject payout
cancel payout
hide review
close dispute
revoke all sessions
revoke current session

Avoid redundant confirmation for harmless read actions.

Dialog language must state what will happen.

Example:

"Cancel this booking?"

For paid booking admin cancellation:

mention that backend may require refund before cancellation.

Do NOT claim refund succeeded before backend confirms.

======================================================================
SANDBOX / DEVELOPMENT HONESTY
======================================================================

Audit all development-only controls.

PAYMENTS:

simulation controls must be clearly labeled:

Development Sandbox

PAYOUTS:

simulation controls must be clearly labeled:

Development Sandbox

ACCOUNT ACTION DELIVERY:

development verification/reset helpers must be clearly labeled:

Development

Do not display sandbox controls when backend does not explicitly advertise
simulation/development availability.

Do not style development action as a normal production flow.

======================================================================
ACCESSIBILITY
======================================================================

Perform a deliberate Flutter accessibility audit.

Requirements where applicable:

- icon-only buttons have Tooltip and/or Semantics label;
- tappable controls meet reasonable Material touch target;
- form labels are visible/meaningful;
- status is not communicated by color alone;
- destructive action includes text/icon semantics;
- loading indicators have context where necessary;
- major images/icons are not given misleading semantic labels;
- dialog focus/actions are sensible;
- navigation remains usable with keyboard where Flutter supports it;
- no critical information hidden exclusively in hover.

Do not hardcode tiny text.

======================================================================
TEXT SCALE
======================================================================

Test important screens with:

textScaleFactor approximately 2.0

or current MediaQuery equivalent.

Critical screens must not overflow:

Login
Signup
Customer Home
Cleaner Home
Admin Home
Booking Detail
Chat
Payment
Dispute Detail
Earnings
Admin Finance
Account Security.

Fix layout issues using:

Wrap
Flexible
Expanded carefully
scrollable layout
responsive composition.

Do NOT globally disable or clamp accessibility text scaling to hide overflows.

======================================================================
SMALL-SCREEN RESPONSIVENESS
======================================================================

Test representative size around:

360 x 640

No major:

RenderFlex overflow
unreachable action
horizontal clipping

on essential screens.

Long admin data should use:

wrapping
vertical cards
horizontal scrolling only where tabular data genuinely needs it.

======================================================================
WIDE-SCREEN RESPONSIVENESS
======================================================================

Test representative width around:

900–1200.

Forms/details should remain readable.

Do not stretch single-column forms across full width.

Admin/dashboard content may intelligently use:

Wrap
Grid
multi-column cards

where simple and useful.

Do not create desktop-only functionality.

======================================================================
LIST / PAGINATION CONSISTENCY
======================================================================

Audit all paginated screens.

Ensure consistent:

Load More
loading
no more results
retry

behavior.

Do not allow multiple overlapping loadMore calls.

Do not clear existing content during loadMore.

======================================================================
CHAT UX HARDENING
======================================================================

Audit BookingChatScreen.

Ensure:

- initial loading;
- empty message state;
- chronological display;
- readable own/other distinction;
- terminal read-only notice;
- send disabled while empty/submitting;
- message remains plain text;
- polling does not visibly reset list;
- older-message loading preserves current messages;
- background poll failure does not spam SnackBars;
- dispose stops polling;
- accessibility labels sensible.

Do not add WebSocket.

======================================================================
NOTIFICATION UX HARDENING
======================================================================

Ensure:

- unread count remains non-negative;
- mark read updates UI;
- mark all updates UI;
- unknown notification type displays safely;
- resource navigation uses explicit mapping only;
- stale/missing resource produces safe error;
- notifications cannot inject arbitrary route.

======================================================================
DISCOVERY / BOOKING UX HARDENING
======================================================================

Audit:

discovery
filters
comparison
cleaner details
availability selection
booking review/creation.

Ensure:

- filter state understandable;
- no-results state;
- no fake ratings;
- published review count only;
- selected slot/service clearly summarized before booking;
- booking idempotent submission has duplicate-submit protection;
- quoted amount clearly labeled;
- address selection readable;
- booking confirmation clearly links to booking detail/status.

======================================================================
PAYMENT UX HARDENING
======================================================================

Audit customer payment screen.

Ensure:

- current payment state visible;
- no card/CVV form;
- sandbox controls only when advertised;
- duplicate payment-start action disabled while pending;
- cancellation state safe;
- refunded state clear;
- payment failure can present valid retry action where backend allows;
- no claim of external money movement.

======================================================================
REVIEW / DISPUTE UX HARDENING
======================================================================

REVIEWS:

- completed-booking CTA only;
- rating clearly selected;
- comment optional;
- moderation hidden state visible to review owner where appropriate;
- public cleaner view remains "Verified customer";
- hidden reviews excluded discovery.

DISPUTES:

- eligible status CTA only;
- status/history readable;
- resolution distinguished from participant description;
- resolved close action explicit;
- admin action buttons depend on valid state.

======================================================================
CLEANER WORKFLOW UX HARDENING
======================================================================

Audit:

onboarding
services
availability
booking requests
job detail
earnings
payouts.

Ensure user can clearly identify:

setup needed
approval state
service configuration
availability
next requested job action
active job action
historical job
financial summary.

Do not let rejected/unapproved cleaner UI imply they can receive new bookings.

Backend remains authoritative.

======================================================================
ADMIN UX HARDENING
======================================================================

Admin screens should consistently use:

title
filter section
summary/list cards
empty state
pagination
detail
confirmation/action state.

Audit:

Approvals
Users
Bookings
Payments
Payouts
Disputes
Reviews
Finance
Reconciliation
Audit Log.

Avoid presenting raw IDs as primary identity when safe display names are available.

IDs may remain available as secondary operational references.

======================================================================
BACKEND RESPONSE CONTRACT AUDIT
======================================================================

TASK 021 is primarily Flutter/UX, but perform a backend API consistency audit.

Check TASK 011–020 routes for:

success envelope consistency
safe error envelope consistency
JSON content type
appropriate status code
no raw Mongo/provider exception
no password/token leakage
no unexpected HTML error response for known application errors.

Do not rewrite the whole backend.

If a specific inconsistency affects Flutter UX or API safety:

fix it narrowly
add regression test
document it.

Do not alter domain state machines merely for cosmetic consistency.

======================================================================
SENSITIVE RESPONSE HEADERS REGRESSION
======================================================================

Reverify auth/security sensitive endpoints retain:

Cache-Control: no-store

where required.

Do not accidentally remove TASK 020 hardening.

======================================================================
ACCEPTANCE TEST STRATEGY
======================================================================

Create automated cross-feature acceptance tests WITHOUT live Atlas mutation.

Preferred:

test-controlled provider/repository/API fakes.

Tests should exercise:

router
controllers
screens
meaningful state transitions

together.

Do not duplicate every lower-level unit test.

Create a dedicated area such as:

project/test/acceptance/

and optionally:

project/integration_test/

if Flutter SDK integration_test is used.

The acceptance harness must NEVER point at:

production backend
real Atlas
real user accounts.

======================================================================
ACCEPTANCE JOURNEY A — CUSTOMER
======================================================================

Automate a representative customer journey.

At minimum demonstrate:

1. unauthenticated start;
2. signup;
3. verification-pending;
4. development verification action in test harness;
5. login;
6. customer home;
7. profile/address prepared;
8. discovery results;
9. cleaner detail with rating summary;
10. select service/availability;
11. review booking;
12. booking confirmation/detail;
13. confirmed booking payment experience;
14. paid state;
15. chat;
16. notifications;
17. completed booking review action;
18. dispute navigation when eligible;
19. security/session screen;
20. logout.

The harness may pre-script server state transitions.

Do not weaken production architecture for testing.

======================================================================
ACCEPTANCE JOURNEY B — CLEANER
======================================================================

Automate representative cleaner journey:

1. login;
2. cleaner home;
3. onboarding/approval-state rendering;
4. service offering;
5. availability;
6. booking request list;
7. booking detail;
8. accept;
9. chat;
10. start job;
11. complete job;
12. earnings summary;
13. payout request;
14. payout history;
15. reviews;
16. notifications;
17. security;
18. logout.

If a state is administratively impossible to transition within one role,
the test harness may script the backend state between user actions.

======================================================================
ACCEPTANCE JOURNEY C — ADMIN
======================================================================

Automate representative admin journey:

1. login;
2. admin dashboard;
3. cleaner approval;
4. users;
5. bookings;
6. payments;
7. refund/detail path;
8. disputes;
9. review moderation;
10. payout queue;
11. finance;
12. reconciliation;
13. audit log;
14. notifications;
15. security;
16. logout.

No real live mutation.

======================================================================
ACCEPTANCE JOURNEY ASSERTIONS
======================================================================

Tests should verify important user-visible effects, not implementation internals.

Examples:

- expected screen appears;
- loading disappears;
- success action changes state;
- route guard behaves;
- error has safe text;
- duplicate tap does not duplicate logical request;
- current role cannot navigate to foreign role route;
- terminal status disables inappropriate action;
- development-only control only appears when advertised.

======================================================================
ERROR ACCEPTANCE JOURNEYS
======================================================================

Add focused acceptance coverage for important failure paths:

- network load failure → Try Again;
- unauthenticated protected route → login;
- email_not_verified → verification guidance;
- account unavailable → protected access denied;
- booking conflict → safe message;
- payment failure → safe state;
- insufficient payout balance → safe message;
- dispute invalid state → safe message;
- current session revoke → login.

Do not need one gigantic test for every failure.

======================================================================
DUPLICATE SUBMISSION TESTING
======================================================================

Explicitly verify UI/controller protections for important logical mutations:

booking create
message send
payment start
payout request
review save
dispute create
password change

Rapid repeated user taps must not create overlapping logical actions.

For operations with server idempotency keys:

same logical operation retains its intended key through network/auth retry.

Do not change server idempotency rules.

======================================================================
WIDGET OVERFLOW TESTING
======================================================================

Add targeted widget tests at small dimensions and increased text scale.

At minimum:

Login
Signup
CustomerHome
CleanerHome
AdminHome
Booking detail
Chat
Earnings
Admin finance
Account security

must pump without overflow exceptions.

Do not silence Flutter errors globally.

======================================================================
ACCESSIBILITY TESTING
======================================================================

Where practical add tests for:

Semantics labels
button accessibility
form fields
development/sandbox labels
status text.

Do not make brittle semantics snapshots for every widget.

======================================================================
ROUTER ACCEPTANCE MATRIX
======================================================================

Create/maintain explicit tests covering:

UNAUTHENTICATED

allowed:
login
signup
verify-email-pending
forgot-password
reset-password

protected:
redirect login

CUSTOMER

allowed customer routes
shared notifications/security

cleaner/admin routes:
redirect own home

CLEANER

allowed cleaner routes
shared notifications/security

customer/admin routes:
redirect own home

ADMIN

allowed admin routes
shared notifications/security

customer/cleaner operational routes:
redirect admin home

SESSION INVALIDATION

routes return login after auth becomes unauthenticated.

Do not create role authorization only in UI; backend protection remains required.

======================================================================
BACK BUTTON / DEEP LINK TESTS
======================================================================

Test representative deep routes:

customer booking detail
customer chat
cleaner booking detail
admin payment detail
admin payout detail
admin dispute detail
account security

Ensure direct route entry with correct auth resolves correctly.

Back navigation must not create obvious loops.

======================================================================
PERFORMANCE / STATE HYGIENE AUDIT
======================================================================

Without adding profiling packages, inspect obvious state-management issues:

- accidental repeated API loads on every build;
- timers surviving dispose;
- duplicate polling;
- providers never disposed when screen-specific;
- repeated loadMore overlap;
- large list rebuild caused by unnecessary top-level watch;
- controllers retaining stale role data after logout.

Fix clearly demonstrated issues.

Do not prematurely micro-optimize.

======================================================================
LOGOUT STATE CLEANUP
======================================================================

Verify logout clears/invalidates user-specific state where required.

A newly logged-in different role/user must not see stale:

bookings
chat
notifications
profile
earnings
admin data

from the previous account.

Add regression test if current provider lifecycle could leak state.

======================================================================
TEST DATA PRIVACY
======================================================================

All acceptance fixtures:

fake only.

Use obvious fake identifiers/emails.

Do not copy:

real Atlas data
real emails
real account action tokens
real webhook values
real payment/payout records

into tests or docs.

======================================================================
DOCUMENTATION — UX
======================================================================

Create:

documentation/ux/release-candidate-ux-guidelines.md

Document:

- layout conventions;
- shared states;
- buttons/destructive actions;
- status presentation;
- money presentation;
- date/time presentation;
- accessibility;
- text scaling;
- responsive behavior;
- sandbox/development labeling;
- empty/error/loading rules.

Create directory if necessary:

documentation/ux/

======================================================================
DOCUMENTATION — TESTING
======================================================================

Create:

documentation/testing/acceptance-testing.md

Document:

- acceptance-test architecture;
- why no live Atlas;
- fake/test seams;
- customer journey;
- cleaner journey;
- admin journey;
- role routing matrix;
- failure-path coverage;
- duplicate-submit coverage;
- responsive/accessibility checks;
- command to run tests.

Create directory if necessary:

documentation/testing/

======================================================================
MANUAL RELEASE-CANDIDATE CHECKLIST
======================================================================

Create:

documentation/testing/manual-release-candidate-checklist.md

It must be practical, checkbox-oriented.

Include:

ENVIRONMENT

[ ] backend configuration available
[ ] Flutter API_BASE_URL configured
[ ] no secrets in Flutter

AUTH

[ ] signup
[ ] verify
[ ] login
[ ] forgot/reset
[ ] change password
[ ] sessions
[ ] logout

CUSTOMER

[ ] profile/address
[ ] discovery
[ ] booking
[ ] payment sandbox
[ ] chat
[ ] notifications
[ ] review
[ ] dispute

CLEANER

[ ] onboarding
[ ] services
[ ] availability
[ ] booking lifecycle
[ ] chat
[ ] earnings
[ ] payout sandbox
[ ] reviews
[ ] dispute

ADMIN

[ ] approval
[ ] users
[ ] bookings
[ ] payments/refund
[ ] disputes
[ ] reviews
[ ] payouts
[ ] finance
[ ] audit

UX

[ ] empty
[ ] loading
[ ] error
[ ] small screen
[ ] large text
[ ] wide layout
[ ] destructive confirmations

SECURITY

[ ] role guards
[ ] session revoke
[ ] no raw server errors
[ ] sandbox clearly labeled

Do not include real credentials.

======================================================================
ADR-019
======================================================================

Create:

documentation/decisions/ADR-019-release-candidate-ux-and-acceptance-testing.md

Required:

# ADR-019 — Release-Candidate UX and Acceptance Testing

## Status
Accepted

## Context
## Decision
## Alternatives Considered
## Consequences
## Accessibility
## Testing
## Deferred Decisions

Decision must cover:

- shared internal UI primitives;
- Material 3 consistency;
- responsive constrained layouts;
- explicit loading/empty/error states;
- status presentation centralization;
- minor-unit money honesty;
- local DateTime presentation;
- safe manual retry rather than blind mutation retry;
- accessibility/text scaling;
- role-aware routing preservation;
- cross-role acceptance harness;
- no live Atlas mutation in acceptance tests;
- development/sandbox labeling.

Alternatives:

### Add a third-party design-system library
Rejected.

### Add automatic retry to every API request
Rejected because unsafe mutations may duplicate side effects.

### Disable large text scaling to prevent overflow
Rejected because it harms accessibility.

### Hard-code currency /100 formatting
Rejected because currency minor-unit metadata is not modeled.

### Test acceptance flows against live Atlas
Rejected due state pollution/security/reproducibility.

### Replace existing router/state/network stacks
Rejected because current architecture is established and tested.

Deferred:

visual snapshot/golden infrastructure at scale
real-device farm
full localization/i18n
RTL
production analytics
crash reporting
push notifications
WebSocket chat
production payment/payout integrations.

======================================================================
DOCUMENTATION INDEX UPDATES
======================================================================

Update:

documentation/README.md
documentation/decisions/README.md

If UX/testing directories have their own README indexes, create/update:

documentation/ux/README.md
documentation/testing/README.md

Update as necessary:

project/README.md
README.md

Document acceptance-test commands clearly.

Do not claim:

production deployment
real email
real payments
real payouts
MFA
AI

exist.

======================================================================
TASK EXECUTION
======================================================================

STEP 1 — CLEAN CHECKPOINT

From root:

git rev-parse --show-toplevel
git branch --show-current
git status
git status --short
git log -10 --oneline

Expected:

root:
D:\freelance\erfankhan_cse489\final

branch:
main

working tree:
clean

latest checkpoint:
TASK 020

Verify:

documentation/cursor/020_account_recovery_verification_and_session_security.md

Status:
SUCCESS

Verify:

backend/.env ignored.

If not clean:

STOP.

======================================================================
STEP 2 — BACKEND BASELINE

From backend:

dart pub get
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

Expected:

502 passed
0 failed
analyze clean.

If baseline fails:

STOP.

======================================================================
STEP 3 — FLUTTER BASELINE

From project:

flutter pub get
flutter analyze
flutter test
flutter build apk --debug

Expected:

370 passed
analyze clean
APK success.

If baseline fails:

STOP.

======================================================================
STEP 4 — DEPENDENCY AUDIT

Confirm no new third-party dependencies.

If integration_test Flutter SDK dependency is needed and missing:

it may be added as:

integration_test:
  sdk: flutter

dev dependency only.

No other package.

======================================================================
STEP 5 — UX INVENTORY

Audit all major Flutter screens.

Create a concise internal checklist before editing identifying:

- inconsistent page structure;
- loading gaps;
- empty-state gaps;
- error-state gaps;
- duplicate-submit risks;
- raw status formatting;
- raw DateTime formatting;
- raw money formatting;
- responsive issues;
- accessibility issues.

Do not create a throwaway committed checklist file unless useful.

======================================================================
STEP 6 — SHARED UI FOUNDATION

Implement the smallest useful shared component set.

Migrate repeated patterns deliberately.

Do not perform unrelated massive file rewrites.

======================================================================
STEP 7 — FORMATTERS / STATUS PRESENTATION

Implement:

safe status labels
money minor-unit presentation
local date/time presentation

with unit/widget tests.

======================================================================
STEP 8 — ROLE HOME / NAVIGATION UX

Improve customer/cleaner/admin home organization and shared navigation
consistency.

Preserve route paths.

Add/repair route tests.

======================================================================
STEP 9 — LOADING / EMPTY / ERROR / FORM HARDENING

Systematically harden major customer, cleaner, admin, and shared screens.

Focus first on user-visible workflows rather than obscure internal pages.

======================================================================
STEP 10 — ACCESSIBILITY / RESPONSIVENESS

Fix:

small-screen
large-text
wide-layout
Semantics/Tooltip

issues.

Add targeted tests.

======================================================================
STEP 11 — FEATURE UX AUDIT

Harden:

auth
customer discovery/booking/payment/chat/review/dispute
cleaner workflow/earnings/payout
admin operations
notifications/security.

Do not change business rules.

======================================================================
STEP 12 — BACKEND CONTRACT AUDIT

Audit known routes for safe/consistent responses.

Make only narrowly justified backend fixes.

Add tests for any changed backend behavior.

======================================================================
STEP 13 — ACCEPTANCE TEST HARNESS

Create test-only acceptance architecture.

It must not use live Atlas.

Use provider/API/repository test seams compatible with current architecture.

======================================================================
STEP 14 — CUSTOMER ACCEPTANCE JOURNEY

Implement and pass representative customer journey.

======================================================================
STEP 15 — CLEANER ACCEPTANCE JOURNEY

Implement and pass representative cleaner journey.

======================================================================
STEP 16 — ADMIN ACCEPTANCE JOURNEY

Implement and pass representative admin journey.

======================================================================
STEP 17 — FAILURE / ROUTING ACCEPTANCE

Implement:

important error flows
role matrix
session invalidation
duplicate-submit
deep-link/back-navigation

coverage.

======================================================================
STEP 18 — RESPONSIVE / ACCESSIBILITY TESTS

Implement small-screen / text-scale / semantics tests.

No hidden overflow errors.

======================================================================
STEP 19 — FLUTTER FULL VERIFICATION

Run:

dart format lib test integration_test

if integration_test exists.

Then:

flutter analyze
flutter test

If integration_test exists:

run the appropriate repository-supported Flutter integration-test command.

Do not require real backend/Atlas.

All green.

Record exact:

unit/widget count
integration/acceptance count if reported separately.

======================================================================
STEP 20 — BACKEND FULL VERIFICATION

From backend:

dart format .
dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

All green.

Final backend tests:

>= 502.

======================================================================
STEP 21 — ANDROID DEBUG BUILD

From project:

flutter build apk --debug

Must succeed.

Do not alter:

application ID
release signing
production network security

in TASK 021.

======================================================================
STEP 22 — SAFE LIVE BACKEND CHECK

Only if backend runtime code changed, verify:

GET /
GET /api/v1/health
GET /api/v1/ready
GET /api/v1/services

Expected 200.

If backend runtime code did not change:

existing TASK 020 safe live verification may stand,
but report that no repeat was necessary.

Never call protected mutation routes against live Atlas.

======================================================================
STEP 23 — MANUAL UX SMOKE REVIEW

Perform a reasoned/manual code-driven smoke review of:

customer home
cleaner home
admin home
login/signup/security
booking
chat
payment
earnings
admin finance

for:

loading
empty
error
back
status
money/date
accessibility
small-screen behavior.

Do not fabricate emulator taps if they were not actually performed.

If actual emulator smoke test is performed, document exactly what was tested.

======================================================================
STEP 24 — DOCUMENTATION

Create:

documentation/ux/release-candidate-ux-guidelines.md
documentation/ux/README.md

documentation/testing/acceptance-testing.md
documentation/testing/manual-release-candidate-checklist.md
documentation/testing/README.md

documentation/decisions/ADR-019-release-candidate-ux-and-acceptance-testing.md

Update indexes/readmes.

======================================================================
STEP 25 — FINAL SECURITY / PRODUCT-HONESTY REVIEW

Confirm:

- no fake production email claim;
- no fake payment claim;
- no fake payout claim;
- development controls clearly labeled;
- no client secret;
- no raw server exceptions;
- no arbitrary notification route;
- no role-guard regression;
- no action token stored in Flutter;
- no automatic unsafe mutation replay;
- no live Atlas acceptance data.

======================================================================
STEP 26 — FINAL FLUTTER VERIFICATION

Run:

flutter analyze
flutter test

Run acceptance/integration command if applicable.

Run:

flutter build apk --debug

All green.

Record exact final counts.

======================================================================
STEP 27 — FINAL BACKEND VERIFICATION

Run:

dart analyze
dart test
dart pub global run dart_frog_cli:dart_frog list

All green.

Record exact final backend count.

======================================================================
STEP 28 — FINAL GIT REVIEW

From root:

git status --short
git check-ignore -v backend/.env
git diff --check

Inspect:

git diff -- backend/
git diff -- project/
git diff -- documentation/
git diff -- README.md

Confirm no:

backend/.env
MONGODB_URI
ACCESS_TOKEN_SECRET
SANDBOX_PAYMENT_WEBHOOK_SECRET
SANDBOX_PAYOUT_WEBHOOK_SECRET
real account-action token
password
JWT
refresh token
real user data
real payment data
real payout data
APK
build directory
SDK artifact
project/devtools_options.yaml
temporary prompt file
test screenshot artifact unless intentionally documented
unrelated generated file

is tracked.

Do NOT stage.

======================================================================
STEP 29 — TASK REPORT

Create:

documentation/cursor/021_release_candidate_ux_accessibility_and_acceptance.md

Use existing task-report style.

The report MUST contain the COMPLETE EXACT TASK 021 prompt under:

## Exact Cursor Prompt

Document:

- clean TASK 020 checkpoint;
- backend baseline;
- Flutter baseline;
- dependencies;
- UX inventory;
- shared UI primitives;
- theme/layout decisions;
- status formatting;
- money formatting;
- date formatting;
- loading states;
- empty states;
- error states;
- form hardening;
- duplicate-submit protection;
- navigation;
- accessibility;
- text scaling;
- small-screen behavior;
- wide-screen behavior;
- chat UX;
- notification UX;
- customer workflow;
- cleaner workflow;
- admin workflow;
- sandbox/development labeling;
- backend API contract audit;
- backend changes if any;
- customer acceptance journey;
- cleaner acceptance journey;
- admin acceptance journey;
- error acceptance tests;
- router/deep-link tests;
- responsive tests;
- accessibility tests;
- state cleanup;
- Flutter final test counts;
- backend final test counts;
- APK;
- safe live verification decision/result;
- manual smoke review;
- documentation;
- security/product-honesty audit;
- files;
- warnings;
- final Git status.

Do not include real credentials/data.

======================================================================
STEP 30 — DO NOT COMMIT

Do NOT:

git add
git commit
git push

Leave all TASK 021 work:

UNSTAGED
UNCOMMITTED

for ChatGPT review.

Do NOT begin TASK 022.

======================================================================
FINAL RESPONSE FORMAT
======================================================================

Respond exactly:

# TASK 021 RESULT

## Status

SUCCESS
PARTIAL
FAILED

## Pre-Task Verification

## Dependencies

## UX Inventory

## Shared UI Foundation

## Theme and Layout

## Status Presentation

## Money Presentation

## Date and Time Presentation

## Loading States

## Empty States

## Error States

## Form Hardening

## Duplicate Submission Protection

## Role Home Experience

## Navigation and Back Behavior

## Accessibility

## Text Scaling

## Small-Screen Responsiveness

## Wide-Screen Responsiveness

## Chat UX

## Notification UX

## Customer Workflow UX

## Cleaner Workflow UX

## Admin Workflow UX

## Development and Sandbox Honesty

## Backend Contract Audit

## Customer Acceptance Journey

## Cleaner Acceptance Journey

## Admin Acceptance Journey

## Failure Acceptance Tests

## Router and Deep-Link Tests

## Responsive and Accessibility Tests

## State Cleanup

## Backend Tests

## Backend Routes

## Flutter Tests

## Acceptance / Integration Tests

## Flutter Static Analysis

## Android Debug Build

## Live Backend Verification

## Live Data Safety

## Manual Smoke Review

## Files Created

## Files Modified

## Files Deleted

## Documentation

## Security and Product-Honesty Verification

## Git Status

## Issues / Warnings

## Final Statement

State whether the application UX, accessibility, resilience, role navigation,
cross-role acceptance journeys, and release-candidate hardening are complete
and ready for ChatGPT review.

Do NOT implement deployment in this task.

Do NOT implement AI.

Do NOT begin TASK 022.

Start TASK 021 now.
~~~~

## Git Status

TASK 021 changes remain **uncommitted** by design. No `git add` / `git commit` / `git push`.

## Issues / Warnings

- Gradle may emit Java restricted-method warnings during APK build; APK still succeeds.
- Manual emulator smoke taps were not performed; verification is code/test-driven.

## Final Statement

Release-candidate UX foundation, accessibility/responsive hardening, cross-role acceptance journeys (fake-only), and documentation are complete and ready for ChatGPT review. Deployment and TASK 022 were not started.
