import SwiftUI
import PassKit

/// SwiftUI wrapper around the native `PKPaymentButton` via `UIViewRepresentable`.
///
/// - Warning: Do not replace this control with a custom “fake” Apple Pay button.
/// - Important: Start payment only from the button `action` (direct user tap). Obtain a
///   `UIViewController` presenter when calling ``VenPaysApplePayClient/presentApplePay(session:from:)``.
public struct SwiftUIApplePayButton: UIViewRepresentable {
    /// PassKit button type.
    public var type: ApplePayButtonType
    /// PassKit button style.
    public var style: ApplePayButtonStyle
    /// When `true`, duplicate taps are ignored.
    public var isPaymentInProgress: Bool
    /// User tap handler.
    public var action: () -> Void

    /// Creates a SwiftUI Apple Pay button.
    public init(
        type: ApplePayButtonType = .buy,
        style: ApplePayButtonStyle = .automatic,
        isPaymentInProgress: Bool = false,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.style = style
        self.isPaymentInProgress = isPaymentInProgress
        self.action = action
    }

    public func makeUIView(context: Context) -> ApplePayButton {
        let button = ApplePayButton(type: type, style: style)
        button.onTap = action
        button.isPaymentInProgress = isPaymentInProgress
        return button
    }

    public func updateUIView(_ uiView: ApplePayButton, context: Context) {
        uiView.onTap = action
        uiView.isPaymentInProgress = isPaymentInProgress
    }
}
