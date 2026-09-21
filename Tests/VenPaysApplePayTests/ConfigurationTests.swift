import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("Configuration")
struct ConfigurationTests {
    @Test func productionURL() throws {
        let config = try VenPaysConfiguration(environment: .production)
        #expect(config.environment.baseURL.absoluteString == "https://merchant.venpays.com")
    }

    @Test func defaultEnvironmentIsProduction() throws {
        let config = try VenPaysConfiguration()
        #expect(config.environment == .production)
        #expect(config.environment.baseURL == VenPaysEnvironment.defaultProductionURL)
    }

    @Test func customHTTPSURL() throws {
        let url = URL(string: "https://custom.example.com")!
        let config = try VenPaysConfiguration(environment: .custom(url))
        #expect(config.environment.baseURL == url)
    }

    @Test func customLocalhostHTTPAllowed() throws {
        let url = URL(string: "http://localhost:8080")!
        let config = try VenPaysConfiguration(environment: .custom(url))
        #expect(config.environment.baseURL == url)
    }

    @Test func invalidHTTPCustomURLRejected() {
        let url = URL(string: "http://api.example.com")!
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysConfiguration(environment: .custom(url))
        }
    }

    @Test func invalidTimeoutRejected() {
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysConfiguration(requestTimeout: 0)
        }
        #expect(throws: VenPaysError.self) {
            _ = try VenPaysConfiguration(requestTimeout: -1)
        }
    }

    @Test func sdkVersionIs011() {
        #expect(SDKVersion.current == "0.1.1")
        #expect(SDKVersion.userAgent == "VenPaysApplePay-iOS/0.1.1")
    }
}
