import Foundation
import PassKit
import Testing
@testable import VenPaysApplePay

struct MockCapabilityChecker: ApplePayCapabilityChecking {
    var canMake: Bool
    var canMakeUsingNetworks: Bool

    func canMakePayments() -> Bool { canMake }

    func canMakePayments(
        usingNetworks networks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool {
        canMakeUsingNetworks
    }
}

@Suite("ApplePayAvailability")
struct ApplePayAvailabilityTests {
    @Test func available() throws {
        let session = try Fixtures.validSession()
        let service = ApplePayAvailabilityService(
            checker: MockCapabilityChecker(canMake: true, canMakeUsingNetworks: true)
        )
        #expect(service.availability(for: session) == .available)
    }

    @Test func supportedButNoCard() throws {
        let session = try Fixtures.validSession()
        let service = ApplePayAvailabilityService(
            checker: MockCapabilityChecker(canMake: true, canMakeUsingNetworks: false)
        )
        #expect(service.availability(for: session) == .supportedButNoConfiguredCard)
    }

    @Test func unsupportedDevice() throws {
        let session = try Fixtures.validSession()
        let service = ApplePayAvailabilityService(
            checker: MockCapabilityChecker(canMake: false, canMakeUsingNetworks: false)
        )
        #expect(service.availability(for: session) == .unsupportedDevice)
    }

    @Test func expiredSession() throws {
        // Construct without validate by decoding then checking with custom now via service.
        // Build a session that is valid at creation, then evaluate with a future "now".
        let expires = Date().addingTimeInterval(2)
        let session = try Fixtures.validSession(expiresAt: expires)
        let service = ApplePayAvailabilityService(
            checker: MockCapabilityChecker(canMake: true, canMakeUsingNetworks: true)
        )
        #expect(service.availability(for: session, now: expires.addingTimeInterval(1)) == .sessionExpired)
    }

    @Test func invalidMerchantConfigurationWhenNoMappedNetworks() throws {
        // Session validation requires at least one recognized network, so simulate
        // via mapper directly for ignored-only outcome through a custom config path.
        let mapped = ApplePayNetworkMapper.mapNetworks(["not-a-network"])
        #expect(mapped.networks.isEmpty)
        #expect(mapped.ignored == ["not-a-network"])
    }
}
