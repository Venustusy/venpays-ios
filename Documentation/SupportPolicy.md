# Support Policy

## What support covers

- Integration questions for supported SDK versions
- Defects reproducible on supported iOS versions with the public API
- Clarification of error codes and backend contract expectations for native Apple Pay

## What merchants must provide

- SDK version and git tag/commit
- Xcode and device iOS versions
- Environment (production host)
- Stable error code (`VenPaysErrorCode`) and `requestID` when available
- Redacted logs only (no API keys, session tokens, or Apple Pay `paymentData`)

## Severity levels (proposed)

| Level | Meaning |
|-------|---------|
| SEV1 | Payments failing broadly; security incident |
| SEV2 | Major feature broken for a merchant segment |
| SEV3 | Degraded behavior with workaround |
| SEV4 | Minor / documentation |

## Response targets

**Proposed only — not formally approved SLA:**

| Severity | First response target |
|----------|----------------------|
| SEV1 | Same business day |
| SEV2 | 1 business day |
| SEV3–4 | 2–3 business days |

## Supported SDK versions

Until 1.0.0: best-effort on the latest `0.1.x` tag/commit used by internal pilots.

Unsupported: forked SDKs, modified PassKit flows, embedding `X-API-KEY` in apps.

## Security reporting

Do not file secrets in public issues.

Email placeholder: `security@venpays.com` _(confirm before external use)_  
Also see `.github/ISSUE_TEMPLATE/security_config.yml`.

## Product support contact

`support@venpays.com` _(placeholder — confirm)_
