# Security

Security boundaries for VenPaysApplePay.

## Trust rules

- Merchant secrets stay on the merchant backend.
- Native session tokens must not be logged.
- Apple Pay payment tokens must not be logged.
- The SDK does not call MPGS directly.
- Authorize uses Bearer native session tokens with idempotency keys.

## Warning

Do not ship while the unauthenticated merchant track-ID status endpoint remains available without authentication. Confirm gateway remediation before public release.

## See Also

- <doc:Integration>
