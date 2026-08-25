# ADR-012 — Service Offerings, Availability, and Cleaner Discovery

## Status
Accepted

## Context

TASK 013 delivered customer profiles, addresses, cleaner onboarding, and admin approval. Approved cleaners were not yet configurable or discoverable. Booking will later consume a stable service offering and UTC availability foundation. Money must not use floating point. Customer browsing must not expose cleaner contact or review metadata. MongoDB cannot enforce arbitrary interval exclusion with a unique index.

## Decision

* Own platform catalog definitions in a `services` collection, not on cleaner profiles.
* Seed only the canonical `home-cleaning` service through a controlled, idempotent, manually runnable tool (`tool/ensure_service_catalog.dart`), never at request time or server startup.
* Store cleaner offerings in `cleaner_services` (one row per cleaner + service) with integer `hourly_rate_minor` and an explicit uppercase `currency_code`.
* Deactivate offerings logically (`is_active = false`) instead of deleting rows.
* Require `ApprovedCleanerPolicy` (active cleaner + onboarding approved) for offering and availability mutation; do not bake that into global role middleware.
* Persist availability slots as UTC open future windows, 60 minutes–8 hours in 30-minute increments.
* Detect overlap with a repository query (`existing.start_at < proposed.end_at AND existing.end_at > proposed.start_at`); allow exact adjacent boundaries.
* Cap future slots at 180 per cleaner.
* Page discovery with a `cleaner_services._id` keyset cursor (limit 1–50, default 20) using bounded batch fetches, not N+1 loops and not claimed ranking.
* Return customer-safe DTOs only.
* Keep comparison local in Flutter, maximum three cleaners, session-only.

## Alternatives Considered

### Price as double

Rejected due money precision.

### Put service price directly on cleaner_profiles

Rejected because a cleaner may later offer multiple services.

### Delete offering row when disabled

Rejected because future booking/history needs a stable relationship.

### Store availability in local time

Rejected because backend scheduling requires unambiguous timestamps.

### Offset pagination

Not selected because keyset pagination scales better.

### Expose cleaner phone/email during discovery

Rejected for privacy and because contact should be controlled by later booking workflow.

### Currency conversion in client

Deferred because exchange-rate and currency metadata systems do not exist.

### Database-perfect interval exclusion

Deferred because MongoDB has no simple exclusion constraint for arbitrary time ranges; application overlap checks are documented until booking reservation architecture is introduced.

## Consequences

* Additional platform services can be added later without changing authentication, profile, or booking ownership models.
* Flutter displays minor-unit prices without dividing by 100.
* Concurrent partially overlapping slot inserts can theoretically race until booking reservation controls exist.
* Discovery order by `_id` is deterministic, not a marketplace rank.
* Unapproved cleaners still use TASK 013 onboarding routes.

## Security

* Offering and slot owner identity comes from the authenticated persisted user; HTTP bodies cannot override cleaner id.
* Availability update/delete selectors include `_id` and `cleaner_user_id`.
* Discovery returns only approved active cleaners with active offerings of an active service.
* Customer JSON excludes email, phone, review metadata, passwords, tokens, and sessions.
* Raw Mongo errors are not exposed.
* Catalog seed cannot mutate users, profiles, or sessions.
* Flutter protected APIs reuse authenticated Dio; the public catalog uses plain Dio. No MongoDB URI or `ACCESS_TOKEN_SECRET` in the client.

## Deferred Decisions

* booking
* slot reservation
* payment
* cancellation
* cleaner service-specific duration rules
* ratings/reviews
* geospatial filtering
* service-area normalization
* ranking/recommendations
* currency conversion
* admin catalog editor
* recurring availability rules
