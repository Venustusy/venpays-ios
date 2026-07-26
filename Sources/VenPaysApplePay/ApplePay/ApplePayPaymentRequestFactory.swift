import Foundation
import PassKit

/// Builds a `PKPaymentRequest` exclusively from a trusted backend session.
///
/// Callers cannot override merchant identifier, country, currency, amount,
/// networks, capabilities, or the final summary item total.
enum ApplePayPaymentRequestFactory {
    static func makeRequest(from session: VenPaysNativePaymentSession) throws -> PKPaymentRequest {
        let mapped = ApplePayNetworkMapper.mapNetworks(session.applePay.supportedNetworks)
        guard !mapped.networks.isEmpty else {
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "No supported Apple Pay networks remain after mapping."
            )
        }

        let capabilities = ApplePayCapabilityMapper.mapCapabilities(session.applePay.merchantCapabilities)
        let request = PKPaymentRequest()
        request.merchantIdentifier = session.applePay.merchantIdentifier
        request.countryCode = session.applePay.countryCode
        request.currencyCode = session.applePay.currencyCode
        request.supportedNetworks = mapped.networks
        request.merchantCapabilities = capabilities

        let summaryItem = PKPaymentSummaryItem(
            label: session.applePay.merchantDisplayName,
            amount: NSDecimalNumber(decimal: session.amount),
            type: .final
        )
        request.paymentSummaryItems = [summaryItem]
        return request
    }
}
