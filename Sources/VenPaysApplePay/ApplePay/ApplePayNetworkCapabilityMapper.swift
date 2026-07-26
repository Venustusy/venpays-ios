import Foundation
import PassKit

/// Maps backend network string values to PassKit networks without crashing on unknowns.
enum ApplePayNetworkMapper {
    static let recognizedBackendValues: [String] = [
        "visa",
        "masterCard",
        "amex",
        "mada",
        "discover"
    ]

    static func mapNetworks(_ values: [String]) -> (networks: [PKPaymentNetwork], ignored: [String]) {
        var networks: [PKPaymentNetwork] = []
        var ignored: [String] = []
        var seen = Set<String>()

        for value in values {
            let key = value
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            if let network = mapSingle(key) {
                networks.append(network)
            } else {
                ignored.append(key)
            }
        }
        return (networks, ignored)
    }

    static func mapSingle(_ value: String) -> PKPaymentNetwork? {
        switch value {
        case "visa":
            return .visa
        case "masterCard":
            return .masterCard
        case "amex":
            return .amex
        case "discover":
            return .discover
        case "mada":
            if #available(iOS 15.1, *) {
                return .mada
            }
            return nil
        default:
            return nil
        }
    }
}

/// Maps backend merchant capability strings to PassKit capabilities.
enum ApplePayCapabilityMapper {
    static let recognizedBackendValues: [String] = [
        "threeDSecure",
        "credit",
        "debit",
        "emv"
    ]

    static func isRecognized(_ value: String) -> Bool {
        recognizedBackendValues.contains(value)
    }

    static func mapCapabilities(_ values: [String]) -> PKMerchantCapability {
        var result: PKMerchantCapability = []
        for value in values {
            switch value {
            case "threeDSecure":
                result.insert(.capability3DS)
            case "credit":
                result.insert(.capabilityCredit)
            case "debit":
                result.insert(.capabilityDebit)
            case "emv":
                result.insert(.capabilityEMV)
            default:
                break
            }
        }
        if result.isEmpty {
            result.insert(.capability3DS)
        }
        return result
    }
}
