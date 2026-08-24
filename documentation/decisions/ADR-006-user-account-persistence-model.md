# ADR-006 — User Account Persistence Model

## Status

Accepted.

## Context

Authentication needs a stable MongoDB account model before HTTP signup/login logic is implemented.

The backend already has a reusable MongoDB connection. The first real domain collection is `users`. The model must keep password hashes internal, enforce email uniqueness under concurrent requests, and avoid mixing authentication identity with role-specific profile data.

## Decision

* `users` collection
* ObjectId `_id`
* explicit `UserRole` strings (`customer`, `cleaner`, `admin`)
* explicit `AccountStatus` strings (`active`, `suspended`, `deactivated`)
* original + normalized email
* unique `email_normalized` index named `users_email_normalized_unique`
* password hash persisted but never publicly serialized
* repository abstraction + Mongo implementation
* UTC timestamps

Email lookup methods normalize the caller-supplied email internally (trim + lowercase).

## Alternatives Considered

### Email uniqueness only in application code

Rejected because concurrent requests can race.

### Case-sensitive unique email only

Rejected because user lookup/registration should treat casing consistently.

### MongoDB case-insensitive collation instead of normalized field

Viable, but an explicit normalized field is chosen for straightforward predictable lookup/index behavior.

### Store role/status enum ordinal

Rejected because ordinal persistence is fragile when enum definitions change.

### One giant generic repository

Rejected because feature-specific repositories keep contracts explicit and avoid speculative abstraction.

### Put customer/cleaner profile fields in users

Rejected/deferred because authentication identity and role-specific profile data have different lifecycles.

## Consequences

* duplicate emails are database-enforced
* future authentication has a clean persistence contract
* password hashes remain sensitive internal data
* profile collections will reference user `_id` later
* public JSON must continue to omit `password_hash`
* public signup must later refuse to create `admin` accounts

## Security

* No plaintext password is accepted or stored.
* Password hashing is not implemented in this decision; only an already-produced hash string may be persisted.
* Public serializers and `toString` omit password material.
* The unique index is the final uniqueness boundary; application `find` then `insert` is not relied on alone.
* Flutter never receives MongoDB credentials or password hashes from this model.

## Deferred Decisions

* password hashing algorithm
* authentication service
* signup/login routes
* sessions/tokens
* password resets
* email verification mechanism
* cleaner onboarding
* customer/cleaner profiles
* admin provisioning process
