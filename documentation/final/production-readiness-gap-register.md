# Production Readiness Gap Register

**Project:** Home Cleaning Service Marketplace  
**Versions:** Flutter `1.0.0+1`, backend `1.0.0+1`  
**Purpose:** Honest backlog separating **software release** gaps from **production service** gaps

Priorities:

* **P0** — required before real production users / real money
* **P1** — strongly recommended shortly after (or before public marketing scale)
* **P2** — scale and operational excellence

Statuses: `Open` · `Mitigated in software` · `Accepted for portfolio demo`

---

## P0 — before real production users

| ID | Gap | Why P0 | Current mitigation | Status |
| --- | --- | --- | --- | --- |
| P0-01 | Real email delivery | Verification and password reset cannot complete for real users without SMTP/ESP | Dev/test delivery only; production delivery unavailable (no raw-token fallback) | Open |
| P0-02 | Real payment provider | Customers cannot be charged; refunds are not real money movement | Sandbox only in development/test; production `payment_provider_unavailable` | Open |
| P0-03 | Real payout provider (if payouts launch) | Cleaners cannot receive funds | Sandbox only in development/test; production `payout_provider_unavailable` | Open — or disable payouts at launch |
| P0-04 | Legal / privacy / terms | Real users need ToS, privacy policy, payment disclosures | Not productized in-app as counsel-approved content | Open |
| P0-05 | Production domain + TLS | Release app requires HTTPS API | Flutter release validates `https://`; TLS termination is operator-owned | Open (ops) |
| P0-06 | Production secrets manager | Secrets must not live in images/git/chat | Runtime env injection; `.env` gitignored; validation at boot | Mitigated in software / ops still Open |
| P0-07 | Release signing key | Play distribution needs real keystore | External `key.properties`; debug signing fallback for local only | Open for store release |
| P0-08 | Atlas backup policy | Data loss risk | Documented; not automated by repo | Open |
| P0-09 | Monitoring / alerting | Outages and 5xx invisible otherwise | Health/ready endpoints only | Open |
| P0-10 | Privacy / security review | Real PII and future payments | Internal TASK 022 audit only — not a pentest | Open |
| P0-11 | Production environment validation | Misconfig must fail closed | `validateServerConfig` for production boot | Mitigated in software |
| P0-12 | Incident response basics | Credential leak / Atlas outage | Session revoke + runbooks documented | Open (people/process) |

---

## P1 — strongly recommended next

| ID | Gap | Notes | Status |
| --- | --- | --- | --- |
| P1-01 | Distributed / edge rate limiting | Protect login, reset, discovery abuse | Open |
| P1-02 | Background jobs / outbox | Harden notifications, email, audit, settlement side effects | Open |
| P1-03 | WebSocket/SSE chat | Reduce polling load; better UX | Open / Deferred product |
| P1-04 | Crash reporting | Mobile failure visibility | Open (SDK deferred by task policy) |
| P1-05 | Audit retention / export | Compliance and forensics | Open |
| P1-06 | Support tooling | Customer support beyond raw admin screens | Open |
| P1-07 | Automated DB migration process | Beyond index ensure script | Partial (indexes tool exists) |
| P1-08 | Load testing | Required before Stage 3 claims | Open |
| P1-09 | Structured logging + log shipping | Request ID exists; pipeline does not | Open |
| P1-10 | Admin account hardening | MFA / break-glass (MFA deferred in product) | Open |

---

## P2 — scale / polish

| ID | Gap | Notes | Status |
| --- | --- | --- | --- |
| P2-01 | Cache tier | Catalog/discovery | Open |
| P2-02 | Multi-region | Latency and DR | Open |
| P2-03 | Warehouse / BI | Offload analytics from OLTP | Open |
| P2-04 | Advanced fraud tooling | Reviews, payments, promo abuse | Open |
| P2-05 | Localization | i18n beyond English baseline | Open |
| P2-06 | Accessibility device lab | Beyond automated text-scale pumps | Open |
| P2-07 | Disaster-recovery automation | Beyond manual Atlas restore drills | Open |
| P2-08 | Push notifications | Deferred by product scope | Open / Deferred |
| P2-09 | Media object storage | When images/documents added | Open |
| P2-10 | Certificate pinning | Optional mobile hardening | Open |

---

## Accepted for portfolio / software-release demo

These remain **non-production** by design and must stay labeled honestly in UI and docs:

* Development account-action delivery
* Sandbox payment provider + simulate routes
* Sandbox payout provider + simulate routes

Do **not** weaken production unavailable guards to fake a live demo.

---

## Mapping to readiness terms

| Term | Gap register implication |
| --- | --- |
| SOFTWARE RELEASE READY | P0-06/P0-11 largely addressed in code; packaging/CI/docs exist; P0 provider/legal/ops may still be open |
| FULLY PRODUCTION SERVICE READY | Requires closing P0-01..P0-05, P0-07..P0-10, P0-12 (and P0-03 if payouts offered) |

See [project-completion-summary.md](project-completion-summary.md) and [../security/final-security-audit.md](../security/final-security-audit.md).
