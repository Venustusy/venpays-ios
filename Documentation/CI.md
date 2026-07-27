# Continuous Integration

## Workflow

File: `.github/workflows/ios-sdk.yml`

### Triggers

- `pull_request` to `main`
- `push` to `main`
- tags matching `v*`

### Runner

`macos-15` GitHub-hosted runner with concurrency cancellation and a 45-minute timeout.

### Commands

1. Print `xcodebuild -version` and `swift --version`
2. `swift package resolve`
3. `xcodebuild -list`
4. Generic iOS build:
   `xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
5. Initialize CoreSimulator (`xcrun simctl list`) and select a device from
   `xcrun simctl list devices available --json` (Python preference list, then first available iOS simulator)
6. Boot the simulator and wait with `xcrun simctl bootstatus <udid> -b`
7. `xcodebuild test` with `-destination "platform=iOS Simulator,id=<udid>"` and
   `-resultBundlePath .build/test-results/VenPaysApplePay.xcresult`

Host `swift build` / `swift test` are **not** CI gates (iOS-only UIKit package).

### Simulator preference order

1. iPhone 16
2. iPhone 16 Pro
3. iPhone 16e
4. iPhone 17
5. iPhone SE (3rd generation)
6. iPad (A16)
7. First available iOS simulator (fallback)

### Artifacts

Uploaded when present:

- `.build/test-results/VenPaysApplePay.xcresult`
- `.build/test-results/xcodebuild-test.log`

No production secrets, signing identities, or external service credentials are used.

## Local equivalent

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift package resolve
xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

xcrun simctl list >/dev/null
xcrun simctl list devices available --json > /tmp/simctl-devices.json
# Select UDID via the same preference logic as CI (or pick manually).

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b

mkdir -p .build/test-results
xcodebuild -scheme VenPaysApplePay \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -parallel-testing-enabled NO \
  -resultBundlePath .build/test-results/VenPaysApplePay.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Failure diagnosis

| Symptom | Likely cause |
|---------|----------------|
| UIKit module not found | Destination is My Mac / host SDK |
| No available iOS simulators | Runner missing iOS Simulator runtimes |
| bootstatus hang | Simulator service unhealthy; re-run job |
| Test flake on MockURLProtocol | Ensure networking suites remain serialized |
| Signing errors | Ensure `CODE_SIGNING_ALLOWED=NO` for package tests |

## Badge

README uses a placeholder badge path:

`https://github.com/<organization>/venpays-apple-pay-ios/actions/workflows/ios-sdk.yml/badge.svg`

Replace `<organization>/venpays-apple-pay-ios` when the remote exists.
