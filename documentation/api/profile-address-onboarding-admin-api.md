# Profile, Address, Onboarding, and Admin Review API

TASK 013 adds role-scoped marketplace account APIs. Bookings, payments, chat, reviews, cleaner services, availability, earnings, and discovery are not implemented.

All feature routes require:

1. Bearer access JWT verification
2. persisted user resolution from `users`
3. `account_status == active`
4. **current persisted** `users.role` matching the route role

JWT `role` is authentication evidence only. It is not sufficient authorization.

Public signup still cannot create `admin` accounts. These admin routes assume an already-provisioned administrator.

See [authentication-api.md](authentication-api.md) for signup/login/refresh/logout and account routes.

## Shared error envelope

```json
{
  "success": false,
  "error": {
    "code": "forbidden",
    "message": "You do not have permission to perform this action."
  }
}
```

| Situation | HTTP | code |
| --- | --- | --- |
| missing/invalid/expired access token | 401 | `invalid_access_token` |
| user missing after JWT issue | 401 | `invalid_access_token` |
| suspended or deactivated | 403 | `account_unavailable` |
| authenticated active user, wrong persisted role | 403 | `forbidden` |
| malformed JSON / wrong types | 400 | `invalid_json` or `invalid_input` |
| unsupported method | 405 | (Allow header when the project convention applies) |

## Customer — `GET /api/v1/customer/profile`

Customer role only.

No profile yet:

```json
{
  "success": true,
  "data": {
    "profile": null
  }
}
```

Existing profile (fake data):

```json
{
  "success": true,
  "data": {
    "profile": {
      "id": "507f1f77bcf86cd799439021",
      "user_id": "507f1f77bcf86cd799439011",
      "full_name": "Ada Example",
      "phone_e164": "+15555550100",
      "default_address_id": null,
      "created_at": "2026-08-25T12:00:00.000Z",
      "updated_at": "2026-08-25T12:00:00.000Z"
    }
  }
}
```

## Customer — `PUT /api/v1/customer/profile`

Upserts the authenticated customer's profile. Body may only supply editable fields:

```json
{
  "full_name": "Ada Example",
  "phone_e164": "+15555550100"
}
```

`phone_e164` may be `null`. Body `user_id`, `default_address_id`, and timestamps are ignored/backend-owned.

HTTP 200 with `{ "profile": { ... } }`.

## Customer — `GET /api/v1/customer/addresses`

Returns owned addresses, `created_at` descending. `is_default` is computed. Pagination is not used (20-address cap).

```json
{
  "success": true,
  "data": {
    "addresses": [
      {
        "id": "507f1f77bcf86cd799439031",
        "label": "Home",
        "line1": "1 Example Street",
        "line2": null,
        "city": "Dhaka",
        "region": "Dhaka",
        "postal_code": "1205",
        "country_code": "BD",
        "is_default": true,
        "created_at": "2026-08-25T12:00:00.000Z",
        "updated_at": "2026-08-25T12:00:00.000Z"
      }
    ]
  }
}
```

## Customer — `POST /api/v1/customer/addresses`

HTTP **201**. May succeed before a customer profile exists. Default remains unset until explicitly selected.

```json
{
  "label": "Office",
  "line1": "2 Example Street",
  "line2": null,
  "city": "Dhaka",
  "region": "Dhaka",
  "postal_code": "1206",
  "country_code": "bd"
}
```

`country_code` is stored uppercase (`BD`).

| Conflict | HTTP | code |
| --- | --- | --- |
| already 20 addresses | 409 | `address_limit_reached` |

## Customer — `GET /api/v1/customer/addresses/{addressId}`

Ownership enforced in the Mongo selector. Missing or foreign → 404 `address_not_found`.

## Customer — `PUT /api/v1/customer/addresses/{addressId}`

Replaces editable address fields only. Cannot change `_id`, `user_id`, or timestamps.

## Customer — `DELETE /api/v1/customer/addresses/{addressId}`

Ownership enforced. If the address is the current default, the profile pointer is cleared first, then the address is deleted. Success envelope; no security fields.

## Customer — `PUT /api/v1/customer/addresses/{addressId}/default`

Ownership enforced.

| Conflict | HTTP | code |
| --- | --- | --- |
| no customer profile yet | 409 | `customer_profile_required` |
| missing/foreign address | 404 | `address_not_found` |

Returns the updated customer profile.

## Cleaner — `GET /api/v1/cleaner/profile`

Cleaner role only. `{ "profile": null }` until onboarding begins.

## Cleaner — `PUT /api/v1/cleaner/profile`

Create/update draft onboarding fields. Allowed when missing, `draft`, or `rejected`. Creates as `draft` if absent.

```json
{
  "full_name": "Naim Example",
  "phone_e164": "+15555550101",
  "bio": "Experienced residential cleaner for apartments and small homes.",
  "years_experience": 3,
  "service_area": "Dhaka North"
}
```

| Conflict | HTTP | code |
| --- | --- | --- |
| status `pending` or `approved` | 409 | `cleaner_profile_locked` |

## Cleaner — `POST /api/v1/cleaner/onboarding/submit`

No meaningful body. Transitions `draft` or `rejected` → `pending`, sets `submitted_at`, and on resubmission after rejection clears `rejection_reason`, `reviewed_at`, and `reviewed_by`.

| Conflict | HTTP | code |
| --- | --- | --- |
| no profile | 409 | `cleaner_profile_required` |
| already `pending` or `approved` | 409 | `invalid_onboarding_state` |

Returns the updated profile.

## Admin — `GET /api/v1/admin/cleaners`

Admin role only.

Query:

* `status` optional: `draft` \| `pending` \| `approved` \| `rejected` (default **pending**)
* `limit` optional: default 20, min 1, max 50
* `after` optional: cleaner_profile ObjectId cursor

Sort: filtered `onboarding_status`, then `_id` ascending. When `after` is supplied: `_id > after`.

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "507f1f77bcf86cd799439041",
        "user_id": "507f1f77bcf86cd799439077",
        "full_name": "Naim Example",
        "email": "pending.cleaner@example.com",
        "onboarding_status": "pending",
        "submitted_at": "2026-08-25T12:30:00.000Z"
      }
    ],
    "next_cursor": "507f1f77bcf86cd799439042"
  }
}
```

`next_cursor` is `null` when no further page exists. List items include a safe user email via batch user lookup. Password hashes, `email_normalized`, and session fields are omitted.

## Admin — `GET /api/v1/admin/cleaners/{userId}`

Safe user account fields plus cleaner profile. Unknown user/profile → 404 `cleaner_application_not_found`.

## Admin — `POST /api/v1/admin/cleaners/{userId}/approve`

No meaningful body. Pending only.

Approve sets `onboarding_status=approved`, `reviewed_at`, `reviewed_by` (current admin user id), `rejection_reason=null`. Does not change `users.role`.

Non-pending → 409 `invalid_onboarding_state`.

## Admin — `POST /api/v1/admin/cleaners/{userId}/reject`

```json
{
  "reason": "Please expand the service-area description."
}
```

Reason required, trim, 5–500 Unicode code points. Pending only. Same 409 for non-pending.

Responses include at most a safe reviewer id, never reviewer security fields.
