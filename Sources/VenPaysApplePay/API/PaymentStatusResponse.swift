import Foundation

struct PaymentStatusResponse: Decodable, Sendable, Equatable {
    let trackID: String
    let status: String
    let transactionID: String?
    let merchantReference: String?
    let amount: String?
    let currency: String?
    let paymentMethod: PaymentMethodPayload?

    struct PaymentMethodPayload: Decodable, Sendable, Equatable {
        let type: String?
        let network: String?
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case type
            case network
            case displayName = "display_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case trackID = "track_id"
        case status
        case transactionID = "transaction_id"
        case merchantReference = "merchant_reference"
        case amount
        case currency
        case paymentMethod = "payment_method"
    }

    func toPaymentResult(requestID: String?) -> VenPaysPaymentResult {
        let amountDecimal = amount.flatMap { try? DecimalParser.parse($0) }
        let method = paymentMethod.map {
            VenPaysPaymentMethod(type: $0.type, network: $0.network, displayName: $0.displayName)
        }
        return VenPaysPaymentResult(
            trackID: trackID,
            status: VenPaysPaymentStatus.fromBackend(status),
            transactionID: transactionID,
            merchantReference: merchantReference,
            amount: amountDecimal,
            currency: currency,
            paymentMethod: method,
            requestID: requestID,
            backendError: nil
        )
    }
}
