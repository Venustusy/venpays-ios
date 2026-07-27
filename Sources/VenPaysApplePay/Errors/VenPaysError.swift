import Foundation

/// Public SDK error with stable codes suitable for merchant handling.
///
/// Prefer switching on ``code`` rather than parsing ``message``.
///
/// - Note: Descriptions intentionally avoid embedding secrets or Apple Pay payloads.
public struct VenPaysError: Error, Sendable, LocalizedError, Equatable {
    /// Stable machine-readable error code.
    public let code: VenPaysErrorCode
    /// Human-readable message for diagnostics (not a localization catalog).
    public let message: String
    /// Backend or client request correlation identifier when available.
    public let requestID: String?
    /// HTTP status when the error originated from an HTTP response.
    public let httpStatus: Int?
    /// Whether a retry or continued recovery may be appropriate.
    public let isRetryable: Bool
    /// Non-sensitive description of an underlying failure type when available.
    public let underlyingDescription: String?

    /// Creates a VenPays error.
    public init(
        code: VenPaysErrorCode,
        message: String,
        requestID: String? = nil,
        httpStatus: Int? = nil,
        isRetryable: Bool = false,
        underlyingDescription: String? = nil
    ) {
        self.code = code
        self.message = message
        self.requestID = requestID
        self.httpStatus = httpStatus
        self.isRetryable = isRetryable
        self.underlyingDescription = underlyingDescription
    }

    public var errorDescription: String? {
        message
    }

    public var failureReason: String? {
        code.rawValue
    }
}

extension VenPaysError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        redactedDescription
    }

    public var debugDescription: String {
        redactedDescription
    }

    private var redactedDescription: String {
        var parts = ["VenPaysError(code: \(code.rawValue), message: \(message)"]
        if let requestID {
            parts.append("requestID: \(requestID)")
        }
        if let httpStatus {
            parts.append("httpStatus: \(httpStatus)")
        }
        parts.append("isRetryable: \(isRetryable)")
        if let underlyingDescription {
            parts.append("underlying: \(underlyingDescription)")
        }
        return parts.joined(separator: ", ") + ")"
    }
}
