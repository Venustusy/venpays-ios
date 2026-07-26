import Foundation

/// VenPays API environment used by the SDK.
public enum VenPaysEnvironment: Sendable, Equatable {
    /// Sandbox API host. Default: `https://api.sandbox.venpays.com`
    case sandbox
    /// Production API host. Default: `https://api.venpays.com`
    case production
    /// Custom base URL. Use while sandbox/production hosts are being finalized.
    case custom(URL)

    /// Default sandbox base URL. Not assumed to be confirmed production infrastructure.
    public static let defaultSandboxURL = URL(string: "https://api.sandbox.venpays.com")!

    /// Default production base URL. Not assumed to be confirmed production infrastructure.
    public static let defaultProductionURL = URL(string: "https://api.venpays.com")!

    /// Resolved base URL for the selected environment.
    public var baseURL: URL {
        switch self {
        case .sandbox:
            return Self.defaultSandboxURL
        case .production:
            return Self.defaultProductionURL
        case .custom(let url):
            return url
        }
    }
}
