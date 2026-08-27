# ADR-019 — Release-Candidate UX and Acceptance Testing

## Status

Accepted

## Context

Through TASK 020 the marketplace already implements the major functional slices: authentication and account security, customer discovery/booking/payment/chat/reviews/disputes, cleaner onboarding/services/availability/jobs/earnings/payouts, and admin operations/finance/audit.

Those features were delivered incrementally. Screens worked, but presentation conventions, status/money/date labeling, loading/empty/error handling, sandbox honesty, accessibility under large text, and cross-role journey coverage were uneven. TASK 021 needed release-candidate cohesion without introducing a new UI framework, third-party design system, live Atlas acceptance harness, or production payment/email/payout providers.

## Decision

- **Shared internal UI primitives** under `project/lib/shared/` (`AppPageScaffold`, section/async/button/status helpers, layout/spacing tokens) used where they remove real duplication.
- **Material 3 consistency** retained via the existing app theme; feature screens keep Flutter Material controls rather than custom canvas UI.
- **Responsive constrained layouts** via `AppLayout` max widths for forms, details, and dashboards.
- **Explicit loading / empty / error states** through `AppLoadingState`, `AppEmptyState`, `AppErrorState`, and `AppAsyncContent`.
- **Status presentation centralization** in `AppStatusLabels` for booking, payment, payout, dispute, review, and onboarding wire values, with safe unknown/unsupported fallbacks.
- **Minor-unit money honesty** via `formatMinorUnits` / `formatPaymentAmount` / `formatQuotedTotal` without dividing by 100 or inventing currency decimals.
- **Local DateTime presentation** via `formatAppDateTime` / `formatLocalDateTime` (UTC → local, month-name display).
- **Safe manual retry** rather than blind mutation retry; Try Again is user-initiated on safe loads.
- **Accessibility / text scaling** respected (password show/hide tooltips, semantics on development banners, acceptance pumps at compact size and ~2× text scale).
- **Role-aware routing preservation** with existing go_router guards; foreign-role and unauthenticated redirects remain enforced in tests.
- **Cross-role acceptance harness** under `project/test/acceptance/` using Riverpod/API fakes.
- **No live Atlas mutation in acceptance tests**; fixtures are fake-only.
- **Development/sandbox labeling** with `AppDevelopmentBanner` on payment simulation and cleaner payout request flows.

## Alternatives Considered

### Add a third-party design-system library

Rejected. Adds dependency weight and stylistic lock-in for a portfolio release candidate that already standardizes on Material 3.

### Add automatic retry to every API request

Rejected because unsafe mutations may duplicate side effects. Prefer user-visible Try Again on idempotent reads and server idempotency where already designed.

### Disable large text scaling to prevent overflow

Rejected because it harms accessibility. Overflow should be fixed; acceptance tests catch regressions.

### Hard-code currency /100 formatting

Rejected because currency minor-unit metadata is not modeled. Showing integer minor units is honest.

### Test acceptance flows against live Atlas

Rejected due to state pollution, security, and reproducibility concerns.

### Replace existing router/state/network stacks

Rejected because current Riverpod + go_router + Dio architecture is established and tested.

## Consequences

- Feature screens should reuse shared formatters and async/status widgets instead of inventing one-off loading/error/money/date patterns.
- Acceptance tests can validate major role journeys and routing without a device farm or live database.
- Sandbox payment/payout controls remain visibly labeled as development-only.
- Some feature screens may still show transitional presentation until fully migrated onto shared widgets; new work should follow these conventions.
- Manual checklist remains required for visual and device-specific confirmation beyond automated pumps.

## Accessibility

- Password fields stay obscured by default with labeled show/hide controls.
- Compact layout + large text are covered for Login, Signup, role homes, and Account Security.
- Status and errors remain textual; color is not the sole signal.
- Development notices expose semantics labels.

## Testing

- Unit coverage for shared formatters/labels: `project/test/shared/presentation/app_formatters_test.dart`
- Acceptance journeys: customer, cleaner, admin under `project/test/acceptance/`
- Failure/routing/session invalidation acceptance coverage
- Responsive/accessibility overflow capture tests
- Existing router and feature widget tests remain the detailed regression net
- Commands: `flutter test test/acceptance` and `flutter test` from `project/`

## Deferred Decisions

- visual snapshot/golden infrastructure at scale
- real-device farm
- full localization/i18n
- RTL
- production analytics
- crash reporting
- push notifications
- WebSocket chat
- production payment/payout integrations
