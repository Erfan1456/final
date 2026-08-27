# Demo Data Seeding

Idempotent portfolio demo seed for MongoDB Atlas.

## Purpose

Populate `home_cleaning_marketplace` with realistic, interconnected marketplace
data so admin/customer/cleaner Flutter walkthroughs have populated screens.

## Seed key

`portfolio_demo_v1`

Tracked in tooling-only collection `demo_seed_manifests` (not an application
domain collection).

## Database targeting

Application runtime database and seed database are the same:

**`home_cleaning_marketplace`**

`MONGODB_URI` must include that database path explicitly. The seed tool uses the
normal configured Mongo connection (no silent URI rewrite / override).

If the configured URI has no database path, or targets any other name
(including driver-default `test`), `--apply` / `--summary` **STOP before
mutation** with:

`Configured MongoDB database must be home_cleaning_marketplace.`

The URI itself is never printed.

On failure, known tool-owned errors may show a safe message (for example the
database-target requirement above). Unexpected Mongo/driver/internal errors
produce only a generic CLI failure line — never raw exception text, stack
traces, or connection strings.

Private local `backend/.env` must target `home_cleaning_marketplace` and remains
gitignored.


## Commands

From `backend/`:

```bash
dart run tool/seed_demo_data.dart --dry-run
dart run tool/seed_demo_data.dart --apply
dart run tool/seed_demo_data.dart --summary
```

### Apply credentials (runtime only)

Set environment variables (never commit them):

- `DEMO_SEED_ADMIN_PASSWORD` — target administrator password
- `DEMO_SEED_SHARED_PASSWORD` — shared development-only seed credential for
  synthetic `@example.com` accounts

The administrator seed password is intentionally not stored in repository
documentation.

Synthetic demo accounts share a development-only seed credential (also not
documented in plaintext here).

Passwords are validated with `PasswordPolicy` and hashed with
`Argon2idPasswordHasher` before insert/update.

## Safe re-run behavior

On `--apply`:

1. Load previous `portfolio_demo_v1` manifest if present.
2. Delete **only** documents whose `_id` values are listed in that manifest.
3. Never wipe collections or delete unrelated documents.
4. Upsert target admin `erfan.khan.cse@gmail.com` in place (role/status/verified
   /password hash); revoke that user’s sessions after credential change.
5. Reseed deterministic demo documents.
6. Replace the manifest after success.

On mid-run failure: best-effort delete of documents inserted during that run
only.

## Data categories

Users (15: 6 customers / 7 cleaners / 2 admins), profiles, addresses, cleaner
onboarding states, offerings, availability, bookings (all lifecycle statuses),
payments/refunds (sandbox), conversations/messages, notifications, reviews
(including one hidden), disputes, audit logs, earnings ledger, payouts, and a
small number of fake provider event receipts.

Does **not** seed: sessions, refresh tokens, JWTs, account-action tokens.

## Synthetic-only policy

Except the known target admin email, all demo emails use `@example.com`.
No real personal phones, cards, bank credentials, or government IDs.

## Cleanup behavior

Only manifest-listed ObjectIds are removable by the seed tool. Non-seed data is
preserved. The target admin account is never deleted during cleanup even if its
id appears in a prior manifest.

## Known admin email

`erfan.khan.cse@gmail.com` (role `admin`, active, email verified).

Password handling: see Apply credentials above — plaintext is never stored in
Git, docs, manifests, or logs.
