# Apple Pay Setup

## Apple Developer

1. Enroll in the Apple Developer Program.
2. Create an **Apple Pay Merchant ID**.
3. Create a **Payment Processing Certificate** and configure it with your processor (MPGS / VenPays guidance).
4. Enable the **Apple Pay** capability on the iOS App ID.
5. Regenerate provisioning profiles after enabling the capability.

## Xcode project

1. Signing & Capabilities → add **Apple Pay**.
2. Select the Merchant ID that matches `apple_pay.merchant_identifier` from VenPays initiation.
3. Bundle ID must match the App ID with Apple Pay enabled.

## Device requirements

- Physical iPhone with Apple Pay support
- Region/card support for your networks (e.g. Visa / Mastercard)
- Face ID / Touch ID / passcode configured
- Sandbox tester account when testing in sandbox

## Simulator

The iOS Simulator has limited or no real Apple Pay authorization. Treat simulator checks as UI-only. Full payment flows require a physical device.

## What the SDK does not do

- Does not call Apple merchant validation APIs
- Does not use `initiativeContext`
- Does not create fake Apple Pay buttons
- Does not modify Apple’s payment sheet Cancel button
