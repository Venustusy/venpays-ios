# API Reference

Source of truth: `Sources/VenPaysApplePay` public declarations (0.1.0).

Availability: **iOS 15+**. Import: `import VenPaysApplePay`.

---

## VenPaysApplePayClient

```swift
@MainActor
public final class VenPaysApplePayClient
```

**Purpose:** Primary entry point for availability checks and Apple Pay presentation/authorization.

**Thread:** Main actor. Call from UI context.

### `init(configuration:)`

- **Parameters:** `configuration` — validated `VenPaysConfiguration`
- **Throws:** none from this convenience init (configuration already validated)
- **Security:** Merchants never pass secret API keys

### `configuration`

Read-only configuration used by networking and recovery.

### `applePayAvailability(for:)`

- **Returns:** `VenPaysApplePayAvailability`
- Distinguishes device support vs configured card vs expired session

### `presentApplePay(session:from:delegate:)`

- **Parameters:** trusted `session`; `presenter` retained for API consistency (PassKit uses `PKPaymentAuthorizationController`); optional `delegate` for authorization lifecycle callbacks
- **Returns:** `VenPaysPaymentResult`
- **Throws:** `VenPaysError` (availability failures, cancellation, network/backend errors)
- **Important:** Call only from a direct user action
- **Warning:** Simulator cannot fully validate Apple Pay authorization

---

## VenPaysApplePayAuthorizationDelegate

```swift
@MainActor
public protocol VenPaysApplePayAuthorizationDelegate: AnyObject
```

**Purpose:** Receives Apple Pay authorization lifecycle events so the integrating app can track and correlate the request with the VenPays transaction.

**Thread:** Main actor. Implementations update UI freely.

### `applePayAuthorizationDidStart(session:)`

Fires after the Apple Pay sheet is presented and visible, before the user authorizes or cancels.

### `applePayAuthorizationRequestWasSent(requestID:session:)`

Fires when the authorize HTTP request is sent to VenPays. The `requestID` is the `X-Request-ID` header value; use it to correlate with VenPays transaction logs and webhook payloads.

**Lifecycle note:** The SDK holds a strong reference to the delegate for the duration of one `presentApplePay` call and releases it when the flow completes.

```swift
final class MyCoordinator: VenPaysApplePayAuthorizationDelegate {
    func applePayAuthorizationDidStart(session: VenPaysNativePaymentSession) {
        analytics.track("applePay.sheetShown", trackID: session.trackID)
    }
    func applePayAuthorizationRequestWasSent(requestID: String, session: VenPaysNativePaymentSession) {
        analytics.track("venpays.authorizeSent", requestID: requestID, trackID: session.trackID)
    }
}
```

---

## VenPaysConfiguration

```swift
public struct VenPaysConfiguration: Sendable, Equatable
```

| Property | Meaning |
|----------|---------|
| `environment` | `.production` or `.custom(URL)` |
| `requestTimeout` | URLSession timeout (> 0) |
| `statusRecoveryPolicy` | Recovery backoff |
| `loggingEnabled` | Diagnostic logging (default `false`) |

**Throws on init:** `invalidConfiguration` for timeout ≤ 0 or non-HTTPS custom URLs (localhost HTTP allowed for tests).

---

## VenPaysEnvironment

| Case | Base URL |
|------|----------|
| `.production` | `https://merchant.venpays.com` |
| `.custom(URL)` | Caller-supplied (tests/overrides) |

No sandbox environment (Apple Pay sandbox unavailable in some regions).

---

## VenPaysNativePaymentSession

Trusted initiation payload. Decode from merchant backend JSON or construct manually.

| Field | Notes |
|-------|-------|
| `trackID` | Payment track identifier |
| `nativeSessionToken` | Bearer token — **never log** |
| `expiresAt` | Must be in the future at construction |
| `amount` / `currency` | Server source of truth |
| `merchantReference` | Optional |
| `applePay` | PassKit configuration |

**Throws:** `invalidSession`, `sessionExpired`, `invalidAmount`, `unsupportedCurrency`, Apple Pay config errors.

**Security:** `description` / `debugDescription` redact the session token.

---

## VenPaysApplePayConfiguration

Merchant identifier, display name, country/currency codes, networks, capabilities from VenPays initiation.

---

## VenPaysApplePayAvailability

| Case | Meaning |
|------|---------|
| `.available` | Can present Apple Pay for session |
| `.supportedButNoConfiguredCard` | Device OK; no matching card |
| `.unsupportedDevice` | Cannot make payments |
| `.invalidMerchantConfiguration` | Networks/config unusable |
| `.sessionExpired` | Token window elapsed |

---

## VenPaysPaymentStatus / VenPaysPaymentResult

Statuses: `processing`, `succeeded`, `failed`, `cancelled`, `unknown`.

`unknown` and non-final `processing` require merchant-backend reconciliation using `trackID`.

---

## VenPaysError / VenPaysErrorCode

Switch on `code`, not message text. See [ErrorReference.md](ErrorReference.md).

`isRetryable` indicates transport/application retry may help; prefer status recovery after uncertain authorize.

---

## PaymentRecoveryPolicy

Exponential backoff for status polling (defaults: 0.5s → max 4s, ×2, 5 attempts, 15s overall). Set `jitterFraction` to `0` in unit tests.

---

## ApplePayButton / SwiftUIApplePayButton

Official `PKPaymentButton` wrappers only (never fake buttons).

Set `isPaymentInProgress` to block duplicate taps while a payment runs.

**MainActor:** `ApplePayButton` is `@MainActor`.

---

## ApplePayButtonType / ApplePayButtonStyle

Maps to PassKit button types/styles. `.pay` maps to PassKit `.checkout` (no dedicated `.pay` type).

---

## Minimal UIKit example

```swift
let client = VenPaysApplePayClient(
    configuration: try VenPaysConfiguration(environment: .production)
)
let session = try JSONDecoder().decode(VenPaysNativePaymentSession.self, from: data)
let result = try await client.presentApplePay(session: session, from: self)
```
