import Foundation

/// VenPays API environment used by the SDK.
///
/// There is no sandbox environment case. Apple Pay sandbox is unavailable in some regions;
/// production traffic uses ``production``.
public enum VenPaysEnvironment: Sendable, Equatable {
    /// Production API host (`https://merchant.venpays.com`).
    case production
    /// Custom base URL for tests or temporary overrides.
    ///
    /// - Important: Non-localhost URLs must use HTTPS.
    case custom(URL)

    /// Default production base URL.
    public static let defaultProductionURL = URL(string: "https://merchant.venpays.com")!

    /// Resolved base URL for the selected environment.
    public var baseURL: URL {
        switch self {
        case .production:
            return Self.defaultProductionURL
        case .custom(let url):
            return url
        }
    }
}
