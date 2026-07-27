import Foundation

/// Stable public error codes for VenPays Apple Pay.
///
/// Merchants should handle these codes rather than parsing localized messages.
/// See `Documentation/ErrorReference.md` for backend mapping.
public enum VenPaysErrorCode: String, Sendable, Codable, Equatable {
    /// SDK configuration is invalid (URL, timeout, and similar).
    case invalidConfiguration
    /// Payment session fields are invalid.
    case invalidSession
    /// Native session token is expired.
    case sessionExpired
    /// Amount is missing or not greater than zero.
    case invalidAmount
    /// Currency code is unsupported or malformed.
    case unsupportedCurrency
    /// Device cannot use Apple Pay.
    case applePayUnsupported
    /// No card is configured for required networks/capabilities.
    case noSupportedCard
    /// Apple Pay merchant configuration from the session is invalid.
    case invalidApplePayConfiguration
    /// Apple Pay sheet failed to present.
    case presentationFailed
    /// User cancelled the Apple Pay sheet or the request was cancelled.
    case paymentCancelled
    /// Apple Pay token / paymentData is invalid.
    case invalidApplePayToken
    /// Backend response was missing or malformed.
    case invalidBackendResponse
    /// Native session unauthorized or invalid.
    case unauthorized
    /// Payment is already processing.
    case paymentAlreadyProcessing
    /// Payment is already completed.
    case paymentAlreadyCompleted
    /// Processor declined the payment.
    case processorDeclined
    /// Processor is unavailable.
    case processorUnavailable
    /// Request timed out.
    case requestTimeout
    /// Network is unavailable or TLS failed.
    case networkUnavailable
    /// Client is rate limited.
    case rateLimited
    /// Idempotency key missing or conflicting.
    case idempotencyConflict
    /// Payment status could not be determined after recovery.
    case paymentStatusUnknown
    /// Unexpected internal failure.
    case internalError
}
