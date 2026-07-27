import Foundation

/// Trusted native Apple Pay payment session returned by the merchant backend after initiation.
///
/// Amount and currency on this type are the sole source of truth for the Apple Pay sheet total.
/// The SDK does not accept overrides at presentation time.
///
/// - Important: `nativeSessionToken` is sensitive. It is redacted from `description` and
///   `debugDescription` and must never be logged.
/// - Note: Native session tokens typically expire after approximately 900 seconds on the backend.
public struct VenPaysNativePaymentSession: Sendable, Codable, Equatable {
    /// VenPays payment track identifier.
    public let trackID: String
    /// Opaque Bearer token for authorize and status APIs. Never log this value.
    public let nativeSessionToken: String
    /// Instant when the native session token expires.
    public let expiresAt: Date
    /// Trusted payment amount from VenPays initiation.
    public let amount: Decimal
    /// Trusted ISO-style currency code (three uppercase letters).
    public let currency: String
    /// Optional merchant reference from initiation.
    public let merchantReference: String?
    /// Apple Pay PassKit configuration embedded in the initiation response.
    public let applePay: VenPaysApplePayConfiguration

    /// Creates and validates a session from merchant-provided initiation fields.
    ///
    /// - Parameters:
    ///   - trackID: Non-empty track identifier.
    ///   - nativeSessionToken: Non-empty native session token.
    ///   - expiresAt: Expiry that must be strictly in the future relative to `now`.
    ///   - amount: Amount greater than zero.
    ///   - currency: Three-character uppercase currency code.
    ///   - merchantReference: Optional merchant reference.
    ///   - applePay: Embedded Apple Pay configuration.
    ///   - now: Clock used for expiry validation (injectable for tests).
    /// - Throws: ``VenPaysError`` when validation fails.
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
    ///
    /// - Parameter now: Comparison time. Defaults to `Date()`.
    /// - Returns: `true` when `expiresAt` is less than or equal to `now`.
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
    /// Redacted description that never includes the native session token.
    public var description: String {
        redactedDescription
    }

    /// Redacted debug description that never includes the native session token.
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
