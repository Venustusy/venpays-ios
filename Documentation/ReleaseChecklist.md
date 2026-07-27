# Release Checklist

SDK version target: **0.1.0** (do not mark 1.0.0 without full validation).

Use `Scripts/prepare-release.sh <version>` for local gates. Do not push tags from the script by default.

## Code

- [ ] Clean `git status`
- [ ] Version updated in `SDKVersion` / changelog consistently
- [ ] CHANGELOG updated
- [ ] Public API reviewed
- [ ] No breaking changes without version bump
- [ ] No debug-only code paths left enabled by default
- [ ] No secret material in Sources/, Example/, Tests/, docs samples
- [ ] `swift package resolve` succeeds (with Xcode toolchain)

## Automated Tests

- [ ] `swift build` (Xcode `DEVELOPER_DIR`)
- [ ] `swift test` where applicable
- [ ] `xcodebuild -scheme VenPaysApplePay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- [ ] Simulator tests via `xcodebuild test`
- [ ] Test artifacts archived (xcresult under `.build/test-results/` or CI)

## Documentation

- [ ] README current
- [ ] APIReference current
- [ ] IntegrationGuide current
- [ ] BackendIntegration current
- [ ] ErrorReference current
- [ ] SecurityModel current
- [ ] CompatibilityMatrix current
- [ ] ReleaseValidationReportTemplate ready for testers

## Backend

- [ ] Native routes deployed
- [ ] Feature flag enabled
- [ ] Redis TTL configured for native sessions
- [ ] Merchant Apple Pay ID configured
- [ ] Processor (MPGS) path validated in the intended environment
- [ ] Webhook validated
- [ ] Unauthenticated status route removed or protected
- [ ] Rate limiting validated

## Device Validation

- [ ] Physical-device matrix complete (see validation report)
- [ ] Successful transaction complete
- [ ] Cancellation tested
- [ ] Failure / decline tested
- [ ] Recovery tested
- [ ] Sensitive logs reviewed

## Release

- [ ] Tag signed (`git tag -s v0.1.0-rc.1`)
- [ ] Release notes approved
- [ ] GitHub release marked **prerelease** when applicable
- [ ] Package installation tested from tag
- [ ] Rollback commit/tag identified

## Classification

Until physical-device, backend deployment, webhook, and security prerequisites are evidenced:

**IMPLEMENTATION COMPLETE — RELEASE CANDIDATE NOT YET VALIDATED**
