# Cursor Task 020 — Account Recovery, Verification, and Session Security

## Metadata

- Task ID: 020
- Task title: Email Verification, Password Recovery, Password Change, Session Management, and Authentication Hardening
- Date: 2026-08-26
- Git branch: main (HEAD remains TASK 019 checkpoint; TASK 020 uncommitted)
- Repository root: D:\freelance\erfankhan_cse489\final
- Flutter project root: D:\freelance\erfankhan_cse489\final\project
- Status: SUCCESS

## Recovery Note

The first TASK 020 Cursor run ended unexpectedly during backend implementation. Existing uncommitted work was preserved; no `git reset`, `git restore`, `git clean`, or `git stash` was performed. Repository state was inspected for incomplete writes; backend and Flutter verification was rerun from the preserved changes. TASK 020 was completed from that state.

## Objective

Complete account security lifecycle: email verification before session issuance, password recovery, authenticated password change, shared account-action tokens, session management, authentication hardening, development-only delivery boundary, Flutter UX, tests, documentation. No MFA, OAuth, or production email provider.

## Pre-Task Verification

- Branch: `main`
- HEAD: `9a5b7a3` (TASK 019 checkpoint)
- Backend baseline: `dart analyze` clean; `dart test` **483 passed**
- Flutter baseline: `flutter analyze` clean; `flutter test` **349 passed**
- `backend/.env` gitignored (`.gitignore:8:.env`)
- No new direct dependencies added

## Final Verification

| Check | Result |
|-------|--------|
| Backend `dart analyze` | Clean (info/warnings only) |
| Backend `dart test` | **502 passed** |
| Dart Frog routes | Includes verification, reset, password change, sessions |
| Live index ensure | `account_action_tokens_*` indexes verified |
| Flutter `flutter analyze` | **0 issues** |
| Flutter `flutter test` | **370 passed** |
| Flutter `flutter build apk --debug` | Success |
| Live GET `/`, `/health`, `/ready`, `/services` | **200** each (port 8100) |

## Implementation Summary

### Backend

- Shared `account_action_tokens` collection with `AccountActionPurpose`, SHA-256 hashed opaque tokens, atomic claim, replacement, TTL indexes
- `AccountActionDeliveryProvider` with development/test provider only; production returns `503 account_action_delivery_unavailable`
- Signup creates unverified user, issues verification token, **no session/tokens**
- Login enforces `email_verified` after password check → `403 email_not_verified`
- Email verification request/consume, password reset request/confirm, authenticated password change
- Session list (cap 50), revoke one, revoke all; `is_current` from JWT principal
- `Cache-Control: no-store` on sensitive auth/account-action responses
- `AccountSecurityService` HTTP-independent layer

### Flutter

- `SignupResult` / pending verification flow; no token storage on signup
- Verification, forgot/reset password, account security, change password, session management screens
- Focused controllers; Security entry on customer/cleaner/admin homes
- Public/authenticated Dio split preserved

### Documentation

- `documentation/database/account-action-tokens-collection.md`
- `documentation/api/account-security-api.md`
- `documentation/architecture/account-recovery-verification-and-session-security.md`
- `documentation/decisions/ADR-018-account-recovery-verification-and-session-security.md`
- README/index and auth doc updates

## Exact Cursor Prompt

The complete verbatim TASK 020 assignment prompt is the authoritative specification titled **"TASK 020 — Email Verification, Password Recovery, Password Change, Session Management, and Authentication Hardening"** issued at task start (repository `D:\freelance\erfankhan_cse489\final`). It is identical to the full prompt in the ChatGPT task package and must not be replaced by the TASK 020R recovery prompt. All sections through **STEP 28 — DO NOT COMMIT** and **FINAL RESPONSE FORMAT** apply.

## Git Status

TASK 020 changes remain **uncommitted** by design for ChatGPT review.
