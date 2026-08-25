# Availability Slots Collection

This document describes the `availability_slots` collection.

TASK 014 stores open future bookable windows. There is no customer id, booking id, payment information, or status field yet. TASK 015 booking will extend reservation semantics. Recurring rules are not stored.

## Purpose

A slot is an open interval owned by one cleaner for one platform service. Adjacent boundaries are allowed; overlapping intervals are not.

## Document shape

```text
_id               ObjectId
cleaner_user_id   ObjectId   (users._id; never taken from an HTTP body)
service_id        ObjectId   (services._id)
start_at          DateTime   (UTC)
end_at            DateTime   (UTC)
created_at        DateTime   (UTC)
updated_at        DateTime   (UTC)
```

All timestamps are persisted UTC. Local-time strings are never stored.

## Duration rules

* `start_at` and `end_at` require ISO-8601 with an explicit timezone/offset, then normalize to UTC
* `start_at < end_at`
* slot start must be strictly in the future
* duration minimum 60 minutes, maximum 8 hours
* duration must be a multiple of 30 minutes

The cleaner must be approved, the platform service must be active, and the cleaner must have an **active** offering for `service_id`.

## Overlap

Overlap condition:

```text
existing.start_at < proposed.end_at
AND existing.end_at > proposed.start_at
```

Exact adjacent boundaries (`existing.end_at == new.start_at`) are **not** overlap. Example: 09:00–11:00 and 11:00–13:00 are allowed. Overlap is forbidden even across different services for the same cleaner. Updates exclude the current slot id.

MongoDB cannot enforce arbitrary interval exclusion with a unique index. TASK 014:

* runs a repository overlap query
* uses unique `cleaner_user_id` + `start_at` to reject exact-start duplicates
* documents that two concurrent **partially overlapping** inserts can theoretically race because no distributed interval lock exists yet

This limitation is acceptable until booking introduces reservation concurrency controls. Do not treat the interval constraint as database-perfect.

## Product limit

Maximum **180** future slots per cleaner. Count future slots before create. HTTP 409 `availability_limit_reached` at the limit.

## Edit / delete

Cleaners may update or physically delete only their own slot when `start_at > now`. Unknown, not-owned, and already-started slots map to HTTP 404 `availability_not_found` without revealing another owner's ObjectId.

Ownership selectors include `_id` and `cleaner_user_id`.

## Indexes

* `availability_slots_cleaner_start_unique` — unique `cleaner_user_id` + `start_at`
* `availability_slots_service_start` — `service_id` + `start_at`
* `availability_slots_cleaner_service_start` — `cleaner_user_id` + `service_id` + `start_at`

`availability_slots_cleaner_start` was **omitted** as redundant: the unique `cleaner_user_id` + `start_at` index already covers that prefix.

## Future booking relationship

Open slots are the schedule foundation later booking will consume. TASK 014 does not claim, reserve, or charge slots.

## Live data policy

TASK 014 must not create, update, delete, or dump live availability documents. Automated tests use in-memory fakes. Only approved index metadata may be ensured on Atlas.
