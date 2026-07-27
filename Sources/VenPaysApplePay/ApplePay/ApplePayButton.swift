import UIKit
import PassKit

/// UIKit wrapper around `PKPaymentButton`.
///
/// Prevents duplicate taps while a payment is in progress. Presentation must
/// only be started from a direct user action (button tap).
///
/// - Important: This type is main-actor isolated.
/// - Warning: Do not replace this control with a custom “fake” Apple Pay button.
@MainActor
public final class ApplePayButton: UIView {
    /// Invoked when the user taps the Apple Pay button and payment is not already in progress.
    public var onTap: (() -> Void)?

    /// When `true`, ignores taps and dims the button to prevent duplicate payment starts.
    public var isPaymentInProgress: Bool = false {
        didSet {
            isUserInteractionEnabled = !isPaymentInProgress
            paymentButton.alpha = isPaymentInProgress ? 0.6 : 1.0
        }
    }

    private let paymentButton: PKPaymentButton

    /// Creates an Apple Pay button using official PassKit styling.
    ///
    /// - Parameters:
    ///   - type: Button type. Defaults to ``ApplePayButtonType/buy``.
    ///   - style: Button style. Defaults to ``ApplePayButtonStyle/automatic``.
    public init(
        type: ApplePayButtonType = .buy,
        style: ApplePayButtonStyle = .automatic
    ) {
        paymentButton = PKPaymentButton(paymentButtonType: type.pkType, paymentButtonStyle: style.pkStyle)
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setup() {
        paymentButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(paymentButton)
        NSLayoutConstraint.activate([
            paymentButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            paymentButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            paymentButton.topAnchor.constraint(equalTo: topAnchor),
            paymentButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        paymentButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        accessibilityIdentifier = "VenPaysApplePayButton"
    }

    @objc private func handleTap() {
        guard !isPaymentInProgress else { return }
        onTap?()
    }
}
