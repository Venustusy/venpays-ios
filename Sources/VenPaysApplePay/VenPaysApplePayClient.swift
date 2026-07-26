import Foundation
import UIKit

/// Primary entry point for VenPays native Apple Pay on iOS.
@MainActor
public final class VenPaysApplePayClient {
    public let configuration: VenPaysConfiguration

    private let availabilityService: ApplePayAvailabilityService
    private let authorizer: any ApplePayPaymentAuthorizing
    private let recoverer: any PaymentStatusRecovering
    private let logger: Logger

    /// Creates a client with the given configuration.
    ///
    /// Networking dependencies are supplied by the SDK. Merchants never pass secret API keys.
    public convenience init(configuration: VenPaysConfiguration) {
        let logger = Logger(enabled: configuration.loggingEnabled)
        let api = APIClient(configuration: configuration, logger: logger)
        let recovery = PaymentStatusRecoveryService(
            apiClient: api,
            policy: configuration.statusRecoveryPolicy,
            logger: logger
        )
        self.init(
            configuration: configuration,
            availabilityService: ApplePayAvailabilityService(logger: logger),
            authorizer: api,
            recoverer: recovery,
            logger: logger
        )
    }

    init(
        configuration: VenPaysConfiguration,
        availabilityService: ApplePayAvailabilityService,
        authorizer: any ApplePayPaymentAuthorizing,
        recoverer: any PaymentStatusRecovering,
        logger: Logger
    ) {
        self.configuration = configuration
        self.availabilityService = availabilityService
        self.authorizer = authorizer
        self.recoverer = recoverer
        self.logger = logger
    }

    /// Checks Apple Pay availability for the given trusted session.
    public func applePayAvailability(
        for session: VenPaysNativePaymentSession
    ) -> VenPaysApplePayAvailability {
        availabilityService.availability(for: session)
    }

    /// Presents the Apple Pay sheet and authorizes the payment with VenPays.
    ///
    /// Must be called as a direct result of a user action (e.g. Apple Pay button tap).
    /// The `presenter` is retained for API consistency; presentation uses
    /// `PKPaymentAuthorizationController`.
    public func presentApplePay(
        session: VenPaysNativePaymentSession,
        from presenter: UIViewController
    ) async throws -> VenPaysPaymentResult {
        switch applePayAvailability(for: session) {
        case .available:
            break
        case .sessionExpired:
            throw VenPaysError(code: .sessionExpired, message: "Native session token has expired.")
        case .unsupportedDevice:
            throw VenPaysError(code: .applePayUnsupported, message: "This device does not support Apple Pay.")
        case .supportedButNoConfiguredCard:
            throw VenPaysError(code: .noSupportedCard, message: "No card is configured for the required networks.")
        case .invalidMerchantConfiguration:
            throw VenPaysError(
                code: .invalidApplePayConfiguration,
                message: "Apple Pay merchant configuration is invalid for this session."
            )
        }

        let coordinator = ApplePayCoordinator(
            authorizer: authorizer,
            recoverer: recoverer,
            logger: logger
        )
        return try await coordinator.present(session: session, from: presenter)
    }
}
