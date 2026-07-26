# VenPays Apple Pay Example

Example SwiftUI application source demonstrating VenPaysApplePay integration.

This directory contains **source only** (no generated `.xcodeproj`). Create the Xcode app locally as below.

## Create the Xcode app

1. Open Xcode → **File → New → Project…** → iOS App.
2. Product Name: `VenPaysApplePayExample`
3. Interface: SwiftUI, Language: Swift
4. Save the project (you may place it under `Example/` or elsewhere).
5. Delete the default `ContentView.swift` / `App` files if you will use the sources in this folder.
6. Add the files from `VenPaysApplePayExample/` into the app target.
7. **File → Add Package Dependencies…** → **Add Local…** → select the repository root (`VenPaysApplePay` package).
8. Add the `VenPaysApplePay` library product to the example target.
9. Signing & Capabilities → enable **Apple Pay** and select your Merchant ID.
10. Set a real merchant backend base URL in `ExampleMerchantBackendClient` (placeholder is `https://merchant.example.com/...`).

## Placeholder backend

```
https://merchant.example.com/api/payments/apple-pay/session
```

The example **does not** embed `X-API-KEY`. Your merchant backend holds the secret and returns the native initiation JSON.

## Run

Use a **physical device** for Apple Pay sheet testing. Simulator is insufficient for full authorization.
