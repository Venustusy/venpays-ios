# VenPays Apple Pay SDK Release Validation Report

Fill this report during RC / pilot validation. Do **not** pre-mark approvals as passed.

## Release Identity

| Field | Value |
|-------|-------|
| SDK version | 0.1.0 |
| SDK commit | |
| Git tag | |
| Payment engine commit | |
| Environment | production host / other |
| Date | |
| Tester | |
| Reviewer | |

## Toolchain

| Field | Value |
|-------|-------|
| macOS | |
| Xcode | |
| Swift | |
| iOS SDK | |
| Device model | |
| Device iOS version | |

## Automated Validation

| Check | Result | Artifact / notes |
|-------|--------|------------------|
| `swift package resolve` | | |
| `swift build` (with Xcode DEVELOPER_DIR) | | |
| `swift test` | | |
| generic iOS `xcodebuild` build | | |
| Simulator `xcodebuild` test | | |
| Test count | | |
| Result artifact links | | |

## Backend Validation

| Check | Result | Notes |
|-------|--------|-------|
| Native routes deployed | NOT RUN / PASS / FAIL | |
| Feature flag enabled | | |
| Redis configured | | |
| Merchant Apple Pay configuration | | |
| MPGS credentials validated | | |
| Webhooks configured | | |
| Unauthenticated status route remediated | | **Release blocker if open** |

## Physical-Device Tests

| Scenario | Pass / Fail / Not run | Notes |
|----------|----------------------|-------|
| Apple Pay available | | |
| No supported card | | |
| Successful payment | | |
| User cancellation | | |
| Processor decline | | |
| HTTP 202 processing | | |
| Status recovery | | |
| Expired native session | | |
| Wrong token/track pair | | |
| Duplicate tap | | |
| Retry with same idempotency key | | |
| Network loss before submission | | |
| Network loss after submission | | |
| App backgrounding | | |
| App termination and recovery | | |
| Webhook delivery | | |
| Database transaction status | | |
| MPGS transaction confirmation | | |
| Sensitive log inspection | | |

## Security Review

| Check | Result |
|-------|--------|
| No X-API-KEY in app | |
| No session token logs | |
| No Apple token logs | |
| No authorization body logs | |
| No direct MPGS access | |
| Unauthenticated status endpoint resolved | |
| TLS confirmed | |
| Rate limiting confirmed | |

## Defects

| ID | Severity | Description | Owner | Status | Release impact |
|----|----------|-------------|-------|--------|----------------|
| | | | | | |

## Approval

| Role | Name | Date | Decision |
|------|------|------|----------|
| Engineering | | | |
| Security | | | |
| Product | | | |
| Operations | | | |

## Final Decision

Select exactly one:

- [ ] rejected
- [ ] approved for release candidate
- [ ] approved for pilot
- [ ] approved for production

**Default until evidenced otherwise:** not approved for production.
