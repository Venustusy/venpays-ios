import Foundation
@testable import VenPaysApplePay

enum Fixtures {
    static let trackID = "11111111-2222-3333-4444-555555555555"
    static let token = "native-session-token-value"
    static let merchantID = "merchant.com.venpays.example"

    static func futureExpiry(seconds: TimeInterval = 900) -> Date {
        Date().addingTimeInterval(seconds)
    }

    static func pastExpiry(seconds: TimeInterval = 60) -> Date {
        Date().addingTimeInterval(-seconds)
    }

    static func applePayConfig(
        networks: [String] = ["visa", "masterCard"],
        capabilities: [String] = ["threeDSecure"]
    ) throws -> VenPaysApplePayConfiguration {
        try VenPaysApplePayConfiguration(
            merchantIdentifier: merchantID,
            merchantDisplayName: "Example Merchant",
            countryCode: "BH",
            currencyCode: "BHD",
            supportedNetworks: networks,
            merchantCapabilities: capabilities
        )
    }

    static func validSession(
        expiresAt: Date? = nil,
        amount: Decimal = Decimal(string: "10.000")!,
        currency: String = "BHD",
        token: String = token
    ) throws -> VenPaysNativePaymentSession {
        try VenPaysNativePaymentSession(
            trackID: trackID,
            nativeSessionToken: token,
            expiresAt: expiresAt ?? futureExpiry(),
            amount: amount,
            currency: currency,
            merchantReference: "order-1",
            applePay: applePayConfig()
        )
    }

    static func initiationJSON(
        expiresAt: Date? = nil,
        amount: String = "10.000",
        currency: String = "BHD",
        token: String = token,
        networks: [String] = ["visa", "masterCard"]
    ) throws -> Data {
        let expiry = DateParser.formatISO8601(expiresAt ?? futureExpiry())
        let networksJSON = networks.map { "\"\($0)\"" }.joined(separator: ",")
        let json = """
        {
          "track_id": "\(trackID)",
          "native_session_token": "\(token)",
          "expires_at": "\(expiry)",
          "amount": "\(amount)",
          "currency": "\(currency)",
          "merchant_reference": "order-1",
          "apple_pay": {
            "merchant_identifier": "\(merchantID)",
            "merchant_display_name": "Example Merchant",
            "country_code": "BH",
            "currency_code": "\(currency)",
            "supported_networks": [\(networksJSON)],
            "merchant_capabilities": ["threeDSecure"]
          },
          "success": true
        }
        """
        return Data(json.utf8)
    }

    static func validPaymentDataJSON() throws -> Data {
        let json: [String: Any] = [
            "version": "EC_v1",
            "data": "encrypted-payload",
            "signature": "signature-value",
            "header": [
                "ephemeralPublicKey": "ephemeral-key",
                "publicKeyHash": "public-key-hash",
                "transactionId": "transaction-id"
            ]
        ]
        return try JSONSerialization.data(withJSONObject: json)
    }

    static func authorizeSuccessBody(status: String = "succeeded") -> Data {
        Data("""
        {
          "track_id": "\(trackID)",
          "status": "\(status)",
          "transaction_id": "txn_123",
          "merchant_reference": "order-1",
          "amount": "10.000",
          "currency": "BHD",
          "error": null
        }
        """.utf8)
    }

    static func statusBody(status: String) -> Data {
        Data("""
        {
          "track_id": "\(trackID)",
          "status": "\(status)",
          "transaction_id": "txn_123",
          "merchant_reference": "order-1",
          "amount": "10.000",
          "currency": "BHD",
          "payment_method": {
            "type": "apple_pay",
            "network": "Visa",
            "display_name": "Visa 1234"
          }
        }
        """.utf8)
    }

    static func backendErrorBody(code: String, message: String = "failed") -> Data {
        Data("""
        {
          "error": {
            "code": "\(code)",
            "message": "\(message)",
            "request_id": "req-1",
            "details": {}
          }
        }
        """.utf8)
    }

    static func encodedToken() throws -> EncodedApplePayToken {
        let data = try validPaymentDataJSON()
        let dict = try ApplePayTokenEncoder.encodePaymentDataJSON(data)
        return EncodedApplePayToken(
            paymentData: dict,
            paymentMethodDisplayName: "Visa 1234",
            paymentMethodNetwork: "Visa",
            paymentMethodType: "credit",
            transactionIdentifier: "apple-txn"
        )
    }
}
