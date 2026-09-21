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
    /// User closed the Apple Pay sheet before any authorization was dispatched.
    ///
    /// No authorize request was sent, so no charge is possible. Safe to retry immediately.
    case userCancelledBeforeAuthorization
    /// An in-flight authorize/status network operation was cancelled.
    ///
    /// The authorization may have reached VenPay. Do not treat as a definitive user
    /// cancellation; reconcile with the merchant backend using `trackID`.
    case networkRequestCancelled
    /// User cancelled the Apple Pay sheet or the request was cancelled.
    ///
    /// - Deprecated: Ambiguous predecessor of ``userCancelledBeforeAuthorization`` and
    ///   ``networkRequestCancelled``. New SDK versions emit the specific codes instead.
    @available(*, deprecated, renamed: "userCancelledBeforeAuthorization")
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
