# Deployment Architecture

**Project:** Home Cleaning Service Marketplace  
**Versions:** Flutter `1.0.0+1`, backend `1.0.0+1`  
**Stance:** Target-neutral — examples may mention cloud vendors; the design does not require a specific one

## Target shape

```text
Flutter Android App
  applicationId: com.homecleaningmarketplace.app
  API_BASE_URL: https://api.example.com   (dart-define; public)
        |
      HTTPS
        |
TLS termination / Reverse Proxy / Managed Load Balancer
  (certificates, HSTS, optional WAF / edge rate limits)
        |
Dart Frog API Containers
  image from backend/Dockerfile
  PORT=8080
  env: APP_ENV=production, MONGODB_URI, ACCESS_TOKEN_SECRET,
       ALLOWED_ORIGINS, PLATFORM_COMMISSION_BPS, ...
  probes: GET /api/v1/health  (liveness)
          GET /api/v1/ready   (Mongo readiness)
        |
MongoDB Atlas
  indexes ensured via controlled job:
  dart run tool/ensure_database_indexes.dart
```

## External providers (future)

```text
Email provider     → AccountActionDeliveryProvider (not production-integrated)
Payment provider   → PaymentProvider (sandbox only today in development/test)
Payout provider    → PayoutProvider (sandbox only today in development/test)
```

In `APP_ENV=production`, sandbox payment/payout and development account-action delivery are **not** constructed. APIs must fail safe with provider/delivery unavailable — not fall back to sandbox.

## Trust boundaries

| Component | Holds secrets? | Notes |
| --- | --- | --- |
| Flutter app | No backend secrets | `API_BASE_URL` is public and extractable |
| Reverse proxy | TLS private keys | Operator managed |
| API containers | Runtime env secrets | Injected at start; never baked into image |
| Atlas | DB credentials | URI only on backend |
| CI | None of production | Analyze/test/debug APK only |

## Scaling sketch

* Add API replicas behind the load balancer (stateless HTTP).
* Keep session/refresh state in MongoDB.
* Scale Atlas tier independently.
* Chat/notification polling and missing queue/cache become limiting factors before “infinite” horizontal scale — see [scalability-and-growth-review.md](../architecture/scalability-and-growth-review.md).

## What this repository does not deploy

* No mandatory AWS/GCP/Azure modules
* No Kubernetes manifests or Terraform
* No automatic cloud deploy from CI
* No production provider account provisioning

Operators choose hosting; this repo supplies the container, config rules, Android release identity, and runbooks.

## Related runbooks

* [backend-container-runbook.md](backend-container-runbook.md)
* [android-release-runbook.md](android-release-runbook.md)
* [environment-reference.md](environment-reference.md)
* [operations-runbook.md](operations-runbook.md)
