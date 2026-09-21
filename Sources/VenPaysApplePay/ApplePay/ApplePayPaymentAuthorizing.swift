import Foundation

/// Authorizes an Apple Pay token with VenPays.
protocol ApplePayPaymentAuthorizing: Sendable {
    func authorize(
        session: VenPaysNativePaymentSession,
        token: EncodedApplePayToken,
        idempotencyKey: String,
        requestID: String
    ) async throws -> AuthorizePaymentOutcome
}

/// Outcome of a backend authorize call including HTTP semantics.
struct AuthorizePaymentOutcome: Sendable, Equatable {
    let result: VenPaysPaymentResult
    let httpStatus: Int
    let requiresRecovery: Bool
    let authorizationMayHaveReachedBackend: Bool
}

/// Recovers payment status after processing / uncertain network outcomes.
protocol PaymentStatusRecovering: Sendable {
    func recover(
        session: VenPaysNativePaymentSession,
        seed: VenPaysPaymentResult?
    ) async throws -> VenPaysPaymentResult
}
