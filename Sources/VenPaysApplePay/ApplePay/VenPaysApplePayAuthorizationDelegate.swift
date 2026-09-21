import Foundation

/// Delegate that receives Apple Pay authorization lifecycle events.
///
/// All methods are called on the main actor. Implementations should avoid
/// long-running work that could block the Apple Pay sheet.
///
/// - Note: The SDK holds a strong reference to the delegate for the duration
///   of a single `presentApplePay` call. The reference is released when the
///   authorization flow completes or fails.
@MainActor
public protocol VenPaysApplePayAuthorizationDelegate: AnyObject {
    /// Called when the Apple Pay authorization flow begins.
    ///
    /// This fires after the Apple Pay sheet has been presented and is visible
    /// to the user, but before the user authorizes or cancels.
    ///
    /// - Parameter session: The trusted session being authorized.
    func applePayAuthorizationDidStart(
        session: VenPaysNativePaymentSession
    )

    /// Called when the authorization request has been sent to VenPays.
    ///
    /// Use the `requestID` to correlate this request with VenPays transaction
    /// logs and webhook payloads.
    ///
    /// - Parameters:
    ///   - requestID: The ``X-Request-ID`` sent in the authorize HTTP request.
    ///   - session: The trusted session being authorized.
    func applePayAuthorizationRequestWasSent(
        requestID: String,
        session: VenPaysNativePaymentSession
    )
}
