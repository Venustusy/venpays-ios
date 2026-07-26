# Release Checklist

## Version

Current target: **0.1.0** (not 1.0.0)

Reasons 1.0.0 is blocked:

- [ ] Physical-device Apple Pay tests not complete
- [ ] Sandbox end-to-end tests not complete
- [ ] Backend native routes may not yet be deployed
- [ ] Unauthenticated status endpoint still exists on backend side
- [ ] Backend sheet fields remain hardcoded

## Package gates

- [ ] `swift package resolve`
- [ ] `swift build` (iOS destination)
- [ ] `swift test`
- [ ] `xcodebuild` iOS generic build (if Xcode available)
- [ ] CHANGELOG updated
- [ ] README version/status accurate
- [ ] No merchant secret keys in Sources/ or Example/

## API stability

- [ ] Public API reviewed (`VenPaysApplePayClient`, session, configuration, errors, buttons)
- [ ] No `PaymentIntent` naming unless backend adds it
- [ ] No web Apple Pay / merchant validation / `initiativeContext`

## Classification

Until physical-device and sandbox E2E validation are done:

**IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED**
