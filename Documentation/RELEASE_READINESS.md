# Release Readiness

**Date:** 2026-08-06  
**SDK version:** 0.1.0 (`0.1.0-rc.1` tag target)  
**Validated commit (CI PASS evidence):** `79a8b66` (`79a8b6694f8c0bb71ae537afe72a7cbd9c4727ca`)  
**RC tag target:** `v0.1.0-rc.1` (commit recorded by the tag itself)  
**GitHub Actions run:** [30246765172](https://github.com/Venustusy/venpays-ios/actions/runs/30246765172)  
**CI Xcode:** 16.4 (Build 16F6) · Apple Swift 6.1.2  
**CI simulator:** iPhone 16 · UDID `5E1C2676-21D9-4C43-9CDC-8EFAD663A9C4` · runtime `iOS-18-5`  

**Final classification:**

## IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED

| Area | Status | Evidence | Blocking? |
|------|--------|----------|-----------|
| package build | PASS | `xcodebuild … generic/platform=iOS CODE_SIGNING_ALLOWED=NO build` → BUILD SUCCEEDED (local + CI) | No |
| unit tests | PASS | 44 tests / 9 suites on iOS Simulator (local + CI) | No |
| simulator tests | PASS | CI selected `iPhone 16` (`5E1C2676-21D9-4C43-9CDC-8EFAD663A9C4`, iOS 18.5); TEST SUCCEEDED | No |
| CI | PASS | GitHub Actions completed successfully on remote repository; build and 44 tests passed | No |
| API documentation | PASS | Public `///` comments + APIReference + DocC | No |
| integration documentation | PASS | IntegrationGuide / BackendIntegration / README | No |
| security model | PASS | SecurityModel.md documented; remediation of gateway prerequisite **not** evidenced | Yes (backend prerequisite) |
| release process | PARTIAL | Checklist, validation template, prepare-release.sh present; RC tag/prerelease in progress | No (process ready) |
| backend deployment | NOT RUN | No evidence in this repository that native routes are deployed | Yes |
| physical-device validation | PARTIAL | Apple Pay token generation confirmed on device for Bahrain config; processor authorization success still pending | Yes |
| sandbox MPGS payment | NOT RUN | Not performed / Apple Pay sandbox may be unavailable in region | Yes |
| webhook validation | NOT RUN | Not performed | Yes |
| status recovery validation (live) | PARTIAL | Unit/networking coverage only; live recovery not run | Yes |
| sensitive logging validation | PARTIAL | Code/docs assert redaction; device/log review not run | Yes |
| pilot merchant integration | NOT RUN | Not performed | Yes |
| global market certification | NOT RUN | Initial Bahrain (BHD / Visa / Mastercard / 3-D Secure) only | Yes |

### Notes

- Host `swift build` without an iOS destination fails to resolve UIKit (expected for iOS-only package); CI uses generic iOS `xcodebuild` instead.
- Do not treat PASS automated rows as full Apple Pay runtime or processor validation.
- Unauthenticated `POST /merchant/payment-status-by-track-id` remains a documented security prerequisite until ops confirms fix.
- CI evidence taken from successful push run on `main` for commit `79a8b66` (workflow **iOS SDK**).
- Native iOS does not use `success_url` / `fail_url`; payment completion returns via PassKit + authorize/status JSON.

## Native Apple Pay gate status (VP-188, 22 Nov 2026)

The payment engine's code default and `.env.example` now set `NATIVE_APPLE_PAY_ENABLED=false`.
Each environment sets the flag explicitly in CDK so it is never implicit:

| Environment | Flag | Reason |
|-------------|------|--------|
| Production (Live) | `true` (explicit CDK override) | Live merchants still use native Apple Pay; switching off would stop them. Time-bound risk acceptance, not SDK approval. |
| Sandbox | `false` (explicit CDK override) | Native Apple Pay is unavailable for testing until the release gates below pass. |

This does **not** make the native SDK production-approved. Every row marked `Yes` in the
"Blocking?" column above is still open — notably processor authorization on a physical
device, sandbox MPGS payment, webhook validation, live status recovery, sensitive-logging
validation, pilot merchant integration and global market certification. The Live override
may be removed, and the backend default kept off in production, only once all blocking
rows are `PASS`.

Hosted (web) Apple Pay is unaffected by this flag.
