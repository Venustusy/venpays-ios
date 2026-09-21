# Integrate Native Apple Pay (iOS)

Public merchant guide for VenPaysApplePay — the native iOS Apple Pay SDK.

Use this document when publishing integration docs for merchants. It covers setup, backend initiation, app integration, results, security, testing, and regional availability.

**Current package candidate:** `0.1.0-rc.1`  
**API base URL:** `https://merchant.venpays.com`  
**Classification:** Controlled pilot / RC — not globally certified for unrestricted production

---

## 1. Overview

VenPaysApplePay presents Apple Pay with PassKit, sends the Apple payment token to VenPays for authorization, and returns a structured payment result to your app.

### What the SDK does

- Checks Apple Pay availability for the trusted session
- Presents the Apple Pay sheet after a user tap
- Authorizes with VenPays using a native session Bearer token
- Recovers payment status when authorization is processing or uncertain

### What the SDK does not do

- Call `POST /merchant/initiate-payment` (that is server-to-server only)
- Accept a merchant `X-API-KEY` on the device
- Open browser redirect URLs (`success_url` / `fail_url`)
- Override amount, currency, Merchant ID, or summary totals from the app
- Create fake Apple Pay buttons or modify Apple’s sheet Cancel button
- Call Apple web merchant-validation APIs or use `initiativeContext`

### Requirements

- iOS 15.0+
- Xcode with an iOS SDK (this package is **iOS-only**; do not build for My Mac)
- Apple Pay–capable **physical** device for real authorization
- Apple Developer Merchant ID + Apple Pay capability on the app
- Merchant backend that initiates payments with VenPays
- VenPays native Apple Pay APIs enabled for your merchant

---

## 2. Architecture

```
Merchant iOS app
    → Merchant backend
    → VenPays POST /merchant/initiate-payment   (X-API-KEY, server-to-server only)
    → Merchant backend returns native session JSON to the app
    → VenPaysApplePay SDK
    → Apple Pay sheet (PassKit)
    → VenPays POST /v1/sdk/apple-pay/payments/{track_id}/authorize
    → Processor
    → Optional GET status recovery while the native session is valid
    → App receives VenPaysPaymentResult or VenPaysError
    → Merchant backend receives webhooks / reconciles by track_id
```

**Return to the app:** There is no redirect. The Apple Pay sheet is presented in-process. When the sheet finishes, `presentApplePay` completes with a result or error. Your app updates UI from that outcome. Order fulfillment should still rely on your backend and VenPays webhooks.

**About `success_url` / `fail_url`:** These optional initiation fields are for web/redirect flows. They are accepted by VenPays initiation but **do not control native iOS navigation**. The iOS SDK ignores them.

---

## 3. Regional availability

VenPaysApplePay is distributed as a reusable iOS SDK.

Apple Pay payment availability depends on:

- Apple Pay availability in the merchant's country or region
- participating card issuers and networks
- merchant Apple Developer configuration
- Apple Pay entitlement and Merchant ID configuration
- Payment Processing certificate configuration
- VenPays and acquiring-bank activation
- processor support for the transaction currency and card network

The current release has been designed and initially tested against Bahrain merchant configuration using BHD, Visa, Mastercard, and 3-D Secure. Other markets require validation before production use.

---

## 4. Apple Developer and app setup

### Apple Developer

1. Enroll in the Apple Developer Program.
2. Create an **Apple Pay Merchant ID**.
3. Create a **Payment Processing Certificate** and configure it per VenPays / processor guidance.
4. Enable the **Apple Pay** capability on the iOS App ID.
5. Regenerate provisioning profiles after enabling the capability.

### Xcode project

1. Signing & Capabilities → add **Apple Pay**.
2. Select the Merchant ID that matches `apple_pay.merchant_identifier` from VenPays initiation.
3. Ensure Bundle ID and Team match the App ID with Apple Pay enabled.

The host merchant app configures its own:

- Apple Developer Team
- Bundle ID
- Apple Pay capability
- Merchant ID
- Provisioning profile

The SDK package does not change those settings.

### Device requirements

- Physical iPhone with Apple Pay support
- Region and card support for your networks (for example Visa / Mastercard)
- Face ID / Touch ID / passcode configured

### Simulator

The iOS Simulator cannot fully validate Apple Pay authorization. Treat simulator checks as UI-only. Full payment flows require a physical device.

---

## 5. Installation

Add the VenPays private Swift package (organization access required).

### Xcode

1. **File → Add Package Dependencies…**
2. Paste the VenPays iOS repository URL
3. Choose **Up to Next Minor Version** or **Exact**
4. Select **0.1.0-rc.1**

