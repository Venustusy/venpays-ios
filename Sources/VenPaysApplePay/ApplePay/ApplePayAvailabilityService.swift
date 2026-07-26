import Foundation
import PassKit

/// Abstraction over PassKit static availability APIs for testability.
protocol ApplePayCapabilityChecking: Sendable {
    func canMakePayments() -> Bool
    func canMakePayments(usingNetworks networks: [PKPaymentNetwork], capabilities: PKMerchantCapability) -> Bool
}

struct SystemApplePayCapabilityChecker: ApplePayCapabilityChecking {
    func canMakePayments() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    func canMakePayments(
        usingNetworks networks: [PKPaymentNetwork],
        capabilities: PKMerchantCapability
    ) -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks, capabilities: capabilities)
    }
}

/// Evaluates Apple Pay availability for a trusted native payment session.
struct ApplePayAvailabilityService: Sendable {
    private let checker: any ApplePayCapabilityChecking
    private let logger: Logger

    init(
        checker: any ApplePayCapabilityChecking = SystemApplePayCapabilityChecker(),
        logger: Logger = Logger(enabled: false)
    ) {
        self.checker = checker
        self.logger = logger
    }

    func availability(
        for session: VenPaysNativePaymentSession,
        now: Date = Date()
    ) -> VenPaysApplePayAvailability {
        if session.isExpired(now: now) {
            return .sessionExpired
        }

        let mapped = ApplePayNetworkMapper.mapNetworks(session.applePay.supportedNetworks)
        if !mapped.ignored.isEmpty {
            logger.debug("Ignoring unrecognized Apple Pay networks: \(mapped.ignored.joined(separator: ","))")
        }
        guard !mapped.networks.isEmpty else {
            return .invalidMerchantConfiguration
        }

        let capabilities = ApplePayCapabilityMapper.mapCapabilities(session.applePay.merchantCapabilities)

        guard checker.canMakePayments() else {
            return .unsupportedDevice
        }

        // Distinct from canMakePayments(): requires a configured card for networks/capabilities.
        guard checker.canMakePayments(usingNetworks: mapped.networks, capabilities: capabilities) else {
            return .supportedButNoConfiguredCard
        }

        return .available
    }
}
