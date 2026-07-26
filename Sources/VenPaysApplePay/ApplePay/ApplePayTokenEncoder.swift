import Foundation
import PassKit

/// Encoded Apple Pay token payload ready for VenPays authorize.
struct EncodedApplePayToken: @unchecked Sendable, Equatable {
    /// Decoded `paymentData` JSON object. Marked `@unchecked Sendable` because
    /// Apple Pay token dictionaries are treated as immutable after encoding.
    let paymentData: [String: Any]
    let paymentMethodDisplayName: String?
    let paymentMethodNetwork: String?
    let paymentMethodType: String?
    let transactionIdentifier: String?

    static func == (lhs: EncodedApplePayToken, rhs: EncodedApplePayToken) -> Bool {
        NSDictionary(dictionary: lhs.paymentData).isEqual(to: rhs.paymentData)
            && lhs.paymentMethodDisplayName == rhs.paymentMethodDisplayName
            && lhs.paymentMethodNetwork == rhs.paymentMethodNetwork
            && lhs.paymentMethodType == rhs.paymentMethodType
            && lhs.transactionIdentifier == rhs.transactionIdentifier
    }
}

/// Decodes `PKPayment.token.paymentData` as JSON and extracts payment method metadata.
///
/// Does not base64-encode the complete paymentData blob — the decoded JSON object
/// is sent as `payment_data` to the backend.
enum ApplePayTokenEncoder {
    static func encode(_ payment: PKPayment) throws -> EncodedApplePayToken {
        let data = payment.token.paymentData
        guard !data.isEmpty else {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData is empty."
            )
        }

        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData is not valid JSON.",
                underlyingDescription: String(describing: type(of: error))
            )
        }

        guard let dictionary = jsonObject as? [String: Any] else {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData JSON root must be an object."
            )
        }

        try validatePaymentData(dictionary)

        let method = payment.token.paymentMethod
        let typeString: String?
        switch method.type {
        case .debit:
            typeString = "debit"
        case .credit:
            typeString = "credit"
        case .prepaid:
            typeString = "prepaid"
        case .store:
            typeString = "store"
        @unknown default:
            typeString = nil
        }

        return EncodedApplePayToken(
            paymentData: dictionary,
            paymentMethodDisplayName: method.displayName,
            paymentMethodNetwork: method.network?.rawValue,
            paymentMethodType: typeString,
            transactionIdentifier: payment.token.transactionIdentifier
        )
    }

    /// Validates payment data from a JSON dictionary (also used by tests).
    static func validatePaymentData(_ dictionary: [String: Any]) throws {
        for key in ["version", "data", "signature"] {
            guard let value = dictionary[key] as? String, !value.isEmpty else {
                throw VenPaysError(
                    code: .invalidApplePayToken,
                    message: "Apple Pay paymentData missing required field: \(key)."
                )
            }
        }

        guard let header = dictionary["header"] as? [String: Any] else {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData missing required field: header."
            )
        }

        for key in ["ephemeralPublicKey", "publicKeyHash", "transactionId"] {
            guard let value = header[key] as? String, !value.isEmpty else {
                throw VenPaysError(
                    code: .invalidApplePayToken,
                    message: "Apple Pay paymentData.header missing required field: \(key)."
                )
            }
        }
    }

    /// Encodes a raw paymentData JSON blob for tests without a live PKPayment.
    static func encodePaymentDataJSON(_ data: Data) throws -> [String: Any] {
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData is not valid JSON."
            )
        }
        guard let dictionary = jsonObject as? [String: Any] else {
            throw VenPaysError(
                code: .invalidApplePayToken,
                message: "Apple Pay paymentData JSON root must be an object."
            )
        }
        try validatePaymentData(dictionary)
        return dictionary
    }
}