### Package.swift

```swift
dependencies: [
    .package(
        url: "https://github.com/Venustusy/venpays-ios.git",
        exact: "0.1.0-rc.1"
    )
]
```

Then:

```swift
import VenPaysApplePay
```

---

## 6. Backend integration

### Server-to-server initiation

Only your merchant backend may call:

```
POST /merchant/initiate-payment
X-API-KEY: <merchant-secret-key>
Content-Type: application/json
```

**Never** put the merchant secret `X-API-KEY` in the iOS application or the SDK.

### Example request

```json
{
  "amount": 10.000,
  "currency": "BHD",
  "payment_provider": "apple-pay",
  "integration_type": "native_ios",
  "merchant_reference": "optional-reference",
  "payment_method": "apple_pay",
  "additional_data": {}
}
```

Optional web-only fields such as `success_url` and `fail_url` may be accepted by VenPays but do not drive native iOS navigation.

### Native initiation response (returned to the iOS app)

Your backend returns this payload (or an equivalent) to the app. The app never calls initiation directly.

```json
{
  "track_id": "11111111-2222-3333-4444-555555555555",
  "native_session_token": "<opaque-token>",
  "expires_at": "2026-07-26T12:00:00.000Z",
  "amount": "10.000",
  "currency": "BHD",
  "merchant_reference": "optional-reference",
  "apple_pay": {
    "merchant_identifier": "merchant.com.example",
    "merchant_display_name": "Example Merchant",
    "country_code": "BH",
    "currency_code": "BHD",
    "supported_networks": ["visa", "masterCard"],
    "merchant_capabilities": ["threeDSecure"]
  },
  "success": true
}
```

### Amount and currency source of truth

The backend session amount and currency are authoritative. The SDK builds exactly one final Apple Pay summary item:

- label = `apple_pay.merchant_display_name`
- amount = top-level `amount`
- type = final

### What the SDK calls after Apple Pay authorization

```
POST /v1/sdk/apple-pay/payments/{track_id}/authorize
Authorization: Bearer <native_session_token>
Idempotency-Key: <uuid>
X-Request-ID: <uuid>
Content-Type: application/json
```

`payment_data` is the decoded JSON object from `PKPayment.token.paymentData` (not a base64 blob of the whole token).

- HTTP **200** — completed result body
- HTTP **202** — processing; SDK recovers via status

```
GET /v1/sdk/apple-pay/payments/{track_id}
Authorization: Bearer <native_session_token>
X-Request-ID: <uuid>
```

Native session tokens typically expire after about **900 seconds**. Status recovery only works while the token is valid.

Do **not** use `/merchant/payment-status-by-track-id` from the iOS app or SDK.

### Environments

- Production SDK base URL: `https://merchant.venpays.com`
- There is no separate sandbox environment option in this SDK build (Apple Pay sandbox may be unavailable in some regions)
- Use a custom base URL only for approved tests or temporary overrides

---

## 7. iOS integration

### 1. Create the client

```swift
let client = VenPaysApplePayClient(
    configuration: try VenPaysConfiguration(
        environment: .production
        // loggingEnabled: true  // optional diagnostics; never logs tokens
    )
)
```

No publishable key is required.

### 2. Obtain a native session from your backend

Your app calls **your** merchant backend. That backend calls VenPays initiation and returns the native initiation payload.

```swift
let session = try JSONDecoder().decode(
    VenPaysNativePaymentSession.self,
    from: responseData
)
```

Or construct the session from fields your backend already decoded.

### 3. Check availability

```swift
switch client.applePayAvailability(for: session) {
case .available:
    break
case .supportedButNoConfiguredCard:
    // Prompt the user to add a card in Wallet
case .unsupportedDevice:
    // Hide Apple Pay
case .invalidMerchantConfiguration:
    // Fix Merchant ID / networks / capabilities
case .sessionExpired:
    // Re-initiate on your backend
}
```

### 4. Present Apple Pay (UIKit)

