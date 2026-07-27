# Contributing to VenPaysApplePay

## Local setup

1. Install Xcode with iOS Simulator runtimes.
2. `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
3. Open the package folder in Xcode (**iOS destination**, not My Mac).

## Build

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift package resolve
xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Tests

```bash
# Select an available simulator ID from xcodebuild -showdestinations
xcodebuild -scheme VenPaysApplePay \
  -destination 'platform=iOS Simulator,id=<SIM_ID>' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Formatting expectations

- Match existing Swift style in `Sources/`
- Prefer clear names over cleverness
- No force-unwraps on network payloads without validation

## Public API rules

- Document every new `public` declaration with `///`
- Avoid breaking changes in a patch release
- Never add merchant secret key parameters to the client API

## Commit convention

Use conventional prefixes when practical:

- `feat(ios-sdk):`
- `fix(ios-sdk):`
- `docs(ios-sdk):`
- `test(ios-sdk):`
- `ci(ios-sdk):`
- `chore(...):`

## Pull requests

Use the PR template. Include test evidence and security impact.

## Security reporting

Email `security@venpays.com` (placeholder). Do not open public issues with exploit details or secrets.

## Documentation requirements

Update README / APIReference / guides when behavior or public API changes.

## No secrets rule

Never commit:

- `X-API-KEY` values
- native session tokens
- Apple Pay payment payloads
- provisioning profiles / signing certs
- `.env` files with credentials
