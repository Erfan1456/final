# Scalability and Growth Review

**Project:** Home Cleaning Service Marketplace  
**Versions:** Flutter `1.0.0+1`, backend `1.0.0+1`  
**Nature:** Architectural assessment for planning — **not** a load-test result and **not** a claim that the system “supports N users”

The current stack is a **stateless Dart Frog HTTP API** talking to **MongoDB Atlas**, consumed by a **Flutter Android client** over HTTPS REST. There is no Redis, Kafka, WebSocket layer, or multi-region active-active design in this repository.

---

## What already scales horizontally (with caveats)

* **Flutter clients** — independent devices; scale with user count, not server process count.
* **Dart Frog instances** — no in-process session affinity required for JWT access tokens; refresh state lives in MongoDB.
* **MongoDB Atlas** — managed storage; indexes exist for hot paths (users, sessions, bookings, payments, webhooks, earnings, payouts, chat, notifications).
* **Pagination / keyset discovery** patterns for cleaner discovery (not unbounded full-table UX).
* **Idempotency** on booking create and selected payment/payout flows.
* **Same-slot booking uniqueness** via partial unique reservation index.
* **Webhook event idempotency** for sandbox payment/payout providers (pattern reusable for real providers).

## What does **not** automatically scale

* REST **chat polling** and **notification polling** increase read QPS linearly with active users and poll frequency.
* **Admin list queries** and **reconciliation scans** can become expensive without query discipline and indexes.
* **Audit log** and **earnings ledger** are append-heavy; volume grows with activity.
* **Different-slot availability overlap** is not DB-enforced globally.
* **No distributed rate limiter**, **no cache tier**, **no queue/outbox**, **no background worker pool**.
* **Image/document storage** is largely absent — adding media later needs object storage, not Mongo document bloat.
* **Observability** is minimal (request IDs + container logs); no tracing vendor.

---

## STAGE 1 — Portfolio / early deployment (0–1,000 users)

**Assessment:** Current architecture is **largely sufficient** for demo, coursework, and early private beta **if** production email/payment/payout gaps are accepted or disabled.

**Fit**

* Single API container (or few replicas) behind TLS reverse proxy.
* One Atlas cluster (appropriate tier), index ensure on deploy.
* Flutter release pointing at HTTPS API.
* Sandbox providers remain **off** in `APP_ENV=production`.

**Still required for real users at this stage**

* Real email (verification/reset), or manually provisioned verified users.
* Monitoring/alerting basics and Atlas backups.
* Legal/privacy text and release signing.

**Not required yet**

* Sharding, multi-region, WebSocket chat, warehouse/BI.

---

## STAGE 2 — Growing marketplace (1,000–10,000 users)

**Likely needs**

* Managed container hosting with health/readiness probes (`/api/v1/health`, `/api/v1/ready`).
* Production email + payment (+ payout if offered).
* **Rate limiting** at reverse proxy or API (login, reset request, public discovery).
* Query/performance monitoring (slow query logs, Atlas metrics).
* Formal **backup policy** and restore drills.
* Stronger operational runbooks and on-call lite.
* Review chat/notification poll intervals to protect Atlas read capacity.

**Architecture still viable**

* Stateless API replicas + load balancer + Atlas remains the core shape.

---

## STAGE 3 — Regional scale (10,000–100,000 users)

**Likely needs**

* Multiple stateless API instances behind a load balancer.
* Distributed rate limiting (edge or shared store — **not in repo today**).
* Cache for catalog/discovery hot keys.
* **Queue/outbox** for notifications, email, webhook fan-in, and audit durability.
* Background workers for settlement catch-up and reconciliation jobs.
* Chat transport upgrade (WebSocket/SSE) to reduce polling waste.
* Mongo index/schema tuning; possibly read preference strategy.
* Richer observability (metrics, structured logs, error budgets).

**Honesty:** Moving here without load testing and provider hardening would be premature.

---

## STAGE 4 — Large scale (100,000–1,000,000+)

**Likely needs**

* Partitioning/sharding evaluation (bookings, messages, notifications by time or tenant).
* Multi-region strategy and latency-aware routing.
* Event infrastructure for finance and notifications.
* Data warehousing / BI off the primary OLTP cluster.
* Advanced fraud tooling; capacity and disaster-recovery testing.
* Formal load and chaos testing programs.

**Do not claim** that the current codebase “supports one million users.” Elements are *directionally* horizontal, but **validation is absent**.

---

## Topic notes

| Topic | Current state | Growth note |
| --- | --- | --- |
| Flutter clients | Native Android focus | Store delivery & API latency dominate UX |
| Dart Frog HTTP | Stateless request handlers | Scale out replicas; keep config identical |
| Load balancer | Operator-provided | Terminate TLS; sticky sessions unnecessary for access JWT |
| Atlas indexes | Ensured via tool | Re-verify after restore and major releases |
| Connection pooling | Driver/lifecycle in backend | Watch pool exhaustion under replica fan-out |
| Pagination | Discovery keyset patterns | Keep admin lists bounded |
| Idempotency | Booking/payment/payout/webhooks | Preserve indexes |
| Booking uniqueness | Same-slot partial unique | Overlap across slots still app-level |
| Webhook idempotency | Event id + payload hash | Reuse for real providers |
| Chat | REST polling | Replace before large concurrent messaging |
| Notifications | REST polling / in-app | Queue + push later (push deferred) |
| Audit volume | Append-only best-effort | Retention + export at Stage 2+ |
| Ledger growth | Append-only earnings | Archival strategy at Stage 3+ |
| Admin queries | Direct Mongo reads | Add filters, pagination, async reports |
| Media storage | Absent | Object storage when introduced |
| Rate limiting | Not distributed in-app | Edge limit ASAP for public auth |
| Caching | None | Catalog/discovery first |
| Queues/outbox | None | Needed for reliable side effects at scale |
| Background jobs | None (request-path work) | Settlement/reconcile/email workers |
| Observability | Request ID + logs | Metrics/tracing before Stage 3 |
| Backups | Atlas operator duty | Mandatory with real data |
| Multi-region | Not designed | Stage 4 concern |

---

## Known consistency limitations and mitigations

| Limitation | Why it exists | Mitigation path |
| --- | --- | --- |
| Different-slot availability overlap not covered by one uniqueness constraint | Mongo cannot express arbitrary interval exclusion simply | Keep app checks; consider exclusive booking windows, advisory locks, or redesign slots |
| Notification side effects best-effort | Avoid blocking primary writes on secondary inserts | Outbox + worker; alert on failure metrics |
| Audit side effects best-effort | Same | Outbox; durable audit pipeline |
| Earnings projection not distributed exactly-once | Booking/payment remain source of truth | Reconciliation API; retry settlement; future transactional outbox |
| External provider + Mongo not one distributed transaction | Inherent to payment gateways | Idempotent webhooks; ledger states; manual reconcile |
| Reconciliation detects drift, does not auto-heal | Safety | Admin tools + controlled repair jobs later |
| Chat REST polling | Simplicity for portfolio scope | WebSocket/SSE + push at Stage 3 |
| No distributed task queue/outbox | Scope limit | Introduce before high notification volume |
| No distributed rate limiter | Scope limit | API gateway / edge limits first |

---

## Honesty statement

Horizontal scaling of **stateless API replicas** and **managed MongoDB** is a sound baseline. That is **not** the same as proven capacity at 100k or 1M users. Treat stage tables as engineering planning guidance. Capacity claims require load tests that this repository does not currently include.
