import Foundation

struct AuthorizePaymentRequest: Encodable, Sendable {
    let paymentData: [String: AnyCodable]
    let paymentMethod: PaymentMethodPayload
    let transactionIdentifier: String?
    let sdk: SDKPayload

    struct PaymentMethodPayload: Encodable, Sendable {
        let displayName: String?
        let network: String?
        let type: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case network
            case type
        }
    }

    struct SDKPayload: Encodable, Sendable {
        let platform: String
        let version: String
    }

    enum CodingKeys: String, CodingKey {
        case paymentData = "payment_data"
        case paymentMethod = "payment_method"
        case transactionIdentifier = "transaction_identifier"
        case sdk
    }

    init(token: EncodedApplePayToken) {
        var mapped: [String: AnyCodable] = [:]
        for (key, value) in token.paymentData {
            mapped[key] = AnyCodable(value)
        }
        self.paymentData = mapped
        self.paymentMethod = PaymentMethodPayload(
            displayName: token.paymentMethodDisplayName,
            network: token.paymentMethodNetwork,
            type: token.paymentMethodType
        )
        self.transactionIdentifier = token.transactionIdentifier
        self.sdk = SDKPayload(platform: "ios", version: SDKVersion.current)
    }

    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}

/// Type-erased Codable wrapper for heterogeneous payment_data JSON.
struct AnyCodable: Codable, Sendable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues(AnyCodable.init))
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                try container.encode(number.boolValue)
            } else if floor(number.doubleValue) == number.doubleValue {
                try container.encode(number.intValue)
            } else {
                try container.encode(number.doubleValue)
            }
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON value")
            throw EncodingError.invalidValue(value, context)
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        default:
            return false
        }
    }
}
