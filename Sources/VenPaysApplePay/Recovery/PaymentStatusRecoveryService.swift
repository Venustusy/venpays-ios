import Foundation

/// Polls VenPays payment status with exponential backoff after uncertain authorization outcomes.
struct PaymentStatusRecoveryService: PaymentStatusRecovering, Sendable {
    private let apiClient: APIClient
    private let policy: PaymentRecoveryPolicy
    private let logger: Logger
    private let sleepHandler: @Sendable (TimeInterval) async throws -> Void
    private let now: @Sendable () -> Date

    init(
        apiClient: APIClient,
        policy: PaymentRecoveryPolicy,
        logger: Logger = Logger(enabled: false),
        sleepHandler: @escaping @Sendable (TimeInterval) async throws -> Void = { nanoseconds in
            let ns = UInt64(max(0, nanoseconds) * 1_000_000_000)
            try await Task.sleep(nanoseconds: ns)
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiClient = apiClient
        self.policy = policy
        self.logger = logger
        self.sleepHandler = sleepHandler
        self.now = now
    }

    func recover(
        session: VenPaysNativePaymentSession,
        seed: VenPaysPaymentResult?
    ) async throws -> VenPaysPaymentResult {
        if let seed, seed.status.isFinal {
            return seed
        }

        if session.isExpired(now: now()) {
            throw VenPaysError(
                code: .sessionExpired,
                message: "Native session token expired before status recovery completed."
            )
        }

        let started = now()
        var lastResult = seed
        var lastError: VenPaysError?

        for attempt in 1...policy.maximumAttempts {
            if now().timeIntervalSince(started) > policy.overallTimeout {
                break
            }

            if session.isExpired(now: now()) {
                throw VenPaysError(
                    code: .sessionExpired,
                    message: "Native session token expired during status recovery."
                )
            }

            let delay = policy.delay(beforeAttempt: attempt)
            if delay > 0 {
                try await sleepHandler(delay)
            }

            if now().timeIntervalSince(started) > policy.overallTimeout {
                break
            }

            do {
                let result = try await apiClient.fetchStatus(session: session)
                lastResult = result
                logger.info(
                    "Recovery attempt=\(attempt) trackID=\(session.trackID) status=\(result.status.rawValue)"
                )
                if result.status.isFinal {
                    return result
                }
            } catch let error as VenPaysError {
                lastError = error
                logger.error(
                    "Recovery attempt=\(attempt) failed code=\(error.code.rawValue)"
                )
                if error.code == .unauthorized || error.code == .sessionExpired {
                    throw error
                }
                if !error.isRetryable {
                    throw error
                }
            }
        }

        if let lastResult, lastResult.status.isFinal {
            return lastResult
        }

        if let lastError, lastError.code == .unauthorized || lastError.code == .sessionExpired {
            throw lastError
        }

        return VenPaysPaymentResult(
            trackID: session.trackID,
            status: .unknown,
            transactionID: lastResult?.transactionID,
            merchantReference: lastResult?.merchantReference ?? session.merchantReference,
            amount: lastResult?.amount ?? session.amount,
            currency: lastResult?.currency ?? session.currency,
            paymentMethod: lastResult?.paymentMethod,
            requestID: lastResult?.requestID ?? lastError?.requestID,
            backendError: lastResult?.backendError
        )
    }
}
