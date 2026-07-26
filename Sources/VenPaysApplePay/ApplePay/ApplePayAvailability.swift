import Foundation

/// Result of checking whether Apple Pay can be used for a session.
public enum VenPaysApplePayAvailability: Sendable, Equatable {
    /// Device supports Apple Pay and has a card configured for the session networks/capabilities.
    case available
    /// Device supports Apple Pay but no card is configured for the required networks/capabilities.
    case supportedButNoConfiguredCard
    /// Device cannot make Apple Pay payments at all.
    case unsupportedDevice
    /// Session Apple Pay configuration cannot be mapped to usable PassKit values.
    case invalidMerchantConfiguration
    /// Native session token has expired.
    case sessionExpired
}
