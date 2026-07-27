# Compatibility Matrix

Evidence-based compatibility for VenPaysApplePay **0.1.0**.

Do not claim untested toolchains.

| Area | Support | Evidence |
|------|---------|----------|
| Minimum iOS | **15.0** | `Package.swift` `platforms: [.iOS(.v15)]` |
| Swift tools | **6.0** | `// swift-tools-version: 6.0` |
| Swift language mode | **v6** | `swiftLanguageModes: [.v6]` |
| UIKit | Required | Public `ApplePayButton`, `presentApplePay` |
| SwiftUI | Supported | `SwiftUIApplePayButton` |
| PassKit | Required | Payment sheet + button |
| Third-party deps | None | Package has no external products |
| Physical device for Apple Pay auth | **Required** | PassKit / TestingGuide |
| iOS Simulator | Limited UI-only | Cannot claim full authorization validation |
| VenPays API host | `https://merchant.venpays.com` | `VenPaysEnvironment.production` |
| Sandbox environment case | **Removed** | Regional Apple Pay sandbox limitations |
| Backend contract | Native authorize + Bearer status | Docs; gateway branch historically `feat/native-apple-pay-sdk-api` |
| MPGS | Via VenPays gateway only | SDK never calls MPGS |

## Locally validated toolchain (engineering machine)

Recorded during release preparation on this workstation:

| Tool | Version |
|------|---------|
| Xcode | 26.6 (Build 17F113) |
| Swift | Apple Swift 6.3.3 |
| Host macOS | darwin 25.x (from environment) |

Other Xcode / iOS combinations are **unclaimed** until listed here with evidence.

## Backend dependency

SDK authorize:

`POST /v1/sdk/apple-pay/payments/{track_id}/authorize`

SDK status:

`GET /v1/sdk/apple-pay/payments/{track_id}`

Merchant initiation remains server-to-server and outside the SDK.
