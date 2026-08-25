# Admin Operations API

Admin-only user management, booking oversight, and audit log routes. Persisted admin role is required. JWT role alone is not sufficient.

Payouts, finance summary, and reconciliation live in [earnings-and-payout-api.md](earnings-and-payout-api.md). Password recovery, MFA, chargebacks, and AI moderation are not implemented.

All list endpoints use keyset pagination: `limit` default 20 (1–50), `after` ObjectId cursor, sort `_id` descending. No offset.

## Users

| method | path |
| --- | --- |
| `GET` | `/api/v1/admin/users` |
| `GET` | `/api/v1/admin/users/{userId}` |
| `POST` | `/api/v1/admin/users/{userId}/suspend` |
| `POST` | `/api/v1/admin/users/{userId}/reactivate` |
| `POST` | `/api/v1/admin/users/{userId}/deactivate` |

### List query

`role` (`customer` / `cleaner` / `admin`), `status` (`active` / `suspended` / `deactivated`), `email` (optional **exact** normalized email only; no regex/substring scan), `limit`, `after`.

Safe list fields: `id`, `role`, `email`, `account_status`, `email_verified`, `created_at`, `updated_at`, optional `full_name` / `onboarding_status`.

Never returned: `password_hash`, `email_normalized`, sessions, refresh-token hashes, password-reset data.

### Detail

Safe public user fields, role-specific profile, `protected_admin_account`, and operational counts (`booking_count`, `payment_count`, `active_dispute_count`) without N+1 where batching is used.

### Suspend / deactivate body

```json
{
  "reason": "Repeated no-show complaints"
}
```

Reason: required, trim, 5–500 Unicode code points, plain text, no controls. Reasons are stored in `audit_logs`, not on the user document.

### State machine

| route | allowed targets | transition |
| --- | --- | --- |
| suspend | customer, cleaner | `active` → `suspended` (already suspended: idempotent 200) |
| reactivate | customer, cleaner | `suspended` → `active` (already active: idempotent 200). `deactivated` is rejected |
| deactivate | customer, cleaner | `active` or `suspended` → `deactivated` |

Administrator accounts cannot be targeted. Self-target is also protected. Response: `403 protected_admin_account`.

Deactivation is not deletion. Bookings, payments, reviews, messages, and disputes remain.

After successful suspend or deactivate, all refresh sessions for the target are revoked through `AuthSessionService`. If revocation fails after the status write, the account stays unavailable because persisted `account_status` is authoritative. Status is not reverted to restore sessions. Access JWTs may exist briefly; persisted-user authorization still rejects non-active accounts.

Idempotent no-ops do not write a duplicate audit row.

## Bookings

| method | path |
| --- | --- |
| `GET` | `/api/v1/admin/bookings` |
| `GET` | `/api/v1/admin/bookings/{bookingId}` |
| `POST` | `/api/v1/admin/bookings/{bookingId}/cancel` |

### List query

`status`, `customer_user_id`, `cleaner_user_id`, `service_id`, `from`, `to` (explicit offset, normalized UTC, filter `booking.start_at`), `limit`, `after`.

Safe summary: booking id, status, customer/cleaner ids and display names, service name, schedule, quoted total, currency, payment summary, dispute summary.

Detail adds status history, service/pricing/address snapshots, payment summary/history, dispute summary. Full booking address is visible for support. No password, tokens, sessions, payment secret, webhook secret, or raw provider payload.

### Cancel body

```json
{
  "reason": "Duplicate booking created by mistake"
}
```

Admin may cancel only `pending` or `confirmed`. `in_progress`, `completed`, `declined`, and `cancelled` return `409 admin_booking_not_cancellable` (or existing `invalid_booking_state` where that remains semantically correct).

Pending uses conditional booking cancellation. Confirmed uses payment-aware orchestration: cancel pending/authorized payment first; refund remaining amount when paid/partially_refunded; only then cancel the booking. If refund fails, the booking stays confirmed. History actor is the admin user id and admin role (not impersonated customer/cleaner).

After success, customer and cleaner receive `booking_cancelled` with body `"An administrator cancelled this booking."` Admin email is not exposed.

## Audit logs

| method | path |
| --- | --- |
| `GET` | `/api/v1/admin/audit-logs` |
| `GET` | `/api/v1/admin/audit-logs/{auditLogId}` |

Query: `actor_user_id`, `action`, `target_type`, `target_id`, `from`, `to`, `limit`, `after`.

Safe fields: actor id/role, action, target type/id, reason, safe metadata, created_at.

Missing: `404 audit_log_not_found`.

## Error codes

| code | typical status |
| --- | --- |
| `user_not_found` | 404 |
| `protected_admin_account` | 403 |
| `invalid_account_state` | 409 |
| `invalid_moderation_reason` | 400 |
| `admin_booking_not_cancellable` | 409 |
| `audit_log_not_found` | 404 |
| `payment_refund_failed` | reused |
| `account_unavailable` | reused |
| `forbidden` | 403 |

Cursor pagination and validation errors follow existing API envelope conventions. Raw Mongo errors are not exposed.
