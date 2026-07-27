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
3. Best-effort `swift build` / `swift test` (may fail on host without iOS SDK usage)
4. `xcodebuild -list`
5. Generic iOS build:
   `xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
6. Dynamically select an available iOS Simulator from `-showdestinations`
7. `xcodebuild test` with `-resultBundlePath .build/test-results/VenPaysApplePay.xcresult`

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

SIM_ID=$(xcodebuild -scheme VenPaysApplePay -showdestinations 2>/dev/null \
  | grep 'platform:iOS Simulator' | grep 'arch:arm64' | head -n 1 \
  | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p')

mkdir -p .build/test-results
xcodebuild -scheme VenPaysApplePay \
  -destination "platform=iOS Simulator,id=${SIM_ID}" \
  -parallel-testing-enabled NO \
  -resultBundlePath .build/test-results/VenPaysApplePay.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Failure diagnosis

| Symptom | Likely cause |
|---------|----------------|
| UIKit module not found | Destination is My Mac / host SDK |
| No simulator destination | Runner missing iOS Simulator runtimes |
| Test flake on MockURLProtocol | Ensure networking suites remain serialized |
| Signing errors | Ensure `CODE_SIGNING_ALLOWED=NO` for package tests |

## Badge

README uses a placeholder badge path:

`https://github.com/<organization>/venpays-apple-pay-ios/actions/workflows/ios-sdk.yml/badge.svg`

Replace `<organization>/venpays-apple-pay-ios` when the remote exists.
