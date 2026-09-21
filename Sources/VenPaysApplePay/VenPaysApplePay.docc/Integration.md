# Integration

Integrate VenPaysApplePay using a merchant-backend initiation flow.

## Architecture

1. Merchant app requests a session from the **merchant backend**.
2. Merchant backend calls VenPays `POST /merchant/initiate-payment` with `X-API-KEY`.
3. App decodes ``VenPaysNativePaymentSession``.
4. App checks ``VenPaysApplePayClient/applePayAvailability(for:)``.
5. On user tap, call ``VenPaysApplePayClient/presentApplePay(session:from:delegate:)``.

## Tracking the authorization lifecycle

Pass a ``VenPaysApplePayAuthorizationDelegate`` to receive events when the Apple Pay sheet
appears and when the authorize request is sent to VenPays, including the `requestID`
(`X-Request-ID`) for correlation with VenPays transaction logs and webhooks.

```swift
final class Tracker: VenPaysApplePayAuthorizationDelegate {
    func applePayAuthorizationDidStart(session: VenPaysNativePaymentSession) {
        // Sheet is visible.
    }
    func applePayAuthorizationRequestWasSent(requestID: String, session: VenPaysNativePaymentSession) {
        // Authorize request dispatched; correlate with requestID.
    }
}

let result = try await client.presentApplePay(
    session: session,
    from: presenter,
    delegate: Tracker()
)
```

## Important

- Never embed the merchant `X-API-KEY` in the iOS app.
- Amount and currency are trusted from the session only.
- Call `presentApplePay` only from a direct user action.
- Prefer a physical device for Apple Pay authorization testing.

## See Also

- <doc:Security>
