# Changelog

All notable changes to VenPaysApplePay are documented in this file.

## [0.1.0] - Unreleased

Initial Swift Package implementation of the VenPays native iOS Apple Pay SDK.

### Added

- Initial Swift Package (`VenPaysApplePay`) for iOS 15+
- Apple Pay availability checks (device support vs configured card)
- Native Apple Pay payment sheet via `PKPaymentAuthorizationController`
- VenPays authorize API integration with Bearer native session tokens
- Idempotent authorization with transport-retry key reuse
- Payment status recovery with exponential backoff
- UIKit `ApplePayButton` wrapper around `PKPaymentButton`
- SwiftUI `SwiftUIApplePayButton` adapter
- Stable `VenPaysError` / `VenPaysErrorCode` model
- Unit and networking tests with `MockURLProtocol`
- Merchant documentation and example application source

### Notes

- Physical-device Apple Pay testing is **pending**
- Sandbox end-to-end testing is **pending**
- Default production base URL is `https://merchant.venpays.com` (no separate sandbox environment; Apple Pay sandbox is unavailable in some regions)
- Use `.custom(URL)` only for tests or temporary overrides
- This release is **not** marked 1.0.0 and is **not** claimed production-ready

**Classification:** IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED
