import Foundation
import UIKit

/// Primary entry point for VenPays native Apple Pay on iOS.
///
/// Create one client per configuration, obtain a ``VenPaysNativePaymentSession`` from your
/// merchant backend, check availability, then present Apple Pay only after a direct user tap.
///
/// - Important: This type is main-actor isolated. Call it from UI code.
/// - Warning: The iOS Simulator cannot fully validate Apple Pay authorization. Use a physical device.
/// - Note: Merchants never supply an `X-API-KEY` to this client.
@MainActor
public final class VenPaysApplePayClient {
    /// Active SDK configuration (environment, timeouts, recovery, logging).
    public let configuration: VenPaysConfiguration

    private let availabilityService: ApplePayAvailabilityService
    private let authorizer: any ApplePayPaymentAuthorizing
    private let recoverer: any PaymentStatusRecovering
    private let logger: Logger

    /// Creates a client with the given configuration.
    ///
    /// Networking and status-recovery dependencies are constructed internally.
    ///
    /// - Parameter configuration: Validated ``VenPaysConfiguration``.
    /// - Important: Do not pass merchant secret API keys. Initiation is server-to-server only.
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

    /// Checks whether Apple Pay can be used for the given trusted session.
    ///
    /// Distinguishes unsupported devices from devices that support Apple Pay but lack a
    /// configured card for the session networks and capabilities.
    ///
    /// - Parameter session: Trusted native payment session from your merchant backend.
    /// - Returns: A ``VenPaysApplePayAvailability`` value.
    public func applePayAvailability(
        for session: VenPaysNativePaymentSession
    ) -> VenPaysApplePayAvailability {
        availabilityService.availability(for: session)
    }

    /// Presents the Apple Pay sheet and authorizes the payment with VenPays.
    ///
    /// On success or accepted processing, returns a ``VenPaysPaymentResult``. User cancellation
    /// throws ``VenPaysError`` with ``VenPaysErrorCode/paymentCancelled``.
    ///
    /// - Parameters:
    ///   - session: Trusted session. Amount and currency are taken only from this value.
    ///   - presenter: Presenting view controller retained for API consistency; presentation uses
    ///     `PKPaymentAuthorizationController`.
    /// - Returns: Final or best-effort payment result, including `.unknown` when recovery exhausts.
    /// - Throws: ``VenPaysError`` for availability, presentation, token, network, or backend failures.
    /// - Important: Invoke only as a direct result of a user action (for example an Apple Pay button tap).
    /// - Note: Authorize uses a single idempotency key per logical attempt; transport retries reuse it.
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
