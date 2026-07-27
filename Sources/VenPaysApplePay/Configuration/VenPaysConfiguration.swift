import Foundation

/// Client configuration for VenPays Apple Pay.
///
/// Construct once and pass to ``VenPaysApplePayClient``. Invalid timeouts or non-HTTPS custom
/// base URLs (except localhost) throw ``VenPaysError`` with ``VenPaysErrorCode/invalidConfiguration``.
public struct VenPaysConfiguration: Sendable, Equatable {
    /// API environment (production or custom URL).
    public var environment: VenPaysEnvironment

    /// URLSession request timeout in seconds. Must be greater than zero.
    public var requestTimeout: TimeInterval

    /// Policy controlling payment status recovery after uncertain authorization outcomes.
    public var statusRecoveryPolicy: PaymentRecoveryPolicy

    /// Enables internal diagnostic logging. Disabled by default.
    ///
    /// - Warning: Even when enabled, the SDK must not log tokens, payment data, signatures,
    ///   or Authorization headers.
    public var loggingEnabled: Bool

    /// Creates a configuration.
    ///
    /// - Parameters:
    ///   - environment: API environment. Defaults to ``VenPaysEnvironment/production``.
    ///   - requestTimeout: Request timeout in seconds. Defaults to `30`.
    ///   - statusRecoveryPolicy: Recovery backoff policy. Defaults to ``PaymentRecoveryPolicy``.
    ///   - loggingEnabled: Whether diagnostic logging is enabled. Defaults to `false`.
    /// - Throws: ``VenPaysError`` when validation fails.
    public init(
        environment: VenPaysEnvironment = .production,
        requestTimeout: TimeInterval = 30,
        statusRecoveryPolicy: PaymentRecoveryPolicy = PaymentRecoveryPolicy(),
        loggingEnabled: Bool = false
    ) throws {
        try Self.validate(environment: environment, requestTimeout: requestTimeout)
        self.environment = environment
        self.requestTimeout = requestTimeout
        self.statusRecoveryPolicy = statusRecoveryPolicy
        self.loggingEnabled = loggingEnabled
    }

    /// Validates environment and timeout constraints.
    ///
    /// - Parameters:
    ///   - environment: Environment whose base URL is checked.
    ///   - requestTimeout: Timeout that must be greater than zero.
    /// - Throws: ``VenPaysError`` with ``VenPaysErrorCode/invalidConfiguration``.
    public static func validate(
        environment: VenPaysEnvironment,
        requestTimeout: TimeInterval
    ) throws {
        guard requestTimeout > 0 else {
            throw VenPaysError(
                code: .invalidConfiguration,
                message: "requestTimeout must be greater than zero."
            )
        }

        let url = environment.baseURL
        guard let scheme = url.scheme?.lowercased() else {
            throw VenPaysError(
                code: .invalidConfiguration,
                message: "Custom environment URL must include a scheme."
            )
        }

        let host = (url.host ?? "").lowercased()
        let isLocalhost = host == "localhost" || host == "127.0.0.1" || host == "::1"
        if scheme != "https" && !(scheme == "http" && isLocalhost) {
            throw VenPaysError(
                code: .invalidConfiguration,
                message: "Custom environment URL must use HTTPS, except localhost for tests."
            )
        }
    }
}
