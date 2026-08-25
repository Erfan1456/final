# Audit Logs Collection

This document describes the `audit_logs` collection.

TASK 018 stores **append-only** administrative audit records. There is no update or delete repository method.

## Purpose

Record successful admin operational actions after the primary write succeeds. This is an operational trail for support, not a compliance-grade exactly-once ledger.

## Document shape

```text
_id             ObjectId
actor_user_id   ObjectId
actor_role      String     (admin)
action          String
target_type     String
target_id       ObjectId
reason          String?
metadata        Map        (safe scalars only)
created_at      DateTime   (UTC)
```

## Actions

Explicit enum / wire values only:

* `user_suspended`
* `user_reactivated`
* `user_deactivated`
* `cleaner_approved`
* `cleaner_rejected`
* `review_hidden`
* `review_unhidden`
* `payment_refund_requested`
* `dispute_review_started`
* `dispute_resolved`
* `dispute_closed`
* `booking_admin_cancelled`

Do not scatter arbitrary action strings.

## Metadata safety

Allowed examples: previous/new status, booking id, payment id, refund_amount_minor, currency_code.

Do **not** place in metadata: password, password hash, JWT, refresh token, idempotency key, request fingerprint, webhook signature/secret, Mongo URI, full service address, private message body, or raw payment-provider response.

Keep metadata small.

## Repository

`AuditLogRepository` exposes only:

* `append`
* `listPage`
* `findById`

No update. No delete.

Admin list uses keyset pagination (`_id` descending, `after` cursor). Limit default 20, range 1–50. Filters: `actor_user_id`, `action`, `target_type`, `target_id`, `from`, `to`.

## Indexes

| name | keys | unique | reason |
| --- | --- | --- | --- |
| `audit_logs_actor_id_desc` | `actor_user_id`, `_id` desc | no | actor filter + cursor |
| `audit_logs_action_id_desc` | `action`, `_id` desc | no | action filter + cursor |
| `audit_logs_target_id_desc` | `target_type`, `target_id`, `_id` desc | no | target lookup |
| `audit_logs_created_at` | `created_at` desc, `_id` desc | no | date-range listing |

`created_at` + `_id` supports `from`/`to` range queries together with keyset paging.

Users also gained `users_role_status_id_desc` (`role`, `account_status`, `_id` desc) for admin user listing.

## Best-effort consistency limitation

Audit write occurs **after** a successful primary admin action. There is no cross-document transaction or outbox in TASK 018.

If audit insertion fails:

* do **not** roll back account moderation, review moderation, payment refund request, booking cancellation, or dispute resolution
* surface the limitation to server diagnostics/logging without exposing internals to the client

The primary action remains authoritative. TASK 018 does **not** claim compliance-grade exactly-once audit persistence. A future outbox/worker strategy is deferred.

## Admin operations

Read API is admin-only. Do not expose audit routes outside the persisted admin role. Do not enrich logs with password/session/security data.

## Security

Append-only by construction. Admin-only read. Safe metadata only. Audit failure must not corrupt the primary action.
