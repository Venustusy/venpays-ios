import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("ApplePayTokenEncoder")
struct ApplePayTokenEncoderTests {
    @Test func validPaymentDataJSON() throws {
        let data = try Fixtures.validPaymentDataJSON()
        let dict = try ApplePayTokenEncoder.encodePaymentDataJSON(data)
        #expect(dict["version"] as? String == "EC_v1")
        #expect(dict["data"] as? String == "encrypted-payload")
        #expect(dict["signature"] as? String == "signature-value")
        let header = dict["header"] as? [String: Any]
        #expect(header?["ephemeralPublicKey"] as? String == "ephemeral-key")
        #expect(header?["publicKeyHash"] as? String == "public-key-hash")
        #expect(header?["transactionId"] as? String == "transaction-id")
    }

    @Test func invalidJSONRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try ApplePayTokenEncoder.encodePaymentDataJSON(Data("not-json".utf8))
        }
    }

    @Test func missingRequiredFieldsRejected() throws {
        let incomplete: [String: Any] = [
            "version": "EC_v1",
            "data": "x",
            "header": [
                "ephemeralPublicKey": "a",
                "publicKeyHash": "b"
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: incomplete)
        #expect(throws: VenPaysError.self) {
            _ = try ApplePayTokenEncoder.encodePaymentDataJSON(data)
        }
    }

    @Test func authorizeBodyShapeIncludesOptionalPaymentMethod() throws {
        let token = try Fixtures.encodedToken()
        let body = try AuthorizePaymentRequest(token: token).jsonData()
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["payment_data"] != nil)
        let method = json?["payment_method"] as? [String: Any]
        #expect(method?["display_name"] as? String == "Visa 1234")
        #expect(method?["network"] as? String == "Visa")
        #expect(method?["type"] as? String == "credit")
        #expect(json?["transaction_identifier"] as? String == "apple-txn")
        let sdk = json?["sdk"] as? [String: Any]
        #expect(sdk?["platform"] as? String == "ios")
        #expect(sdk?["version"] as? String == "0.1.1")
    }
}
