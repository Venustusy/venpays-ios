import Foundation
import PassKit
import UIKit

/// Presents the Apple Pay sheet via `PKPaymentAuthorizationController` and
/// coordinates token encoding, backend authorization, and status recovery.
@MainActor
final class ApplePayCoordinator: NSObject {
    private let authorizer: any ApplePayPaymentAuthorizing
    private let recoverer: any PaymentStatusRecovering
    private let logger: Logger
    private weak var delegate: VenPaysApplePayAuthorizationDelegate?

    private var session: VenPaysNativePaymentSession?
    private var continuation: CheckedContinuation<VenPaysPaymentResult, Error>?
    private var didResumeContinuation = false
    private var didReceiveAuthorization = false
    private var authorizationCompletionCalled = false
    private var pendingResult: VenPaysPaymentResult?
    private var pendingError: Error?
    private var needsPostSheetRecovery = false
    private var idempotencyKey: String = ""
    private var controller: PKPaymentAuthorizationController?

    /// Retained for API consistency / future UIViewController-based fallback.
    private weak var presenter: UIViewController?

    init(
        authorizer: any ApplePayPaymentAuthorizing,
        recoverer: any PaymentStatusRecovering,
        logger: Logger,
        delegate: VenPaysApplePayAuthorizationDelegate? = nil
    ) {
        self.authorizer = authorizer
        self.recoverer = recoverer
        self.logger = logger
        self.delegate = delegate
    }

    func present(
        session: VenPaysNativePaymentSession,
        from presenter: UIViewController
    ) async throws -> VenPaysPaymentResult {
        if session.isExpired() {
            throw VenPaysError(code: .sessionExpired, message: "Native session token has expired.")
        }

        let request = try ApplePayPaymentRequestFactory.makeRequest(from: session)
        self.session = session
        self.presenter = presenter
        self.idempotencyKey = IdempotencyKey.generate()
        self.didResumeContinuation = false
        self.didReceiveAuthorization = false
        self.authorizationCompletionCalled = false
        self.pendingResult = nil
        self.pendingError = nil
        self.needsPostSheetRecovery = false

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        self.controller = controller

        logger.info("Presenting Apple Pay sheet trackID=\(session.trackID) sdk=\(SDKVersion.current)")

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.present { [weak self] presented in
                Task { @MainActor in
                    guard let self else { return }
                    if !presented {
                        self.finish(
                            with: .failure(
                                VenPaysError(
                                    code: .presentationFailed,
                                    message: "Apple Pay sheet failed to present."
                                )
                            )
                        )
                    } else {
                        self.delegate?.applePayAuthorizationDidStart(session: session)
                    }
                }
            }
        }
    }

    private func finish(with outcome: Result<VenPaysPaymentResult, Error>) {
        guard !didResumeContinuation else { return }
        didResumeContinuation = true
        controller?.delegate = nil
        controller = nil
        session = nil
        presenter = nil
        delegate = nil

        let cont = continuation
        continuation = nil
        switch outcome {
        case .success(let result):
            logger.info("Payment finished trackID=\(result.trackID) status=\(result.status.rawValue)")
            cont?.resume(returning: result)
        case .failure(let error):
            if let venPays = error as? VenPaysError {
                logger.error("Payment finished with error code=\(venPays.code.rawValue)")
            } else {
                logger.error("Payment finished with unexpected error type")
            }
            cont?.resume(throwing: error)
        }
    }

    private func mapAppleStatus(for status: VenPaysPaymentStatus) -> PKPaymentAuthorizationStatus {
        switch status {
        case .succeeded, .processing:
            return .success
        case .failed, .cancelled, .unknown:
            return .failure
        }
    }
}

