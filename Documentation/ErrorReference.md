# Error Reference

Merchants should switch on `VenPaysError.code`, not parse message text.

| Code | Meaning | Typical retry |
|------|---------|---------------|
| `invalidConfiguration` | Bad SDK config / URL / timeout | No |
| `invalidSession` | Session fields invalid | No |
| `sessionExpired` | Native token expired | Re-initiate |
| `invalidAmount` | Amount invalid | No |
| `unsupportedCurrency` | Currency invalid | No |
| `applePayUnsupported` | Device cannot Apple Pay | No |
| `noSupportedCard` | No card for networks | User action |
| `invalidApplePayConfiguration` | Merchant ID / networks / capabilities | No |
| `presentationFailed` | Sheet failed to present | Maybe |
| `paymentCancelled` | User cancelled | No |
| `invalidApplePayToken` | Token / paymentData invalid | No |
| `invalidBackendResponse` | Malformed backend payload | Maybe |
| `unauthorized` | Bad / invalid native session | Re-initiate |
| `paymentAlreadyProcessing` | Already processing | Poll / recover |
| `paymentAlreadyCompleted` | Already completed | Reconcile |
| `processorDeclined` | Declined | No |
| `processorUnavailable` | Processor down | Yes |
| `requestTimeout` | Timeout | Yes + recover |
| `networkUnavailable` | Offline / TLS / transport | Yes + recover |
| `rateLimited` | HTTP 429 | Yes |
| `idempotencyConflict` | Idempotency conflict | Investigate |
| `paymentStatusUnknown` | Recovery exhausted | Reconcile by track ID |
| `internalError` | Unexpected | Maybe |

## Backend code mapping

| Backend code | SDK code |
|--------------|----------|
| `invalid_payment_token` | `invalidApplePayToken` |
| `idempotency_key_required` | `idempotencyConflict` |
| `unauthorized` | `unauthorized` |
| `invalid_native_session` | `unauthorized` |
| `native_session_expired` | `sessionExpired` |
| `wrong_track_id` | `invalidSession` |
| `apple_pay_not_enabled` | `invalidApplePayConfiguration` |
| `idempotency_conflict` | `idempotencyConflict` |
| `payment_already_processing` | `paymentAlreadyProcessing` |
| `payment_already_completed` | `paymentAlreadyCompleted` |
| `processor_declined` | `processorDeclined` |
| `processor_unavailable` | `processorUnavailable` |
| `processor_timeout` | `requestTimeout` |
| `internal_error` | `internalError` |

`VenPaysError.isRetryable` indicates whether a transport/application retry may help. After uncertain authorize outcomes the SDK prefers status recovery over declaring failure.
