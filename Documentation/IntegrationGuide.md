# Integration Guide

VenPays Apple Pay SDK for native iOS.

## Architecture

```
Merchant app
    → Merchant backend
    → VenPays POST /merchant/initiate-payment   (X-API-KEY, server-to-server only)
    → Merchant backend returns native initiation response to app
    → VenPays Apple Pay SDK
    → Apple Pay sheet (PassKit)
    → VenPays POST /v1/sdk/apple-pay/payments/{track_id}/authorize
    → Processor (MPGS)
```

**Never** put the merchant secret `X-API-KEY` in the iOS app or this SDK.

## Install

Add the Swift package dependency, then:

```swift
import VenPaysApplePay
```

## 1. Create the client

```swift
let client = VenPaysApplePayClient(
    configuration: try VenPaysConfiguration(
        environment: .production
        // or .custom(URL(string: "https://your-venpays-host")!) for overrides/tests
    )
)
```

No publishable key is required in 0.1.0.

## 2. Obtain a native session from your backend

Your app calls **your** merchant backend. That backend calls VenPays initiation and returns the native initiation payload.

Decode into `VenPaysNativePaymentSession`:

```swift
let session = try JSONDecoder().decode(
    VenPaysNativePaymentSession.self,
    from: responseData
)
```

Or construct manually from fields your backend already decoded.

## 3. Check availability

```swift
switch client.applePayAvailability(for: session) {
case .available:
    break
case .supportedButNoConfiguredCard:
    // Prompt the user to add a card in Wallet
case .unsupportedDevice:
    // Hide Apple Pay
case .invalidMerchantConfiguration:
    // Fix Merchant ID / networks configuration
case .sessionExpired:
    // Re-initiate on your backend
}
```

## 4. Present Apple Pay (UIKit)

Only after a direct user tap on the Apple Pay button:

```swift
let button = ApplePayButton(type: .buy, style: .black)
button.onTap = { [weak self] in
    guard let self else { return }
    button.isPaymentInProgress = true
    Task {
        defer { button.isPaymentInProgress = false }
        do {
            let result = try await client.presentApplePay(
                session: session,
                from: self
            )
            self.handle(result)
        } catch let error as VenPaysError {
            switch error.code {
            case .userCancelledBeforeAuthorization:
                // User dismissed the sheet before any authorization — no charge.
                break
            case .networkRequestCancelled:
                // In-flight request cancelled; authorization may have reached VenPay.
                // Reconcile with your merchant backend before allowing a retry.
                break
            default:
                break
            }
        }
    }
}
```

## 5. SwiftUI

```swift
SwiftUIApplePayButton(type: .buy, style: .automatic, isPaymentInProgress: viewModel.isPaying) {
    Task { await viewModel.pay(from: presenter) }
}
```

Obtain a `UIViewController` presenter from the SwiftUI hierarchy (e.g. via `UIViewController` resolver) when calling `presentApplePay`.

## 6. Track the authorization lifecycle

Pass an `VenPaysApplePayAuthorizationDelegate` to `presentApplePay` to observe the authorization lifecycle and correlate with the VenPays transaction:

```swift
final class PaymentLifecycleTracker: VenPaysApplePayAuthorizationDelegate {
    func applePayAuthorizationDidStart(session: VenPaysNativePaymentSession) {
        analytics.track("applePay.sheetShown", trackID: session.trackID)
    }

    func applePayAuthorizationRequestWasSent(requestID: String, session: VenPaysNativePaymentSession) {
        // requestID matches the VenPays X-Request-ID header for this authorize call.
        analytics.track("venpays.authorizeSent", requestID: requestID, trackID: session.trackID)
    }
}

let tracker = PaymentLifecycleTracker()
let result = try await client.presentApplePay(
    session: session,
    from: self,
    delegate: tracker
)
```

The delegate is retained for the duration of the call and released when the flow completes.

## Handling results

| Status | Meaning |
|--------|---------|
| `succeeded` | Payment completed |
| `failed` | Payment failed / declined |
| `cancelled` | Cancelled |
| `processing` | Accepted; SDK may still be recovering |
| `unknown` | Recovery exhausted; reconcile with your backend using `trackID` |

The Apple Pay sheet UI and Cancel button are controlled by Apple. The SDK does not hide or modify them.

## Cancellation

The SDK separates the two situations that older versions conflated as `paymentCancelled`:

- `userCancelledBeforeAuthorization` — the user closed the Apple Pay sheet before any authorize request
  was dispatched. No charge is possible; retry immediately if desired.
- `networkRequestCancelled` — an in-flight authorize/status request was cancelled. The authorization
  may have reached VenPay, so reconcile with your merchant backend using `trackID` before retrying.

## Security notes

- Amount and currency always come from the trusted session.
- Do not override merchant identifier, networks, or summary totals.
- Tokens and Apple Pay `paymentData` are never logged by the SDK.
