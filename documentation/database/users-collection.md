# Users Collection

This document describes the first persistence/domain boundary for the Home Cleaning Service Marketplace: user account identity records.

TASK 008 established the collection model, repository contract, and unique email index. TASK 009 established Argon2id password hashing primitives. Signup, login, and authentication HTTP routes are not implemented.

## Purpose

Stores authentication/account identity records.

Role-specific customer and cleaner profile data will live in later collections that reference `users._id`. Those profiles are not stored here.

## Document Shape

```text
_id              ObjectId
role             string   (customer | cleaner | admin)
email            string   (user-facing form)
email_normalized string   (trim + lowercase)
password_hash    string   (Argon2id encoded PHC form; never plaintext)
account_status   string   (active | suspended | deactivated)
email_verified   bool
created_at       DateTime (UTC)
updated_at       DateTime (UTC)
```

Do not store or document a real password hash.

## Roles

Persisted lowercase strings:

* `customer`
* `cleaner`
* `admin`

Dart uses idiomatic enum names `UserRole.customer`, `UserRole.cleaner`, and `UserRole.admin`. Enum ordinal values are never persisted.

`ADMIN` is modeled because administrators exist in the system. Public registration must not be allowed to create admin accounts. That authorization rule belongs to a later authentication task.

## Account Status

Persisted lowercase strings:

* `active`
* `suspended`
* `deactivated`

Cleaner approval is not an account status. Cleaner verification and onboarding belong to later cleaner profile/application data.

## Email Normalization

Uniqueness and lookup use `email_normalized`.

Policy:

* trim whitespace
* lowercase

Provider-specific rewriting (Gmail dots, plus addressing, domain rewriting) is not applied.

The original `email` value is retained for communication/display, with surrounding whitespace trimmed at create time.

## Indexes

`users_email_normalized_unique`

* collection: `users`
* key: `email_normalized` ascending
* unique: true

This database-enforced unique index is the concurrency-safe duplicate-email boundary.

## Password Security

Only encoded Argon2id password hashes are stored in `password_hash`. The encoded value includes algorithm, parameters, salt, and derived hash. See [../architecture/password-security.md](../architecture/password-security.md) and [../decisions/ADR-007-password-hashing-and-policy.md](../decisions/ADR-007-password-hashing-and-policy.md).

Public serializers (`UserAccount.toPublicJson`) never expose `password_hash` or `passwordHash`. `toString` also omits the hash.

## Current Operations

`UserRepository` / `MongoUserRepository` support only:

* lookup by id
* lookup/existence by email (normalized internally)
* create account

No signup API exists yet. TASK 008 did not insert real user documents into Atlas.

Index setup is deliberate via `dart run tool/ensure_database_indexes.dart`, not per HTTP request.

## Deferred

* authentication service
* signup/login routes
* sessions/tokens
* password reset
* email verification mechanism
* customer/cleaner profiles
* admin provisioning process
* additional indexes
