# Portfolio Demo Data Seed

## Status

SUCCESS

## Authorization

Live MongoDB demo-data mutation was explicitly requested by the user.

## Pre-Seed Baseline

- HEAD: `c450613` `production_deployment_release_and_final_audit`
- Working tree: clean before seed-tool work
- Backend: `dart analyze` clean; **522** tests passed
- Flutter: `flutter analyze` clean; **434** tests passed

## Seed Utility

- CLI: `backend/tool/seed_demo_data.dart` (`--dry-run` | `--apply` | `--summary`)
- Support: `backend/tool/demo_seed/*`
- Seed key: `portfolio_demo_v1`
- Manifest collection: `demo_seed_manifests`
- Passwords: runtime env only (`DEMO_SEED_ADMIN_PASSWORD`, `DEMO_SEED_SHARED_PASSWORD`); never stored in source/docs/manifests
- Database targeting: configured URI must explicitly target
  `home_cleaning_marketplace`; mismatched/empty path → refuse before mutation
  (no silent override)

## Database Verification

Connected/applied database name: **home_cleaning_marketplace** (URI never printed).

## Final Error-Redaction Correction

Known safe seed errors (`DemoSeedException`, e.g. wrong/missing database
target) may be displayed as their intentional message. Unknown exceptions are
reduced to a generic CLI line such as “unexpected database/tool error.”
Arbitrary `error.toString()` values and stack traces are not printed. No live
data mutation was required for this correction.

## Database Alignment Correction

Private `backend/.env` was aligned so `MONGODB_URI` targets
`home_cleaning_marketplace` (path only; credentials/host/options preserved).
The file remains gitignored and was never printed.

The seed tool no longer rewrites the URI to force another database. Apply and
summary use the normal configured connection and stop if the configured
database is not `home_cleaning_marketplace`.

Existing `portfolio_demo_v1` data was **preserved** (not re-applied /
duplicated). Post-alignment `--summary` and read-only API checks
(`GET /`, `/api/v1/health`, `/api/v1/ready`, `/api/v1/services`) succeeded
against the aligned runtime database.

## Users

15 total — 6 customers, 7 cleaners, 2 administrators.

## Customer Data

6 customer profiles; 9 addresses (Dhaka-area fictional); 5 active + 1 suspended customer.

## Cleaner Data

7 cleaner profiles — 5 approved, 1 pending, 1 rejected (with rejection reason). 5 offerings (one per approved cleaner; only canonical `home-cleaning` platform service exists, unique per cleaner+service). 34 future availability slots.

## Admin Data

- Target: `erfan.khan.cse@gmail.com` — admin, active, email verified (created this run)
- Secondary: `admin.demo@example.com`
- Target admin credential verification: **PASS** (hash verify only; no session/token printed)

## Services

Canonical `home-cleaning` ensured via existing catalog ensure path.

## Availability

34 UTC future slots across approved cleaners (next ~14 days).

## Bookings

14 bookings by status: pending 2, confirmed 2, in_progress 1, completed 5, declined 2, cancelled 2. Active reservations unique per slot.

## Payments and Refunds

14 payments: pending 1, authorized 2, paid 6, partially_refunded 1, failed 1, cancelled 2, refunded 1. Sandbox provider ids only. 2 payment webhook event receipts.

## Conversations and Messages

8 conversations; 16 members; 32 messages.

## Notifications

32 total — 24 unread, 8 read.

## Reviews and Moderation

5 reviews — 4 published, 1 hidden (admin moderation fields set).

## Disputes

3 — open 1, under_review 1, resolved 1.

## Audit Logs

10 admin-action audit records.

## Earnings

5 service earning credits across 5 cleaners; commission via configured `PLATFORM_COMMISSION_BPS` / `CommissionMath`.

## Payouts

4 requests — requested 1, processing 1, paid 1, failed 1. 2 payout provider event receipts.

## Integrity Verification

PASS (relational checks + unique active slot reservations + review eligibility + admin credential verify).

## Dry Run

PASS — planned counts matched apply (15 users, 14 bookings, full status coverage).

## Apply Result

PASS — completed; manifest written.

## Summary Result

PASS — all manifest ids present (15/15 users … through payout events).

## Tests

Seed unit tests: 12 passed (plan + URI helper). Full backend/Flutter suites re-run after implementation (see final response counts).

## Security Review

- No secrets printed
- No plaintext passwords in repository files
- No sessions/JWTs/refresh/account-action tokens seeded
- Only demo seed / manifest-scoped mutation; non-seed records preserved
- Target admin password handled as [user-supplied demo administrator password]

## Git Status

Seed tooling and documentation left **UNSTAGED / UNCOMMITTED** for review.

## Issues / Warnings

- Only one platform service exists → one offering per approved cleaner (unique index), not 2–4 distinct service types.
- Historical note: the initial apply used a temporary URI override while local `.env` lacked a DB path; that mismatch was corrected by aligning private `.env` and removing the seed override.

## Final Statement

Application runtime and portfolio seed both use `home_cleaning_marketplace`. The existing `portfolio_demo_v1` dataset is visible through the normal backend configuration without duplication.
