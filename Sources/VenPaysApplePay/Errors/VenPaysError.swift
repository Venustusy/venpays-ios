import Foundation

/// Public SDK error with stable codes suitable for merchant handling.
public struct VenPaysError: Error, Sendable, LocalizedError, Equatable {
    public let code: VenPaysErrorCode
    public let message: String
    public let requestID: String?
    public let httpStatus: Int?
    public let isRetryable: Bool
    public let underlyingDescription: String?

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
