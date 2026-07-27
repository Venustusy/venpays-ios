# Integration

Integrate VenPaysApplePay using a merchant-backend initiation flow.

## Architecture

1. Merchant app requests a session from the **merchant backend**.
2. Merchant backend calls VenPays `POST /merchant/initiate-payment` with `X-API-KEY`.
3. App decodes ``VenPaysNativePaymentSession``.
4. App checks ``VenPaysApplePayClient/applePayAvailability(for:)``.
5. On user tap, call ``VenPaysApplePayClient/presentApplePay(session:from:)``.

## Important

- Never embed the merchant `X-API-KEY` in the iOS app.
- Amount and currency are trusted from the session only.
- Call `presentApplePay` only from a direct user action.
- Prefer a physical device for Apple Pay authorization testing.

## See Also

- <doc:Security>
