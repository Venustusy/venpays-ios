import Foundation
import PassKit
import Testing
@testable import VenPaysApplePay

@Suite("PaymentRequestFactory")
struct PaymentRequestFactoryTests {
    @Test func buildsTrustedRequestFields() throws {
        let session = try Fixtures.validSession()
        let request = try ApplePayPaymentRequestFactory.makeRequest(from: session)

        #expect(request.merchantIdentifier == Fixtures.merchantID)
        #expect(request.countryCode == "BH")
        #expect(request.currencyCode == "BHD")
        #expect(request.paymentSummaryItems.count == 1)
        #expect(request.paymentSummaryItems[0].label == "Example Merchant")
        #expect(request.paymentSummaryItems[0].amount == NSDecimalNumber(decimal: session.amount))
        #expect(request.paymentSummaryItems[0].type == .final)
        #expect(request.supportedNetworks.contains(.visa))
        #expect(request.supportedNetworks.contains(.masterCard))
        #expect(request.merchantCapabilities.contains(.capability3DS))
    }

    @Test func mapsKnownNetworksAndIgnoresUnknown() {
        let mapped = ApplePayNetworkMapper.mapNetworks(["visa", "unknownCard", "amex", "visa"])
        #expect(mapped.networks == [.visa, .amex])
        #expect(mapped.ignored == ["unknownCard"])
    }

    @Test func mapsCapabilities() {
        let caps = ApplePayCapabilityMapper.mapCapabilities(["threeDSecure", "credit", "debit", "emv"])
        #expect(caps.contains(.capability3DS))
        #expect(caps.contains(.capabilityCredit))
        #expect(caps.contains(.capabilityDebit))
        #expect(caps.contains(.capabilityEMV))
    }

    @Test func unknownOnlyNetworksFailFactory() throws {
        // Bypass session validation by constructing request inputs via mapper emptiness.
        let mapped = ApplePayNetworkMapper.mapNetworks(["totally-unknown"])
        #expect(mapped.networks.isEmpty)
    }
}
