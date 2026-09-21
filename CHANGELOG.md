# Changelog

All notable changes to VenPaysApplePay are documented in this file.

## [0.1.1] - 2026-09-21

### Added

- `userCancelledBeforeAuthorization` cancellation classification — the user closed the Apple Pay
  sheet before any authorize request was dispatched. No charge is possible and an immediate retry
  is safe.
- `networkRequestCancelled` cancellation classification — an in-flight authorize/status request was
  cancelled after authorization may have reached VenPay. The SDK first reconciles via status
  recovery; when the outcome cannot be confirmed it surfaces this code so merchants reconcile by
  `trackID` instead of treating the attempt as a definitive user cancellation.
- Cancellation classification tests covering error-code mapping for `URLError.cancelled`,
  token-task cancellation, transport retry reuse, and status-recovery behavior.

### Changed

- `paymentCancelled` is deprecated in favor of the two specific codes above and is no longer emitted.
- Authorization lifecycle delegate now clearly separates the two cancellation situations; merchants
  can distinguish them with `VenPaysError.code`.
- SDK version bumped to `0.1.1`.

## [Unreleased]

### Added

- Authorization lifecycle delegate (`VenPaysApplePayAuthorizationDelegate`) exposing:
  - `applePayAuthorizationDidStart(session:)` when the Apple Pay sheet appears
  - `applePayAuthorizationRequestWasSent(requestID:session:)` when the authorize request is dispatched, including the `X-Request-ID` for transaction correlation

## [0.1.0-rc.1] - 2026-08-06

### Added

- Native Apple Pay availability checks
- UIKit and SwiftUI Apple Pay buttons
- Native Apple Pay sheet presentation
- VenPays authorization API integration
- Idempotent payment submission
- Payment status recovery
- Structured error handling
- Merchant integration documentation
- Automated build and test pipeline

### Validation status

- Generic iOS build passed
- Automated tests passed
- Physical Apple Pay token generation confirmed
- Successful processor authorization remains pending
- Initial configuration targets Bahrain
- Global market validation has not been completed

### Notes

- Native flow is JSON-only; `success_url` / `fail_url` on initiation do not control iOS navigation
- Default production base URL is `https://merchant.venpays.com`
- Use `.custom(URL)` only for tests or temporary overrides
- This release candidate is for controlled merchant integration and pilot validation — not unrestricted production deployment

**Classification:** IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED

## [0.1.0] - Unreleased

Stable `0.1.0` notes will replace this section when GA is cut from the RC line.