Call presentation only as a direct result of a user tap on the Apple Pay button:

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
                // Handle other VenPaysError codes.
                break
            }
        }
    }
}
```

### 5. SwiftUI

```swift
SwiftUIApplePayButton(
    type: .buy,
    style: .automatic,
    isPaymentInProgress: viewModel.isPaying
) {
    Task { await viewModel.pay(from: presenter) }
}
```

Obtain a `UIViewController` presenter from the SwiftUI hierarchy when calling `presentApplePay`.

---

## 8. Results and errors

### Payment result statuses

| Status | Meaning | Typical app action |
|--------|---------|--------------------|
| `succeeded` | Payment completed | Show success; confirm with backend/webhook |
| `failed` | Payment failed / declined | Show failure |
| `cancelled` | Cancelled at payment layer | Show cancelled / allow retry |
| `processing` | Accepted; may still be settling | Show pending; reconcile by `trackID` |
| `unknown` | Recovery exhausted without a final status | Reconcile with your backend using `trackID` |

Closing the Apple Pay sheet **before** any authorization throws `VenPaysError` with code
`userCancelledBeforeAuthorization` (provably no charge). If an in-flight authorize request is
cancelled afterwards and its outcome cannot be confirmed, the SDK throws
`networkRequestCancelled` — the authorization may have reached VenPay, so reconcile by `trackID`.

### Common error codes

Switch on `VenPaysError.code`, not message text.

| Code | Meaning | Typical next step |
|------|---------|-------------------|
| `sessionExpired` | Native token expired | Re-initiate on backend |
| `applePayUnsupported` | Device cannot use Apple Pay | Hide Apple Pay |
| `noSupportedCard` | No Wallet card for required networks | Prompt user to add a card |
| `invalidApplePayConfiguration` | Merchant ID / networks / capabilities | Fix Apple / initiation config |
| `presentationFailed` | Sheet failed to present | Retry / check device state |
| `userCancelledBeforeAuthorization` | User closed the sheet before any authorization — no charge possible | Show cancelled / allow immediate retry |
| `networkRequestCancelled` | In-flight request cancelled; authorization may have reached VenPay | Reconcile by track ID before retry |
| `paymentCancelled` | Deprecated — ambiguous predecessor of the two codes above | Migrate to the specific codes |
| `invalidApplePayToken` | Token / paymentData invalid | Investigate Apple Pay config |
| `unauthorized` | Invalid native session | Re-initiate |
| `processorDeclined` | Declined | Show decline |
| `processorUnavailable` | Processor unavailable | Retry later |
| `requestTimeout` | Timeout | Reconcile / recover by track ID |
| `networkUnavailable` | Network / transport failure | Retry / recover |
| `paymentStatusUnknown` | Recovery exhausted | Reconcile by track ID |

`VenPaysError.isRetryable` indicates whether a transport-level retry may help. After uncertain authorize outcomes, prefer backend reconciliation over assuming failure.

---

## 9. Security rules

| Credential or data | Allowed location |
|--------------------|------------------|
| Merchant `X-API-KEY` | Merchant backend only |
| Native session token | App memory / SDK only — never logs |
| Amount and currency | Established server-side at initiation |
| Apple `payment_data` | Device → VenPays authorize only |
| Payment status | VenPays + merchant backend |

Rules for merchants:

- Do not embed merchant secrets in the app
- Do not override session amount, currency, Merchant ID, or networks in the client
- Do not log native session tokens, Authorization headers, Apple tokens, signatures, or full authorize bodies
- Treat `.unknown` and `.processing` as reconcile-with-backend states
- Fulfill orders from trusted backend/webhook confirmation, not from client UI alone

Security reports: `security@venpays.com`  
Support: `support@venpays.com`

---

## 10. Testing checklist

Before pilot traffic:

- [ ] Apple Pay capability enabled and Merchant ID selected in Xcode
- [ ] Merchant ID in the app matches `apple_pay.merchant_identifier` from initiation
- [ ] Payment Processing certificate configured with VenPays / processor
- [ ] Initiation uses `integration_type: native_ios` and returns a valid native session
- [ ] Availability check returns `.available` on a physical device with a supported card
- [ ] User tap presents the Apple Pay sheet
- [ ] After Face ID / Touch ID, authorize reaches VenPays (`POST .../authorize`)
- [ ] App handles `succeeded`, `failed`, `processing`, `unknown`, `userCancelledBeforeAuthorization`, and `networkRequestCancelled`
- [ ] Backend webhook / order status updates for the same `track_id`
- [ ] No secrets or tokens appear in device logs

Known gaps for RC:

- Successful processor authorization may still be pending in your environment
- Global market validation is not completed
- Treat this release as controlled merchant integration / pilot validation

---

## 11. Go-live notes

This SDK release candidate is intended for controlled merchant integration and sandbox/pilot validation. It is not yet globally certified or approved for unrestricted production deployment.

When expanding beyond the initially validated Bahrain configuration (BHD, Visa, Mastercard, 3-D Secure), re-validate:

- Apple Pay regional eligibility
- Card networks and 3-D Secure behavior
- Currency and acquirer support
- End-to-end authorize + webhook confirmation on production-like traffic
