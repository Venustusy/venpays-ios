import Foundation
import PassKit

/// Apple Pay button visual style mapped to `PKPaymentButtonStyle`.
public enum ApplePayButtonStyle: Sendable, Equatable {
    /// System automatic style.
    case automatic
    /// Black style.
    case black
    /// White style.
    case white
    /// White outline style.
    case whiteOutline

    var pkStyle: PKPaymentButtonStyle {
        switch self {
        case .automatic:
            if #available(iOS 14.0, *) {
                return .automatic
            }
            return .black
        case .black:
            return .black
        case .white:
            return .white
        case .whiteOutline:
            return .whiteOutline
        }
    }
}

/// Apple Pay button type mapped to `PKPaymentButtonType`.
///
/// Always rendered via `PKPaymentButton` — never a custom facsimile.
public enum ApplePayButtonType: Sendable, Equatable {
    case plain
    case buy
    case checkout
    case donate
    case `continue`
    case order
    /// Closest PassKit mapping is `.checkout` (PassKit has no dedicated `.pay` type).
    case pay
    case subscribe

    var pkType: PKPaymentButtonType {
        switch self {
        case .plain:
            return .plain
        case .buy:
            return .buy
        case .checkout:
            return .checkout
        case .donate:
            return .donate
        case .continue:
            if #available(iOS 15.0, *) {
                return .continue
            }
            return .plain
        case .order:
            if #available(iOS 14.0, *) {
                return .order
            }
            return .buy
        case .pay:
            return .checkout
        case .subscribe:
            if #available(iOS 14.0, *) {
                return .subscribe
            }
            return .buy
        }
    }
}
