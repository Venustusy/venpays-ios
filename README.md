# VenPays Apple Pay SDK

Native iOS Apple Pay SDK for VenPays.

**Repository (private):** [Venustusy/venpays-ios](https://github.com/Venustusy/venpays-ios)  
**Organization:** [Venustusy](https://github.com/Venustusy)

**CI status:** ![iOS SDK](https://github.com/Venustusy/venpays-ios/actions/workflows/ios-sdk.yml/badge.svg)

> This repository is **private** to the Venustusy organization. It is not open source and must not be redistributed or forked publicly.

## Overview

VenPaysApplePay is a Swift Package that presents Apple Pay via PassKit, authorizes the Apple payment token with VenPays native APIs, and recovers payment status when authorization is processing or network outcome is uncertain.

The SDK never calls merchant initiation with `X-API-KEY`. Amount and currency always come from a trusted backend session.

## Current Status

**IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED**

| Gate | Status |
|------|--------|
| Local generic iOS build | Passes (when validated) |
| Automated unit / networking tests | Passes (when validated) |
| Physical-device Apple Pay testing | **Still required** |
| VenPays / processor end-to-end testing | **Still required** |
| Backend native routes deployed | **Must be confirmed operationally** |
| Production approval | **Not granted** |

This package is **not** production-approved.

## Requirements

- iOS 15.0+
- Swift tools 6.0+ / Swift 6 language mode
- Xcode with iOS SDK (locally validated with **Xcode 26.6** / Apple Swift **6.3.3** on this engineering machine; other versions are unclaimed)
- Apple Pay–capable **physical** device for real validation (Simulator is insufficient for authorization)
- Apple Developer Merchant ID + Apple Pay capability
- Merchant backend that initiates payments server-to-server
- VenPays native Apple Pay APIs (authorize + authenticated status)

### Xcode destination

This package is **iOS-only**. Building for **My Mac** fails with `Unable to resolve module dependency: 'UIKit'`. Select an iPhone/iPad simulator or iOS device.

## Architecture

```
Merchant iOS App
    ->
Merchant Backend
    ->
VenPays POST /merchant/initiate-payment   (X-API-KEY, server-to-server only)
    ->
Merchant Backend returns native session
    ->
VenPays Apple Pay SDK
    ->
Apple Pay Sheet (PassKit)
    ->
VenPays Authorize API
    ->
MPGS
    ->
Webhook / status recovery
```

## Installation

Access requires Venustusy organization membership (or an approved collaborator seat on this private repo).

### Local package

In Xcode: **File → Add Package Dependencies… → Add Local…** → select this repository root.

### Remote Git package (private)

```
https://github.com/Venustusy/venpays-ios
```

SSH (recommended for CI / local clones):

```
git@github.com:Venustusy/venpays-ios.git
```

```swift
dependencies: [
    .package(
        url: "https://github.com/Venustusy/venpays-ios.git",
        from: "0.1.0"
    )
]
```

Xcode will prompt for GitHub credentials with access to the private Venustusy repository.

## Basic Usage

```swift
import VenPaysApplePay
import UIKit

@MainActor
func pay(from viewController: UIViewController, initiationData: Data) async {
    do {
        let configuration = try VenPaysConfiguration(environment: .production)
        let client = VenPaysApplePayClient(configuration: configuration)

        let session = try JSONDecoder().decode(
            VenPaysNativePaymentSession.self,
            from: initiationData
        )

        switch client.applePayAvailability(for: session) {
        case .available:
            break
        case .supportedButNoConfiguredCard:
            return // prompt user to add a card
        case .unsupportedDevice, .invalidMerchantConfiguration, .sessionExpired:
            return
        }

        let result = try await client.presentApplePay(
            session: session,
            from: viewController
        )

        switch result.status {
        case .succeeded:
            break
        case .failed, .cancelled:
            break
        case .processing, .unknown:
            // Reconcile with merchant backend using trackID
            break
        }
    } catch let error as VenPaysError where error.code == .paymentCancelled {
        // User dismissed the Apple Pay sheet
    } catch {
        // Handle VenPaysError.code
    }
}
```

## Merchant Backend Requirement

**The merchant `X-API-KEY` must never be embedded in the iOS application or this SDK.**

Only the merchant backend may call `POST /merchant/initiate-payment`. The app receives the native initiation payload and constructs / decodes `VenPaysNativePaymentSession`.

## Apple Pay Setup

See [Documentation/ApplePaySetup.md](Documentation/ApplePaySetup.md).

## Error Handling

See [Documentation/ErrorReference.md](Documentation/ErrorReference.md) and [Documentation/APIReference.md](Documentation/APIReference.md).

## Security

See [Documentation/SecurityModel.md](Documentation/SecurityModel.md).

## Testing

See [Documentation/TestingGuide.md](Documentation/TestingGuide.md) and [Documentation/ReleaseValidationReportTemplate.md](Documentation/ReleaseValidationReportTemplate.md).

CI details: [Documentation/CI.md](Documentation/CI.md).

## Versioning

Semantic versioning. Current version: **0.1.0** (Unreleased / pre-RC validation).

Do not treat `0.1.0` as production. A `1.0.0` bump requires completed device, backend, and security gates.

## Support

Internal contact: `support@venpays.com` (Venustusy / VenPays)

Security reports: `security@venpays.com` — see [CONTRIBUTING.md](CONTRIBUTING.md). Do not file secrets in issues.

## License

MIT — see [LICENSE](LICENSE).
