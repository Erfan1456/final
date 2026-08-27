# Release-Candidate UX Guidelines

Internal Flutter UX conventions for the Home Cleaning Service Marketplace release candidate.

These guidelines describe the shared presentation layer under `project/lib/shared/` and how feature screens should use it. They do not claim production deployment, real email delivery, real card charging, or real payouts.

## Layout conventions

| Token | Value | Use |
| --- | --- | --- |
| `AppSpacing.xs` | 4 | Tight chip/row gaps |
| `AppSpacing.small` | 8 | Related control spacing |
| `AppSpacing.normal` | 16 | Default padding / field gaps |
| `AppSpacing.section` | 24 | Between page sections |
| `AppSpacing.large` | 32 | Rare major separation |

Phone screens use normal horizontal padding (~16). Wide surfaces center content with `AppLayout.constrained`:

- forms ≈ `AppLayout.formMaxWidth` (600)
- detail pages ≈ `AppLayout.detailMaxWidth` (800)
- admin dashboards ≈ `AppLayout.dashboardMaxWidth` (wider)

Do not stretch forms edge-to-edge across desktop-sized windows.

## Shared states

Prefer:

- `AppLoadingState` — spinner plus optional context text
- `AppEmptyState` — non-error empty content with optional action
- `AppErrorState` — safe message plus optional **Try Again**
- `AppSuccessBanner` — soft success/info
- `AppAsyncContent` — chooses loading / error / empty / content

Rules:

- Never leave a blank body while loading.
- Never show raw exception or stack text.
- Empty is not error; error is not empty.
- Retry is user-initiated. Do not blindly auto-retry mutating requests.

## Buttons and destructive actions

- Primary path: `FilledButton` / `AppPrimaryButton`
- Secondary: tonal or outlined
- Destructive: `AppDangerButton` or danger styling, with `AppConfirmationDialog` before irreversible actions (cancel booking, revoke session, reject cleaner, etc.)
- While submitting, disable the primary action and show progress (`AppLoadingButton` / disabled `FilledButton`) so duplicate taps do not stack logical mutations.

## Status presentation

Centralize user-facing status strings in `AppStatusLabels` (booking, payment, payout, dispute, review, onboarding).

- Unknown / blank wire values → `Unknown`
- Unrecognized wire values → `Unsupported Status`
- Prefer `AppStatusChip` for compact status display
- Do not invent success or rating values the backend did not return

## Money presentation

Amounts are **integer minor units**. Formatters must **not** divide by 100.

- `formatMinorUnits` / `formatPaymentAmount` → `BDT 250000 minor units`
- `formatQuotedTotal` → `Quoted total: …`

Currency decimal metadata is not modeled. Do not invent major-unit currency formatting.

## Date/time presentation

- Prefer `formatAppDateTime` / `formatLocalDateTime`
- Treat UTC server timestamps as UTC, convert with `toLocal()`, and show a readable month-name local string
- Avoid raw ISO-8601 as the primary user-facing label when a formatter exists

## Accessibility

- Password fields: obscured by default with show/hide `IconButton` tooltips (`Show password` / `Hide password`)
- Icon-only actions need tooltips
- Development banners expose a Semantics label
- Status and errors should remain readable as text, not color alone

## Text scaling

Respect platform text scaling. Do not clamp or disable large text to hide overflow. Acceptance coverage pumps key screens at ~2.0 text scale on a compact phone size.

## Responsive behavior

- Compact phone: single column, full-width primary actions
- Wide: constrain readable forms/details; admin lists may use a wider max width
- Avoid horizontal overflow at 360×640

## Sandbox / development labeling

Use `AppDevelopmentBanner` wherever the UI exposes development-only simulation:

- customer payment simulate success/failure
- cleaner payout request (sandbox payout, no bank destination)

Never imply real money movement or production email delivery.

## Empty / error / loading rules

| Situation | Presentation |
| --- | --- |
| First load, no data | `AppLoadingState` with short context |
| Success, zero items | `AppEmptyState` with next action when useful |
| Load failed, no data | `AppErrorState` + Try Again |
| Load failed, stale data | Keep stale content; show a non-blocking error if needed |
| Mutation failure | Inline/safe message; leave form values intact when possible |
| Success | Banner, snackbar, or navigational confirmation — never a fake status |
