# Changelog

All notable changes to VenPaysApplePay are documented in this file.

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
