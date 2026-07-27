import Foundation

/// Payment method details returned with a payment result.
public struct VenPaysPaymentMethod: Sendable, Codable, Equatable {
    /// Payment method type string when provided by VenPays (for example `apple_pay`).
    public let type: String?
    /// Card network display string when provided.
    public let network: String?
    /// User-visible method name when provided.
    public let displayName: String?

    /// Creates payment method metadata.
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
///
/// Backend `pending` maps to ``processing``. Unsupported backend values map to ``unknown``.
public enum VenPaysPaymentStatus: String, Sendable, Codable, Equatable {
    /// Payment is accepted for processing or still non-final.
    case processing
    /// Payment completed successfully.
    case succeeded
    /// Payment failed or was declined.
    case failed
    /// Payment was cancelled.
    case cancelled
    /// Status could not be determined after recovery or an unsupported backend value.
    ///
    /// - Important: Reconcile with your merchant backend using `trackID`. Do not treat as success.
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
///
/// - Note: `processing` and `unknown` are not final merchant success signals.
public struct VenPaysPaymentResult: Sendable, Equatable {
    /// VenPays track identifier.
    public let trackID: String
    /// Normalized payment status.
    public let status: VenPaysPaymentStatus
    /// Processor / VenPays transaction identifier when available.
    public let transactionID: String?
    /// Merchant reference when available.
    public let merchantReference: String?
    /// Amount when returned by VenPays.
    public let amount: Decimal?
    /// Currency when returned by VenPays.
    public let currency: String?
    /// Payment method metadata when returned.
    public let paymentMethod: VenPaysPaymentMethod?
    /// Correlation request identifier when available.
    public let requestID: String?
    /// Structured backend error when present on authorize responses.
    public let backendError: VenPaysBackendErrorDetail?

    /// Creates a payment result.
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
    /// Backend error code string.
    public let code: String
    /// Backend error message string.
    public let message: String

    /// Creates a backend error detail.
    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
