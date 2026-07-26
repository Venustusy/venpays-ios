import SwiftUI
import PassKit

/// SwiftUI wrapper around the native `PKPaymentButton` via `UIViewRepresentable`.
public struct SwiftUIApplePayButton: UIViewRepresentable {
    public var type: ApplePayButtonType
    public var style: ApplePayButtonStyle
    public var isPaymentInProgress: Bool
    public var action: () -> Void

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
