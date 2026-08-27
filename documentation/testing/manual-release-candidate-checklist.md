# Manual release-candidate checklist

Practical checkbox list for a release-candidate pass. Use development/test backends and sandbox adapters only. Do **not** record real credentials, Atlas URIs, or production secrets in this file.

## ENVIRONMENT

- [ ] backend configuration available (local Dart Frog + env for development/test)
- [ ] Flutter `API_BASE_URL` configured for the local/dev API
- [ ] no secrets in Flutter (no MongoDB URI, no `ACCESS_TOKEN_SECRET`, no provider keys)

## AUTH

- [ ] signup
- [ ] verify
- [ ] login
- [ ] forgot/reset
- [ ] change password
- [ ] sessions
- [ ] logout

## CUSTOMER

- [ ] profile/address
- [ ] discovery
- [ ] booking
- [ ] payment sandbox
- [ ] chat
- [ ] notifications
- [ ] review
- [ ] dispute

## CLEANER

- [ ] onboarding
- [ ] services
- [ ] availability
- [ ] booking lifecycle
- [ ] chat
- [ ] earnings
- [ ] payout sandbox
- [ ] reviews
- [ ] dispute

## ADMIN

- [ ] approval
- [ ] users
- [ ] bookings
- [ ] payments/refund
- [ ] disputes
- [ ] reviews
- [ ] payouts
- [ ] finance
- [ ] audit

## UX

- [ ] empty
- [ ] loading
- [ ] error
- [ ] small screen
- [ ] large text
- [ ] wide layout
- [ ] destructive confirmations

## SECURITY

- [ ] role guards
- [ ] session revoke
- [ ] no raw server errors
- [ ] sandbox clearly labeled
