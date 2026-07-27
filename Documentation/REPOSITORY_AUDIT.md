# Repository Audit — VenPaysApplePay

**Audit date:** 2026-07-27  
**SDK version:** 0.1.0  
**HEAD (at audit start):** `698991e`  
**Classification:** IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED

## Current repository structure

```
Package.swift
LICENSE
README.md
CHANGELOG.md
Sources/VenPaysApplePay/          # library target (iOS 15+)
Tests/VenPaysApplePayTests/       # Swift Testing + MockURLProtocol
Documentation/                    # merchant & release docs
Example/                          # Swift source (no .xcodeproj)
.swiftpm/                         # local SPM / shared scheme
```

No `.github/` workflows or templates existed at audit start. No Git tags existed.

## Public SDK symbols

| Symbol | Kind | Notes |
|--------|------|-------|
| `VenPaysApplePayClient` | class `@MainActor` | Entry point |
| `VenPaysConfiguration` | struct | Throws on invalid URL/timeout |
| `VenPaysEnvironment` | enum | `.production`, `.custom(URL)` (sandbox removed) |
| `VenPaysNativePaymentSession` | struct | Trusted session; token redacted |
| `VenPaysApplePayConfiguration` | struct | PassKit mapping inputs |
| `VenPaysApplePayAvailability` | enum | Availability result |
| `VenPaysPaymentStatus` | enum | processing/succeeded/failed/cancelled/unknown |
| `VenPaysPaymentResult` | struct | Payment outcome |
| `VenPaysPaymentMethod` | struct | Optional method metadata |
| `VenPaysBackendErrorDetail` | struct | Nested backend error |
| `VenPaysError` | struct | Stable public error |
| `VenPaysErrorCode` | enum | Stable codes |
| `PaymentRecoveryPolicy` | struct | Backoff policy |
| `ApplePayButton` | class `@MainActor` | UIKit `PKPaymentButton` wrapper |
| `SwiftUIApplePayButton` | struct | SwiftUI representable |
| `ApplePayButtonType` | enum | Official button types |
| `ApplePayButtonStyle` | enum | Official button styles |

## Test structure

- Swift Testing suites: Configuration, SessionValidation, ApplePayAvailability, PaymentRequestFactory, ApplePayTokenEncoder, BackendErrorMapper, Networking (APIClient + RecoveryService serialized)
- MockURLProtocol for URLSession
- Prior validated count: **44 tests / 9 suites** (local iOS Simulator)

## Existing documentation

| File | Status |
|------|--------|
| README.md | Present; needs professional sections / placeholder remote URL |
| CHANGELOG.md | `[0.1.0] - Unreleased` |
| IntegrationGuide.md | Present |
| BackendIntegration.md | Present; production host `https://merchant.venpays.com` |
| ApplePaySetup.md | Present |
| ErrorReference.md | Present |
| TestingGuide.md | Present; physical/sandbox checklists pending |
| Troubleshooting.md | Present |
| ReleaseChecklist.md | Present; needs expansion |
| IMPLEMENTATION_LOG.md | Present |
| APIReference.md | **Missing** |
| SecurityModel.md | **Missing** |
| Operational policies | **Missing** |
| CI docs | **Missing** |
| Release validation report | **Missing** |

## Build commands (validated previously)

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -scheme VenPaysApplePay -destination 'platform=iOS Simulator,id=<id>' test
```

Host `swift build` without Xcode DEVELOPER_DIR fails (UIKit). Destination **My Mac** fails with UIKit resolution error (iOS-only package).

## Existing release files

- CHANGELOG.md
- ReleaseChecklist.md
- LICENSE (MIT)
- No tags, no GitHub Release, no prepare-release script

## Missing professional controls (pre-this work)

- CI workflow
- PR / issue templates
- CODEOWNERS / CONTRIBUTING / CODE_OF_CONDUCT
- Security model document
- API reference document
- Incident / support / deprecation / compatibility docs
- Release validation report template
- Release notes template / release.yml
- prepare-release.sh
- DocC catalog
- Complete public Swift doc comments on all public members

## Duplicated or contradictory documentation

- README previously used generic package naming; canonical private remote is `https://github.com/Venustusy/venpays-ios`.
- TestingGuide still discusses Apple sandbox tester cards; region may lack Apple Pay sandbox — keep as optional/regional guidance, do not claim it is available everywhere.
- Some docs historically mentioned sandbox API hosts; production-only environment is now source of truth (`https://merchant.venpays.com`).

## Stale placeholders

- Example merchant backend: `https://merchant.example.com/api/payments/apple-pay/session` (intentionally fake)
- GitHub team `@Venustusy/ios-sdk-maintainers` must exist under the org for CODEOWNERS enforcement
- Support / security mailboxes are internal VenPays contacts (`support@venpays.com`, `security@venpays.com`)

## Remote ownership

- Organization: https://github.com/Venustusy
- Repository: https://github.com/Venustusy/venpays-ios (private)
- Not open source; no public redistribution

## Undocumented public APIs

Partial `///` comments existed on many types; several properties, enum cases, and initializers lacked full Parameters/Throws/Important documentation suitable for DocC.

## Unsupported claims (must not appear)

- Production-ready
- Physical-device validation completed
- MPGS sandbox E2E completed
- Backend native routes confirmed deployed
- Unauthenticated status endpoint fixed
- Security review approved

## Current release blockers

1. Physical Apple Pay device validation not performed
2. VenPays backend native routes deployment not evidenced in this repo
3. MPGS end-to-end payment not evidenced
4. Webhook validation not evidenced
5. Unauthenticated `POST /merchant/payment-status-by-track-id` security prerequisite not confirmed resolved
6. Sensitive log review on device/backend not evidenced
7. Pilot merchant integration not evidenced
8. Private Git remote configured (`Venustusy/venpays-ios`); enable branch protection and ensure GitHub team `ios-sdk-maintainers` exists for CODEOWNERS
9. No CI green run on a published remote yet
