import Foundation

struct AuthorizePaymentResponse: Decodable, Sendable, Equatable {
    let trackID: String
    let status: String
    let transactionID: String?
    let merchantReference: String?
    let amount: String?
    let currency: String?
    let error: NestedError?

    struct NestedError: Decodable, Sendable, Equatable {
        let code: String
        let message: String
    }

    enum CodingKeys: String, CodingKey {
        case trackID = "track_id"
        case status
        case transactionID = "transaction_id"
        case merchantReference = "merchant_reference"
        case amount
        case currency
        case error
    }

    func toPaymentResult(requestID: String?) -> VenPaysPaymentResult {
        let amountDecimal = amount.flatMap { try? DecimalParser.parse($0) }
        let backendError = error.map { VenPaysBackendErrorDetail(code: $0.code, message: $0.message) }
        return VenPaysPaymentResult(
            trackID: trackID,
            status: VenPaysPaymentStatus.fromBackend(status),
            transactionID: transactionID,
            merchantReference: merchantReference,
            amount: amountDecimal,
            currency: currency,
            paymentMethod: nil,
            requestID: requestID,
            backendError: backendError
        )
    }
}
