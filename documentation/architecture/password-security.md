# Password Security

This document describes the password hashing and verification boundary used by future authentication.

TASK 009 established these primitives. Signup, login, sessions, and tokens are not implemented.

## Purpose

Hash and verify account passwords before any authentication HTTP API exists. Future signup/login must call this boundary rather than implementing cryptography in routes.

## Algorithm

Argon2id via `hashlib` 2.4.2.

## Parameters

```text
memory:      19456 KiB (19 MiB)
iterations:  2
parallelism: 1
hash length: 32 bytes
salt:        16 cryptographically secure random bytes
```

These values match OWASP's current Argon2id minimum recommendation. They must not be silently weakened.

## Storage

The hasher returns hashlib's encoded PHC string. That encoded value is what `users.password_hash` will store. It includes algorithm, version, m/t/p parameters, salt, and derived hash.

There is no separate `password_salt` field. TASK 009 does not write `password_hash` to Atlas.

## Password Semantics

Passwords are opaque secrets.

* Do not trim
* Do not lowercase or uppercase
* Do not Unicode-normalize
* Encode as UTF-8 before hashing
* `" Correct Horse Battery Staple "` is not the same secret as `"Correct Horse Battery Staple"`
* `"Password"` is not the same secret as `"password"`

Do not reuse email normalization for passwords.

## Policy

`PasswordPolicy` counts Unicode code points (Dart runes).

* minimum: 15
* maximum: 128
* spaces allowed
* Unicode allowed
* punctuation allowed
* no required uppercase, lowercase, number, or symbol

Policy validation does not hash the password.

## Verification

Verification uses hashlib `argon2Verify` against the encoded hash. It does not compare encoded strings with `==` and does not generate a new salt.

* correct password → true
* incorrect password → false
* malformed or unsupported stored hash → false (does not crash)

## Rehashing

`needsRehash` is true when the encoded hash is malformed, uses a different algorithm, or uses weaker/different cost parameters than the approved target. It is false for a hash produced by the current hasher.

Successful login now replaces an outdated hash after password verification and an active-account check. The update writes only `password_hash` and `updated_at`. Wrong passwords and missing users never trigger a rehash.

## Security Boundaries

Never log plaintext passwords, salts, or encoded hashes unnecessarily.

Never expose `password_hash` through `UserAccount.toPublicJson`.

Never derive salt from email, user id, timestamp, or password.

## Deferred

* compromised-password blocklist
* pepper
* MFA
* production rate limiting
* password reset
* email verification enforcement
