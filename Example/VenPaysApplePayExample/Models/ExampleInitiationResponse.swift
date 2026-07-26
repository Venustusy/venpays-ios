import Foundation
import VenPaysApplePay

/// Mirrors the merchant-facing initiation payload if you decode before constructing a session.
struct ExampleInitiationResponse: Decodable {
    let trackID: String
    let nativeSessionToken: String
    let expiresAt: Date
    let amount: String
    let currency: String
    let merchantReference: String?
    let applePay: VenPaysApplePayConfiguration
    let success: Bool?

    enum CodingKeys: String, CodingKey {
        case trackID = "track_id"
        case nativeSessionToken = "native_session_token"
        case expiresAt = "expires_at"
        case amount
        case currency
        case merchantReference = "merchant_reference"
        case applePay = "apple_pay"
        case success
    }
}
