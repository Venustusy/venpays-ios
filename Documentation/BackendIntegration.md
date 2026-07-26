# Backend Integration

## Server-to-server initiation

The merchant backend creates a native Apple Pay payment:

```
POST /merchant/initiate-payment
X-API-KEY: <merchant-secret-key>
Content-Type: application/json
```

### Request

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

### Native initiation response (returned to the iOS app)

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

The iOS SDK **never** calls `/merchant/initiate-payment`.

## SDK authorize

```
POST /v1/sdk/apple-pay/payments/{track_id}/authorize
Authorization: Bearer <native_session_token>
Idempotency-Key: <uuid>
X-Request-ID: <uuid>
Content-Type: application/json
```

`payment_data` is the decoded JSON object from `PKPayment.token.paymentData` (not a base64 blob of the whole payload).

HTTP **200** = completed result body  
HTTP **202** = processing; SDK recovers via status

## SDK status recovery

```
GET /v1/sdk/apple-pay/payments/{track_id}
Authorization: Bearer <native_session_token>
X-Request-ID: <uuid>
```

Native session tokens default to ~900 seconds. Status recovery only works while the token is valid.

Do **not** use `/merchant/payment-status-by-track-id` from the SDK.

## Amount / currency source of truth

The backend session amount and currency are authoritative. The SDK builds exactly one final Apple Pay summary item:

- label = `apple_pay.merchant_display_name`
- amount = top-level `amount`
- type = final

## Environments

Default SDK base URLs (may still be finalized):

- sandbox: `https://api.sandbox.venpays.com`
- production: `https://api.venpays.com`

Use `VenPaysEnvironment.custom(URL)` while hosts are being confirmed.
