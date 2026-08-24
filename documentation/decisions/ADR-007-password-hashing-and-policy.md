# ADR-007 — Password Hashing and Policy

## Status

Accepted.

## Context

The users persistence layer stores `password_hash`, but secure password generation and verification must exist before signup or login accepts credentials.

The application needs a memory-hard password hashing function, unique per-hash salts, an encoded storage format, and a server-side length policy that does not alter the user's secret.

## Decision

* hashlib 2.4.2
* Argon2id
* m=19456 KiB
* t=2
* p=1
* 32-byte hash
* 16-byte random salt
* encoded hash storage
* 15–128 Unicode-code-point password policy
* no composition rules
* no password normalization
* `needsRehash` support

UTF-8 encodes the password exactly as supplied. Salts come from hashlib `randomBytes` with a secure generator. Malformed stored hashes fail verification instead of crashing.

## Alternatives Considered

### SHA-256 / SHA-512 directly

Rejected because general cryptographic hashes are intentionally fast and are not suitable password-storage functions.

### bcrypt

Viable fallback but not selected because Argon2id is the preferred modern memory-hard password hashing algorithm.

### PBKDF2

Viable in environments requiring specific compliance constraints, but Argon2id is chosen for this application.

### Custom password-hashing algorithm

Rejected.

### Enforcing uppercase/numeric/symbol rules

Rejected because modern password guidance favors length and breached-password screening rather than arbitrary composition rules.

### Trimming passwords

Rejected because it changes the user's authentication secret.

### Password pepper now

Deferred until production secret-management strategy is designed.

## Consequences

* hashing is intentionally CPU/memory expensive
* login/signup must call the `PasswordHasher` rather than implementing crypto
* cost parameters can evolve through `needsRehash`
* password length checks occur before costly hashing
* future rate limiting remains necessary for online attacks

A local development-machine measurement of the approved parameters was acceptable and was not used to lower cost.

## Security

* Unique cryptographically secure salt per hash
* Encoded Argon2id PHC string includes salt and parameters
* Verification uses the library verifier, not string equality of encoded hashes
* Public `UserAccount` JSON still omits password hashes
* No plaintext password is persisted by this decision
* No pepper, breach-check API, or MFA is introduced here

## Deferred Decisions

* compromised-password screening
* pepper
* access tokens
* refresh tokens
* session storage
* auth middleware
* signup
* login
* logout
* password reset
* MFA
* rate limiting
