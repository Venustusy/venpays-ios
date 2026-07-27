# Contributing to VenPaysApplePay

**Private repository.** Owned by the [Venustusy](https://github.com/Venustusy) organization:

https://github.com/Venustusy/venpays-ios

This SDK is **not** open source. Do not fork publicly, publish copies, or accept unsolicited external pull requests. Changes are limited to authorized Venustusy members and approved contractors under NDA.

## Local setup

1. Install Xcode with iOS Simulator runtimes.
2. `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
3. Clone via SSH (org access required):
   `git clone git@github.com:Venustusy/venpays-ios.git`
4. Open the package folder in Xcode (**iOS destination**, not My Mac).

## Build

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift package resolve
xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Tests

Prefer the CI simulator selection approach (`simctl` JSON). Example:

```bash
# After selecting UDID via simctl / CI logic:
xcodebuild -scheme VenPaysApplePay \
  -destination "platform=iOS Simulator,id=${UDID}" \
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

Do **not** add `Co-authored-by: Cursor` or similar tool trailers to commits.

## Pull requests

Use the PR template. Include test evidence and security impact. CODEOWNERS requires review from `@Venustusy/ios-sdk-maintainers`.

## Security reporting

Report privately to `security@venpays.com` (internal Venustusy / VenPays channel). Do not open public issues with exploit details or secrets. This private repo must not leak tokens, keys, or Apple Pay payloads.

## Documentation requirements

Update README / APIReference / guides when behavior or public API changes.

## No secrets rule

Never commit:

- `X-API-KEY` values
- native session tokens
- Apple Pay payment payloads
- provisioning profiles / signing certificates
- `.env` files with credentials
