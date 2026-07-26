# Testing Guide

## Unit / package tests

```bash
swift test
```

These tests use `MockURLProtocol` and do **not** exercise live PassKit sheets or physical Apple Pay.

Do not treat `swift test` as validation of Apple Pay runtime behavior.

## Simulator limitations

- Apple Pay authorization on Simulator is limited or unavailable depending on OS/Xcode.
- Use Simulator only for UI layout of the Apple Pay button and non-PassKit logic.
- Full sheet + Face ID / Touch ID requires a **physical device**.

## Physical device prerequisites

- [ ] Apple Developer account
- [ ] Merchant ID created
- [ ] Apple Pay capability on App ID
- [ ] Provisioning profile includes Apple Pay
- [ ] Payment processing certificate configured with the processor
- [ ] Physical Apple Pay–capable iPhone
- [ ] Sandbox tester Apple ID (for sandbox)
- [ ] Sandbox cards added to Wallet
- [ ] Face ID / Touch ID / passcode enabled

## Physical-device test checklist (PENDING)

Status: **not performed in this repository implementation pass**.

- [ ] Happy-path payment succeeds
- [ ] Face ID / Touch ID confirmation
- [ ] User cancellation before auth
- [ ] Decline path
- [ ] Timeout / poor network after authorization
- [ ] Duplicate tap while payment in progress
- [ ] App backgrounding during sheet
- [ ] Network loss after authorize request sent
- [ ] Status recovery while native token still valid
- [ ] Session expiry after ~900s blocks recovery as expected

## Sandbox end-to-end checklist (PENDING)

- [ ] Merchant backend initiation against deployed native SDK APIs
- [ ] Authorize endpoint reachable from device
- [ ] Status endpoint recovery
- [ ] Processor sandbox accept/decline

## Suggested manual scenarios

1. **Cancellation** — open sheet, tap Cancel → `paymentCancelled`
2. **Decline** — use a sandbox decline card → `failed` / `processorDeclined`
3. **Duplicate tap** — tap Apple Pay button twice quickly → second tap ignored while in progress
4. **Backgrounding** — background during sheet; confirm no crash / single completion
5. **Network loss after authorize** — disable network after token sent; confirm recovery / `unknown` rather than false failure when uncertain
