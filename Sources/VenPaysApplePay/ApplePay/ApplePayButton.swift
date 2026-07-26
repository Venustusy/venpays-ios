import UIKit
import PassKit

/// UIKit wrapper around `PKPaymentButton`.
///
/// Prevents duplicate taps while a payment is in progress. Presentation must
/// only be started from a direct user action (button tap).
@MainActor
public final class ApplePayButton: UIView {
    public var onTap: (() -> Void)?
    public var isPaymentInProgress: Bool = false {
        didSet {
            isUserInteractionEnabled = !isPaymentInProgress
            paymentButton.alpha = isPaymentInProgress ? 0.6 : 1.0
        }
    }

    private let paymentButton: PKPaymentButton

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
