import Foundation

/// Apple Pay configuration embedded in a native payment session from VenPays.
///
/// Values are supplied by VenPays initiation and mapped to PassKit when building the payment request.
public struct VenPaysApplePayConfiguration: Sendable, Codable, Equatable {
    /// Apple Merchant Identifier (for example `merchant.com.example`).
    public let merchantIdentifier: String
    /// Display name used as the single final Apple Pay summary item label.
    public let merchantDisplayName: String
    /// Two-letter uppercase country code (for example `BH`).
    public let countryCode: String
    /// Three-letter uppercase currency code (for example `BHD`).
    public let currencyCode: String
    /// Backend network identifiers such as `visa`, `masterCard`.
    public let supportedNetworks: [String]
    /// Backend capability identifiers such as `threeDSecure`.
    public let merchantCapabilities: [String]

    /// Creates and validates an Apple Pay configuration.
    ///
    /// - Throws: ``VenPaysError`` when identifiers, codes, networks, or capabilities are invalid.
    public init(
        merchantIdentifier: String,
        merchantDisplayName: String,
        countryCode: String,
        currencyCode: String,
        supportedNetworks: [String],
        merchantCapabilities: [String]
    ) throws {
        self.merchantIdentifier = merchantIdentifier
        self.merchantDisplayName = merchantDisplayName
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.supportedNetworks = supportedNetworks
        self.merchantCapabilities = merchantCapabilities
        try validate()
    }

    enum CodingKeys: String, CodingKey {
        case merchantIdentifier = "merchant_identifier"
        case merchantDisplayName = "merchant_display_name"
        case countryCode = "country_code"
        case currencyCode = "currency_code"
        case supportedNetworks = "supported_networks"
        case merchantCapabilities = "merchant_capabilities"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        merchantIdentifier = try container.decode(String.self, forKey: .merchantIdentifier)
        merchantDisplayName = try container.decode(String.self, forKey: .merchantDisplayName)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        supportedNetworks = try container.decode([String].self, forKey: .supportedNetworks)
        merchantCapabilities = try container.decode([String].self, forKey: .merchantCapabilities)
        try validate()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(merchantIdentifier, forKey: .merchantIdentifier)
        try container.encode(merchantDisplayName, forKey: .merchantDisplayName)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(supportedNetworks, forKey: .supportedNetworks)
        try container.encode(merchantCapabilities, forKey: .merchantCapabilities)
    }

    func validate() throws {
        guard !merchantIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "merchant_identifier must be non-empty."
            )
        }
        guard !merchantDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "merchant_display_name must be non-empty."
            )
        }
        guard countryCode.count == 2, countryCode == countryCode.uppercased(),
              countryCode.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.contains($0) }) else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "country_code must be two uppercase characters."
            )
        }
        guard currencyCode.count == 3, currencyCode == currencyCode.uppercased(),
              currencyCode.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.contains($0) }) else {
            throw VenPaysError(
                code: .unsupportedCurrency,
                message: "currency_code must be a three-character uppercase ISO-style code."
            )
        }
        guard !supportedNetworks.isEmpty else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "supported_networks must not be empty."
            )
        }
        let recognizedNetworks = Set(ApplePayNetworkMapper.recognizedBackendValues)
        let hasRecognized = supportedNetworks.contains { recognizedNetworks.contains($0) }
        guard hasRecognized else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "No recognized Apple Pay networks in supported_networks."
            )
        }
        for capability in merchantCapabilities {
            guard ApplePayCapabilityMapper.isRecognized(capability) else {
                throw VenPaysError(
                    code: .invalidApplePayConfiguration,
                    message: "Unrecognized merchant capability: \(capability)."
                )
            }
        }
    }
}
