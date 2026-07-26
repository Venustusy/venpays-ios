import Foundation

/// Stable public error codes for VenPays Apple Pay.
public enum VenPaysErrorCode: String, Sendable, Codable, Equatable {
    case invalidConfiguration
    case invalidSession
    case sessionExpired
    case invalidAmount
    case unsupportedCurrency
    case applePayUnsupported
    case noSupportedCard
    case invalidApplePayConfiguration
    case presentationFailed
    case paymentCancelled
    case invalidApplePayToken
    case invalidBackendResponse
    case unauthorized
    case paymentAlreadyProcessing
    case paymentAlreadyCompleted
    case processorDeclined
    case processorUnavailable
    case requestTimeout
    case networkUnavailable
    case rateLimited
    case idempotencyConflict
    case paymentStatusUnknown
    case internalError
}
