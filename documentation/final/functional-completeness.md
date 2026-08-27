# Functional Completeness Audit

**Project:** Home Cleaning Service Marketplace  
**Versions:** Flutter `1.0.0+1`, backend `1.0.0+1`  
**Statuses used:** `IMPLEMENTED` · `PARTIAL / DEVELOPMENT-ONLY` · `DEFERRED` · `BLOCKED`

Evidence paths are representative entry points, not exhaustive file lists.

**Terminology reminder**

* **SOFTWARE RELEASE READY** can be true while providers remain development-only.
* **PRODUCTION SERVICE READY** requires real email/payment/payout (and related ops) — **not** claimed here for provider-dependent flows.

---

## FR audit

### FR-01 Sign Up — IMPLEMENTED (verification delivery PARTIAL / DEVELOPMENT-ONLY)

* Public customer/cleaner signup API and Flutter screens.
* Persists user with `email_verified=false`; does not auto-login with tokens.
* Evidence: `backend` auth signup routes/services; `project/lib/features/auth`; [account-recovery architecture](../architecture/account-recovery-verification-and-session-security.md).
* Email verification **token architecture** implemented; **outbound email** is development/test delivery only.

### FR-02 Login — IMPLEMENTED

* Login, refresh rotation/replay protection, logout, Flutter secure session storage, role routing.
* Evidence: authentication API + Flutter auth feature; [flutter-authentication.md](../architecture/flutter-authentication.md).
* Beyond baseline FR: password change, session list/revoke (TASK 020).

### FR-03 Profile/Address — IMPLEMENTED

* Customer/cleaner profiles, address CRUD with caps/default pointer, role-scoped authorization.
* Evidence: profile/address APIs and Flutter profile/address screens; ADR-011 docs.

### FR-04 Cleaner Onboarding — IMPLEMENTED

* Cleaner profile lifecycle and onboarding submission toward admin review.
* Evidence: cleaner profile collections/services; cleaner Flutter onboarding flows.

### FR-05 Cleaner Approval — IMPLEMENTED

* Admin approve/reject (and related admin user ops) with persisted status affecting marketplace participation.
* Evidence: admin operations API; admin Flutter approvals.

### FR-06 Discovery/Search — IMPLEMENTED

* Customer discovery/list/filter with keyset-style pagination and availability-aware presentation.
* Evidence: services/availability/discovery API + customer discovery UI.
* Not a full geographic/maps search engine (no Elasticsearch) — in-scope marketplace discovery.

### FR-07 Cleaner Details/Comparison — IMPLEMENTED

* Cleaner detail DTOs and local comparison UX.
* Evidence: discovery detail endpoints; Flutter comparison screens.

### FR-08 Availability — IMPLEMENTED

* Cleaner UTC availability slots; customer sees bookable slots; reserved slots filtered.
* Evidence: availability collections/API; booking reservation docs.
* Limitation: cross-slot overlap not DB-unique (documented).

### FR-09 Booking — IMPLEMENTED

* Complete-slot reservation, immutable quote snapshot, idempotent create, concurrency on same slot.
* Evidence: booking API + Flutter booking flow; [booking-reservation-and-lifecycle.md](../architecture/booking-reservation-and-lifecycle.md).

### FR-10 Booking Management — IMPLEMENTED

* Lifecycle transitions for customer/cleaner (and admin oversight); payment-aware cancellation rules.
* Evidence: booking lifecycle services; role booking screens.

### FR-11 Payment — PARTIAL / DEVELOPMENT-ONLY

* **IMPLEMENTED:** provider-neutral ledger, webhooks, refund foundation, Flutter sandbox simulation UI when allowed.
* **DEVELOPMENT-ONLY:** sandbox provider; production returns unavailable — **no real card charge**.
* Evidence: [payment-processing-and-webhooks.md](../architecture/payment-processing-and-webhooks.md).
* Do **not** call this production payment complete.

### FR-12 Booking Status — IMPLEMENTED

* Status model + Flutter status labels/chips; lifecycle visibility on role dashboards.
* Evidence: shared `AppStatusLabels`; booking DTOs.

### FR-13 Chat/Notifications — IMPLEMENTED (transport PARTIAL relative to realtime expectations)

* Booking-scoped REST chat and in-app notifications.
* **DEFERRED:** WebSocket/SSE, push notifications.
* Evidence: chat/notification APIs + Flutter screens; ADR-015.

### FR-14 Ratings/Reviews — IMPLEMENTED

* Verified reviews, computed ratings for discovery, admin moderation.
* Evidence: review API + Flutter review flows.

### FR-15 Admin Dashboard — IMPLEMENTED (breadth PARTIAL vs enterprise admin suites)

* Admin home and operational screens for approvals, users, bookings, payments/refunds, reviews, disputes, payouts, reconciliation, audit visibility as built.
* Not a full BI/warehouse console.
* Evidence: admin Flutter feature + admin operations API; ADR-016/017.

---

## Beyond original FR baseline (honest extras)

| Capability | Status |
| --- | --- |
| Email verification architecture | IMPLEMENTED / delivery DEVELOPMENT-ONLY |
| Password recovery | IMPLEMENTED / delivery DEVELOPMENT-ONLY |
| Password change + sessions | IMPLEMENTED |
| Cleaner earnings ledger | IMPLEMENTED |
| Cleaner payout requests | IMPLEMENTED architecture / provider DEVELOPMENT-ONLY |
| Financial reconciliation (read-only) | IMPLEMENTED |
| Append-only audit log | IMPLEMENTED (best-effort) |
| Disputes | IMPLEMENTED |
| Release-candidate UX / acceptance tests | IMPLEMENTED (fake-only acceptance) |
| Production email/SMTP | DEFERRED |
| Production payment provider | DEFERRED |
| Production payout provider | DEFERRED |
| MFA / OAuth | DEFERRED |
| AI features | DEFERRED (out of scope) |

---

## Role feature matrix

Legend: **I** = implemented for role · **D** = development-only dependency · **Def** = deferred · **—** = not applicable

| Area | Customer | Cleaner | Admin |
| --- | --- | --- | --- |
| Signup / login / logout | I | I | I (login; admin provisioning is operational) |
| Email verification | I + D delivery | I + D delivery | — |
| Password reset | I + D delivery | I + D delivery | I + D delivery |
| Profile | I | I | user ops I |
| Addresses | I | — / limited | — |
| Cleaner onboarding | — | I | approve I |
| Discovery / compare | I | — | — |
| Availability manage | — | I | — |
| Book / manage jobs | I | I | oversee I |
| Pay for booking | I + D sandbox | — | refunds/ops I + D sandbox |
| Chat | I | I | limited/ops as built |
| Notifications | I | I | I as built |
| Reviews | I | receive/view | moderate I |
| Disputes | I | I | resolve I |
| Earnings | — | I | reconcile I |
| Payouts | — | I + D sandbox | process I + D sandbox |
| Audit trail | — | — | I (best-effort) |
| Push / WebSocket | Def | Def | Def |

---

## Summary verdict

Core marketplace FRs **01–10, 12–15** are implemented in software with documented limitations. **FR-11 Payment** (and payout/email) are **architecturally present** but **not production-provider complete**. The product can be **software release ready** for portfolio/demo while remaining **not fully production service ready**.
