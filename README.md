# VenPaysApplePay

Native iOS Apple Pay SDK for VenPays.

**Version:** 0.1.0  
**Status:** Implementation complete — release candidate not yet validated

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 16+
- Physical Apple Pay–capable device for runtime testing

## Installation

Add the package in Xcode:

**File → Add Package Dependencies…**

```
https://github.com/venpays/VenPaysApplePay.git
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/venpays/VenPaysApplePay.git", from: "0.1.0")
]
```

## Quick Start

```swift
import VenPaysApplePay

let client = VenPaysApplePayClient(
    configuration: VenPaysConfiguration(
        environment: .sandbox
    )
)

let session = try VenPaysNativePaymentSession(
    trackID: initiation.trackID,
    nativeSessionToken: initiation.nativeSessionToken,
    expiresAt: initiation.expiresAt,
    amount: initiation.amount,
    currency: initiation.currency,
    merchantReference: initiation.merchantReference,
    applePay: initiation.applePay
)

let availability = client.applePayAvailability(for: session)
guard case .available = availability else { return }

let result = try await client.presentApplePay(
    session: session,
    from: viewController
)
```

## Architecture

```
Merchant app
    → Merchant backend
    → VenPays POST /merchant/initiate-payment  (server-to-server, X-API-KEY)
    → Merchant backend returns native initiation response to app
    → VenPays Apple Pay SDK
    → Apple Pay sheet
    → VenPays authorize API
    → Processor (MPGS)
```

The merchant secret `X-API-KEY` must never enter the iOS app or this SDK.

## Documentation

| Guide | Description |
|-------|-------------|
| [IntegrationGuide.md](Documentation/IntegrationGuide.md) | Merchant app integration |
| [BackendIntegration.md](Documentation/BackendIntegration.md) | Server initiation contract |
| [ApplePaySetup.md](Documentation/ApplePaySetup.md) | Apple Developer / Merchant ID setup |
| [ErrorReference.md](Documentation/ErrorReference.md) | Stable error codes |
| [TestingGuide.md](Documentation/TestingGuide.md) | Simulator limits & device testing |
| [Troubleshooting.md](Documentation/Troubleshooting.md) | Common issues |
| [ReleaseChecklist.md](Documentation/ReleaseChecklist.md) | Release gates |

## Security

- No merchant secret API keys in the SDK
- Native session tokens are never logged or printed
- Apple Pay `paymentData` is never logged
- Amount and currency always come from the backend session

## License

MIT — see [LICENSE](LICENSE).
