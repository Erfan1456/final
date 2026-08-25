# Service Offerings, Availability, and Discovery Architecture

TASK 014 makes approved cleaners configurable and discoverable. Booking, payment, chat, reviews, maps, geocoding, ranking, and admin catalog UI are not implemented.

## Product flow

```text
Cleaner approved
    ↓
Service offering (hourly_rate_minor + currency_code + is_active)
    ↓
Availability (UTC open future slots)
    ↓
Customer discovery (filters + cursor page)
    ↓
Cleaner detail (safe public profile + future slots)
    ↓
Local comparison (max 3, session-only)
```

## Authorization boundary

```text
JWT (authentication only)
  → persisted user
  → role + active account
  → approved-cleaner policy (management only)
  → application service
  → repository
```

Role middleware from TASK 013 is unchanged: unapproved cleaners can still use onboarding profile routes. `ApprovedCleanerPolicy` is applied by service/availability application services, not globally.

Customer discovery is customer-role only. The public catalog `GET /api/v1/services` returns platform metadata without user information.

## Discovery

```text
customer request
  → filter validation
  → CleanerDiscoveryService
  → bounded batch queries (offerings page, then users/profiles/slots)
  → customer-safe DTO
  → Flutter discovery
```

Strategy: page `cleaner_services` by `_id` (limit ≤ 50), then `findByIds` / `findByUserIds` and a bounded availability batch. Do not N+1 one cleaner at a time. This is deterministic keyset pagination, not marketplace ranking.

When no availability range is supplied, approved cleaners with an active offering may appear with `next_available_at` null.

## Why integer minor units

Hourly price is stored as `hourly_rate_minor` (integer). Floating-point money is rejected. TASK 014 does not assume two decimal places globally. Flutter displays a technical label such as `BDT 250000 minor units / hour`. Currency conversion is deferred because no exchange-rate or ISO decimal metadata system exists.

## Why UTC availability

Scheduling requires unambiguous timestamps. Clients send ISO-8601 with an explicit offset; the backend stores UTC. UI may render `DateTime.toLocal()`.

## Interval-overlap limitation

Application overlap queries plus a unique cleaner/start index prevent most conflicts. MongoDB has no simple exclusion constraint for arbitrary ranges. Concurrent partially overlapping inserts can theoretically race. TASK 015 booking must introduce stronger reservation controls. Adjacent boundaries are allowed.

## Privacy DTO

Customer-facing models exclude email, phone, review metadata, account internals, and security fields. Contact remains for later booking workflow, not marketplace browsing.

## Flutter

Focused Riverpod controllers: catalog (plain Dio), cleaner services, availability, discovery, comparison (max 3, not persisted). Protected APIs reuse TASK 012 authenticated Dio. Routes:

* `/cleaner/services`, `/cleaner/availability`, `/cleaner/availability/new`, `/cleaner/availability/:slotId/edit`
* `/customer/discover`, `/customer/cleaners/:cleanerUserId`, `/customer/compare`

Role guards are UX only. Backend policy remains authoritative. Unapproved cleaners see "Approval required" rather than mutating offerings.