extension ApplePayCoordinator: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        controller.dismiss {
            Task { @MainActor in
                await self.handleDidFinish()
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard !didReceiveAuthorization else {
            // Duplicate callback — acknowledge failure without resuming twice.
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        didReceiveAuthorization = true

        Task { @MainActor in
            await self.handleAuthorization(payment: payment, completion: completion)
        }
    }

    private func handleDidFinish() async {
        if !didReceiveAuthorization {
            finish(
                with: .failure(
                    VenPaysError(
                        code: .userCancelledBeforeAuthorization,
                        message: "The user closed Apple Pay before any authorization was dispatched."
                    )
                )
            )
            return
        }

        if let pendingError {
            finish(with: .failure(pendingError))
            return
        }

        guard var result = pendingResult else {
            finish(
                with: .failure(
                    VenPaysError(
                        code: .paymentStatusUnknown,
                        message: "Payment finished without a definitive result."
                    )
                )
            )
            return
        }

        if needsPostSheetRecovery, let session {
            do {
                result = try await recoverer.recover(session: session, seed: result)
            } catch {
                // Preserve unknown rather than inventing failure after uncertain authorize.
                if result.status != .succeeded && result.status != .failed && result.status != .cancelled {
                    result = VenPaysPaymentResult(
                        trackID: session.trackID,
                        status: .unknown,
                        transactionID: result.transactionID,
                        merchantReference: result.merchantReference,
                        amount: result.amount,
                        currency: result.currency,
                        paymentMethod: result.paymentMethod,
                        requestID: result.requestID,
                        backendError: result.backendError
                    )
                }
            }
        }

        finish(with: .success(result))
    }

    private func handleAuthorization(
        payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) async {
        guard let session else {
            callCompletion(completion, status: .failure)
            pendingError = VenPaysError(code: .invalidSession, message: "Payment session missing.")
            return
        }

        let token: EncodedApplePayToken
        do {
            token = try ApplePayTokenEncoder.encode(payment)
        } catch {
            callCompletion(completion, status: .failure)
            pendingError = error
            return
        }

        do {
            let requestID = RequestID.generate()
            delegate?.applePayAuthorizationRequestWasSent(requestID: requestID, session: session)
            let outcome = try await authorizer.authorize(
                session: session,
                token: token,
                idempotencyKey: idempotencyKey,
                requestID: requestID
            )
            pendingResult = outcome.result

            switch outcome.result.status {
            case .succeeded:
                callCompletion(completion, status: .success)
            case .failed, .cancelled:
                callCompletion(completion, status: .failure)
            case .processing:
                // Backend accepted authorization for processing — do not fail the sheet.
                callCompletion(completion, status: .success)
                needsPostSheetRecovery = true
            case .unknown:
                if outcome.authorizationMayHaveReachedBackend {
                    callCompletion(completion, status: .success)
                    needsPostSheetRecovery = true
                } else {
                    callCompletion(completion, status: mapAppleStatus(for: outcome.result.status))
                    needsPostSheetRecovery = outcome.requiresRecovery
                }
            }

            if outcome.requiresRecovery {
                needsPostSheetRecovery = true
            }
        } catch let error as VenPaysError {
            await handleAuthorizeFailure(
                error: error,
                session: session,
                completion: completion
            )
        } catch {
            callCompletion(completion, status: .failure)
            pendingError = VenPaysError(
                code: .internalError,
                message: "Unexpected authorization failure.",
                underlyingDescription: String(describing: type(of: error))
            )
        }
    }

    private func handleAuthorizeFailure(
        error: VenPaysError,
        session: VenPaysNativePaymentSession,
        completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) async {
        if error.code == .networkRequestCancelled {
            await handleNetworkCancellation(
                error: error,
                session: session,
                completion: completion
            )
            return
        }

        let uncertainCodes: Set<VenPaysErrorCode> = [
            .requestTimeout,
            .networkUnavailable,
            .invalidBackendResponse,
            .processorUnavailable,
            .paymentStatusUnknown
        ]

        if uncertainCodes.contains(error.code) {
            // Do not blindly report failure to Apple if the authorize may have reached VenPays.
            do {
                let recovered = try await recoverer.recover(session: session, seed: nil)
                pendingResult = recovered
                switch recovered.status {
                case .succeeded, .processing:
                    callCompletion(completion, status: .success)
                    needsPostSheetRecovery = recovered.status == .processing
                case .failed, .cancelled:
                    callCompletion(completion, status: .failure)
                case .unknown:
                    callCompletion(completion, status: .success)
                    needsPostSheetRecovery = true
                    pendingResult = VenPaysPaymentResult(
                        trackID: session.trackID,
                        status: .unknown,
                        requestID: error.requestID
                    )
                }
            } catch let recoveryError {
                callCompletion(completion, status: .success)
                needsPostSheetRecovery = true
                let recoveryRequestID = (recoveryError as? VenPaysError)?.requestID ?? error.requestID
                pendingResult = VenPaysPaymentResult(
                    trackID: session.trackID,
                    status: .unknown,
                    requestID: recoveryRequestID
                )
            }
            return
        }

        if error.code == .userCancelledBeforeAuthorization {
            callCompletion(completion, status: .failure)
            pendingError = error
            return
        }

        callCompletion(completion, status: .failure)
        pendingError = error
    }

    /// Reconciles an in-flight authorize request that was cancelled before its
    /// response arrived. The request may never have left the device, or it may
    /// have been captured by the processor, so the outcome is polled before any
    /// classification. When the outcome cannot be confirmed, the unresolved
    /// ``VenPaysErrorCode/networkRequestCancelled`` error is surfaced so the
    /// merchant can reconcile using the track ID instead of treating it as a
    /// definitive user cancellation.
    private func handleNetworkCancellation(
        error: VenPaysError,
        session: VenPaysNativePaymentSession,
        completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) async {
        do {
            let recovered = try await recoverer.recover(session: session, seed: nil)
            pendingResult = recovered
            switch recovered.status {
            case .succeeded:
                callCompletion(completion, status: .success)
            case .processing:
                callCompletion(completion, status: .success)
                needsPostSheetRecovery = true
            case .failed, .cancelled:
                callCompletion(completion, status: .failure)
            case .unknown:
                callCompletion(completion, status: .success)
                needsPostSheetRecovery = true
                pendingError = VenPaysError(
                    code: .networkRequestCancelled,
                    message: "The authorization request was cancelled and its outcome could not be confirmed. The authorization may have reached VenPay; reconcile using the track ID.",
                    requestID: error.requestID
                )
            }
        } catch let recoveryError {
            callCompletion(completion, status: .success)
            needsPostSheetRecovery = true
            let recoveryRequestID = (recoveryError as? VenPaysError)?.requestID ?? error.requestID
            pendingError = VenPaysError(
                code: .networkRequestCancelled,
                message: "The authorization request was cancelled and its outcome could not be confirmed. The authorization may have reached VenPay; reconcile using the track ID.",
                requestID: recoveryRequestID
            )
        }
    }

    private func callCompletion(
        _ completion: @escaping (PKPaymentAuthorizationResult) -> Void,
        status: PKPaymentAuthorizationStatus
    ) {
        guard !authorizationCompletionCalled else { return }
        authorizationCompletionCalled = true
        completion(PKPaymentAuthorizationResult(status: status, errors: nil))
    }
}
