# Troubleshooting

## Apple Pay button does not appear / unavailable

- Confirm `applePayAvailability` result.
- `.unsupportedDevice` → use a capable device; Simulator may report unsupported.
- `.supportedButNoConfiguredCard` → add a card for the required networks.
- `.invalidMerchantConfiguration` → check Merchant ID and `supported_networks`.
- `.sessionExpired` → re-initiate payment on your backend.

## Sheet fails to present

- Ensure presentation is triggered from a user action.
- Confirm Merchant ID capability matches the session `merchant_identifier`.
- Check signing / provisioning includes Apple Pay.

## `unauthorized` / `sessionExpired`

- Native session token invalid or expired (~900s default).
- Do not reuse tokens across unrelated payments.
- Confirm the app did not log or truncate the token.

## Amount mismatch concerns

- The SDK never accepts an app-provided amount override.
- Fix amounts in merchant backend initiation.

## Stuck on processing / unknown

- SDK recovers via GET status with backoff.
- If recovery returns `unknown`, reconcile using `track_id` on your backend while records are authoritative.
- Do not show a definitive failure solely because the client is uncertain after upload.

## Logging

Enable `loggingEnabled` only in non-production diagnostics. The SDK redacts tokens and never logs `payment_data`, signatures, or Authorization headers.
