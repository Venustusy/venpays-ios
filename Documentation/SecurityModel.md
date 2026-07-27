# Security Model

Trust boundaries for VenPaysApplePay 0.1.0.

## Credential and data placement

| Credential or data | Allowed location |
|--------------------|------------------|
| Merchant X-API-KEY | Merchant backend only |
| Native session token | Merchant app memory and VenPays SDK (not logs) |
| MPGS credentials | VenPays gateway only |
| Apple certificates / private keys | VenPays or processor-controlled server environment |
| Payment amount | Established server-side (initiation response) |
| Currency | Established server-side (initiation response) |
| Apple payment token (`paymentData`) | Device → VenPays authorize endpoint only |
| Payment status | VenPays backend and merchant backend |

## SDK guarantees

- **No merchant API key on device.** The SDK has no API-key field and never calls `/merchant/initiate-payment`.
- **No client-controlled amount override.** `PKPaymentRequest` totals come only from `VenPaysNativePaymentSession.amount`.
- **No client-controlled currency override.** Currency comes from the trusted session.
- **HTTPS required** for non-localhost custom base URLs (`VenPaysConfiguration` validation).
- **Native session TTL.** Sessions validate `expiresAt`; recovery stops when the token is expired (backend default ~900s).
- **Bearer token redaction.** `VenPaysNativePaymentSession` descriptions redact `nativeSessionToken`; logger must not emit Authorization headers.
- **Payment token redaction.** Apple `paymentData`, signatures, and ephemeral keys are not logged.
- **Idempotency.** One `Idempotency-Key` per logical authorize attempt; transport retries reuse the same key and body.
- **Duplicate-tap protection.** `ApplePayButton` / `SwiftUIApplePayButton` ignore taps while `isPaymentInProgress` is true.
- **Uncertain payment states.** Timeouts / malformed responses after a request may have reached VenPays trigger status recovery rather than a blind failure declaration to Apple.
- **Status recovery limitations.** Recovery only works while the native session token remains valid; exhaustion returns `.unknown`.
- **No direct MPGS access** from the SDK.
- **No web Apple merchant validation** and no `initiativeContext` in the native flow.
- **No use of unauthenticated track-ID status endpoint** from the SDK. The SDK uses:
  - `GET /v1/sdk/apple-pay/payments/{track_id}` with Bearer native session token

## Known backend security prerequisite

The unauthenticated (or insufficiently authenticated) endpoint:

`POST /merchant/payment-status-by-track-id`

**must be authenticated or removed before public SDK release.**

This repository does **not** contain evidence that the gateway change is complete. Treat it as an open blocker until operations/security confirm remediation.

## Logging rules

Allowed diagnostics (when `loggingEnabled` is true): `trackID`, `requestID`, HTTP status, SDK version, normalized status/error codes, timing.

Never log: native session tokens, Authorization headers, `payment_data`, Apple tokens, signatures, full authorize bodies, merchant secrets.

## Reporting

Do not file secrets, tokens, or raw Apple Pay payloads in public issues. Use the security reporting channel documented in CONTRIBUTING / security issue config.
