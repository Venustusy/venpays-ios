# Incident Response

Operational guidance for VenPays Apple Pay iOS SDK incidents.

**Classification note:** These are engineering runbooks. They do not imply that production monitoring is fully wired.

## Common scenarios

### Payment stuck in processing

1. Capture `trackID`, `requestID`, SDK version, device time, and merchant reference.
2. Merchant backend reconciles against VenPays authoritative status APIs (authenticated).
3. Do not instruct the customer that payment failed solely because the app shows `.processing`.
4. If native session expired, re-initiate only after backend confirms no successful capture.

### App receives `.unknown`

1. Treat as uncertain — not success, not definitive failure.
2. Reconcile by `trackID` on merchant backend / VenPays.
3. Collect whether authorize may have been sent (button tap completed, network loss timing).
4. Avoid duplicate charges; reuse backend idempotency / do not create a second initiation blindly.

### Session token expired

1. Expected after native TTL (~900s).
2. Start a new initiation on the merchant backend.
3. Confirm no in-flight authorize for the expired track before retrying UX.

### Gateway unavailable / processor timeout

1. Prefer status recovery while token valid.
2. If recovery exhausted → `.unknown` / `paymentStatusUnknown`.
3. Escalate to VenPays operations with `trackID` + timestamps (no Apple token bodies).

### Duplicate-attempt concern

1. Confirm SDK duplicate-tap lock (`isPaymentInProgress`).
2. Confirm authorize idempotency key reuse on transport retry.
3. Backend should reject conflicting completions safely.

### Webhook mismatch

1. Compare webhook payload `track_id` / status with SDK result and DB row.
2. Prefer VenPays backend + MPGS as sources of truth over client UI state.
3. Document eventual consistency window.

### Sensitive-data logging incident

1. **Contain:** disable verbose logging, rotate any exposed credentials, invalidate sessions if tokens leaked.
2. Collect log samples with redaction; never forward raw `payment_data` or Bearer tokens.
3. Notify security; follow company disclosure policy.

## Immediate containment steps

1. Stop distributing builds that log secrets.
2. Disable feature flag / merchant rollout if active.
3. Preserve artifacts (xcresult, server logs, request IDs).
4. Identify blast radius (merchants, track IDs, time window).

## Evidence to collect

- SDK version + git commit/tag
- Xcode / iOS / device model
- `trackID`, `requestID` (redact tokens)
- Approximate timeline of tap → sheet → network events
- Merchant backend initiation response metadata (no secrets)
- VenPays server logs / MPGS references (ops only)

## Escalation fields

| Field | Value |
|-------|-------|
| Severity | SEV1–SEV4 (see SupportPolicy) |
| Owner | |
| Customer impact | |
| Start / detect time | |
| Related track IDs | |
| Workaround | |

## Merchant communication guidance

- Be factual; do not claim “payment failed” when status is unknown.
- Ask merchants not to paste API keys or Apple Pay payloads into tickets.
- Provide remediation (retry initiation, wait for webhook, contact support).

## Rollback guidance

1. Pin merchants to previous SDK tag if the regression is client-side.
2. Disable native Apple Pay feature flag server-side if the regression is gateway-side.
3. Record rollback tag/commit in the incident ticket.
4. Do not delete audit logs.
