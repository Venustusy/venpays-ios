import Foundation

/// Payment method details returned with a payment result.
public struct VenPaysPaymentMethod: Sendable, Codable, Equatable {
    public let type: String?
    public let network: String?
    public let displayName: String?

    public init(type: String? = nil, network: String? = nil, displayName: String? = nil) {
        self.type = type
        self.network = network
        self.displayName = displayName
    }

    enum CodingKeys: String, CodingKey {
        case type
        case network
        case displayName = "display_name"
    }
}

/// Normalized payment status exposed by the SDK.
public enum VenPaysPaymentStatus: String, Sendable, Codable, Equatable {
    case processing
    case succeeded
    case failed
    case cancelled
    case unknown

    /// Maps a backend status string into the public SDK status.
    public static func fromBackend(_ raw: String) -> VenPaysPaymentStatus {
        switch raw.lowercased() {
        case "pending", "processing":
            return .processing
        case "succeeded":
            return .succeeded
        case "failed":
            return .failed
        case "cancelled", "canceled":
            return .cancelled
        default:
            return .unknown
        }
    }

    /// Whether the status is considered terminal.
    public var isFinal: Bool {
        switch self {
        case .succeeded, .failed, .cancelled:
            return true
        case .processing, .unknown:
            return false
        }
    }
}

/// Result of an Apple Pay authorization and optional status recovery.
public struct VenPaysPaymentResult: Sendable, Equatable {
    public let trackID: String
    public let status: VenPaysPaymentStatus
    public let transactionID: String?
    public let merchantReference: String?
    public let amount: Decimal?
    public let currency: String?
    public let paymentMethod: VenPaysPaymentMethod?
    public let requestID: String?
    public let backendError: VenPaysBackendErrorDetail?

    public init(
        trackID: String,
        status: VenPaysPaymentStatus,
        transactionID: String? = nil,
        merchantReference: String? = nil,
        amount: Decimal? = nil,
        currency: String? = nil,
        paymentMethod: VenPaysPaymentMethod? = nil,
        requestID: String? = nil,
        backendError: VenPaysBackendErrorDetail? = nil
    ) {
        self.trackID = trackID
        self.status = status
        self.transactionID = transactionID
        self.merchantReference = merchantReference
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.requestID = requestID
        self.backendError = backendError
    }
}

/// Structured backend error detail carried on a payment result when present.
public struct VenPaysBackendErrorDetail: Sendable, Codable, Equatable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
