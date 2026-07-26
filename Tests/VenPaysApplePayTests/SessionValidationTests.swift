import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("SessionValidation")
struct SessionValidationTests {
    @Test func validDecodingFromInitiationJSON() throws {
        let data = try Fixtures.initiationJSON()
        let session = try JSONDecoder().decode(VenPaysNativePaymentSession.self, from: data)
        #expect(session.trackID == Fixtures.trackID)
        #expect(session.amount == Decimal(string: "10.000"))
        #expect(session.currency == "BHD")
        #expect(session.applePay.merchantIdentifier == Fixtures.merchantID)
        #expect(!session.description.contains(Fixtures.token))
        #expect(!session.debugDescription.contains(Fixtures.token))
    }

    @Test func amountDecimalParsing() throws {
        #expect(try DecimalParser.parse("10.000") == Decimal(string: "10.000"))
        #expect(throws: VenPaysError.self) {
            _ = try DecimalParser.parse("")
        }
        #expect(throws: VenPaysError.self) {
            _ = try DecimalParser.parse("abc")
        }
    }

    @Test func expiredSessionRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try Fixtures.validSession(expiresAt: Fixtures.pastExpiry())
        }
    }

    @Test func missingTokenRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try Fixtures.validSession(token: "   ")
        }
    }

    @Test func invalidCurrencyRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try Fixtures.validSession(currency: "bh")
        }
        #expect(throws: VenPaysError.self) {
            _ = try Fixtures.validSession(currency: "BHDX")
        }
    }

    @Test func invalidAppleConfigurationRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysApplePayConfiguration(
                merchantIdentifier: "",
                merchantDisplayName: "Merchant",
                countryCode: "BH",
                currencyCode: "BHD",
                supportedNetworks: ["visa"],
                merchantCapabilities: ["threeDSecure"]
            )
        }
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysApplePayConfiguration(
                merchantIdentifier: "merchant.com.x",
                merchantDisplayName: "Merchant",
                countryCode: "bh",
                currencyCode: "BHD",
                supportedNetworks: ["visa"],
                merchantCapabilities: ["threeDSecure"]
            )
        }
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysApplePayConfiguration(
                merchantIdentifier: "merchant.com.x",
                merchantDisplayName: "Merchant",
                countryCode: "BH",
                currencyCode: "BHD",
                supportedNetworks: ["unknownNetwork"],
                merchantCapabilities: ["threeDSecure"]
            )
        }
    }

    @Test func zeroAmountRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try Fixtures.validSession(amount: 0)
        }
    }
}
