import Foundation

/// Trusted native Apple Pay payment session returned by the merchant backend after initiation.
///
/// The `nativeSessionToken` is never included in `description`, `debugDescription`, or logs.
public struct VenPaysNativePaymentSession: Sendable, Codable, Equatable {
    public let trackID: String
    public let nativeSessionToken: String
    public let expiresAt: Date
    public let amount: Decimal
    public let currency: String
    public let merchantReference: String?
    public let applePay: VenPaysApplePayConfiguration

    /// Creates and validates a session from merchant-provided initiation fields.
    public init(
        trackID: String,
        nativeSessionToken: String,
        expiresAt: Date,
        amount: Decimal,
        currency: String,
        merchantReference: String? = nil,
        applePay: VenPaysApplePayConfiguration,
        now: Date = Date()
    ) throws {
        self.trackID = trackID
        self.nativeSessionToken = nativeSessionToken
        self.expiresAt = expiresAt
        self.amount = amount
        self.currency = currency
        self.merchantReference = merchantReference
        self.applePay = applePay
        try validate(now: now)
    }

    enum CodingKeys: String, CodingKey {
        case trackID = "track_id"
        case nativeSessionToken = "native_session_token"
        case expiresAt = "expires_at"
        case amount
        case currency
        case merchantReference = "merchant_reference"
        case applePay = "apple_pay"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackID = try container.decode(String.self, forKey: .trackID)
        nativeSessionToken = try container.decode(String.self, forKey: .nativeSessionToken)

        if let date = try? container.decode(Date.self, forKey: .expiresAt) {
            expiresAt = date
        } else {
            let raw = try container.decode(String.self, forKey: .expiresAt)
            expiresAt = try DateParser.parseISO8601(raw)
        }

        if let decimal = try? container.decode(Decimal.self, forKey: .amount) {
            amount = decimal
        } else if let string = try? container.decode(String.self, forKey: .amount) {
            amount = try DecimalParser.parse(string)
        } else if let double = try? container.decode(Double.self, forKey: .amount) {
            amount = Decimal(double)
        } else {
            throw VenPaysError(code: .invalidAmount, message: "Unable to decode amount.")
        }

        currency = try container.decode(String.self, forKey: .currency)
        merchantReference = try container.decodeIfPresent(String.self, forKey: .merchantReference)
        applePay = try container.decode(VenPaysApplePayConfiguration.self, forKey: .applePay)
        try validate(now: Date())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackID, forKey: .trackID)
        try container.encode(nativeSessionToken, forKey: .nativeSessionToken)
        try container.encode(DateParser.formatISO8601(expiresAt), forKey: .expiresAt)
        try container.encode(DecimalParser.format(amount), forKey: .amount)
        try container.encode(currency, forKey: .currency)
        try container.encodeIfPresent(merchantReference, forKey: .merchantReference)
        try container.encode(applePay, forKey: .applePay)
    }

    /// Whether the native session token is still within its validity window.
    public func isExpired(now: Date = Date()) -> Bool {
        expiresAt <= now
    }

    func validate(now: Date) throws {
        guard !trackID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VenPaysError(code: .invalidSession, message: "track_id must be non-empty.")
        }
        guard !nativeSessionToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VenPaysError(code: .invalidSession, message: "native_session_token must be non-empty.")
        }
        guard expiresAt > now else {
            throw VenPaysError(code: .sessionExpired, message: "Native session token has expired.")
        }
        guard amount > 0 else {
            throw VenPaysError(code: .invalidAmount, message: "Amount must be greater than zero.")
        }
        guard currency.count == 3, currency == currency.uppercased(),
              currency.unicodeScalars.allSatisfy({ CharacterSet.uppercaseLetters.contains($0) }) else {
            throw VenPaysError(
                code: .unsupportedCurrency,
                message: "Currency must be a three-character uppercase ISO-style code."
            )
        }
        try applePay.validate()
        if applePay.currencyCode != currency {
            throw VenPaysError(
                code: .invalidSession,
                message: "Session currency must match apple_pay.currency_code."
            )
        }
    }
}

extension VenPaysNativePaymentSession: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        redactedDescription
    }

    public var debugDescription: String {
        redactedDescription
    }

    private var redactedDescription: String {
        """
        VenPaysNativePaymentSession(trackID: \(trackID), nativeSessionToken: <redacted>, \
        expiresAt: \(DateParser.formatISO8601(expiresAt)), amount: \(DecimalParser.format(amount)), \
        currency: \(currency), merchantReference: \(merchantReference ?? "nil"), \
        applePay: \(applePay.merchantIdentifier))
        """
    }
}
