import Foundation

/// Controls exponential backoff when recovering payment status after uncertain authorization.
public struct PaymentRecoveryPolicy: Sendable, Equatable {
    /// Delay before the first recovery attempt.
    public var initialDelay: TimeInterval
    /// Upper bound for backoff delay between attempts.
    public var maximumDelay: TimeInterval
    /// Multiplier applied after each attempt.
    public var multiplier: Double
    /// Maximum number of status poll attempts.
    public var maximumAttempts: Int
    /// Overall wall-clock timeout for recovery.
    public var overallTimeout: TimeInterval
    /// Optional bounded jitter fraction in `[0, 1)`. Inject `0` in unit tests.
    public var jitterFraction: Double

    public init(
        initialDelay: TimeInterval = 0.5,
        maximumDelay: TimeInterval = 4,
        multiplier: Double = 2,
        maximumAttempts: Int = 5,
        overallTimeout: TimeInterval = 15,
        jitterFraction: Double = 0
    ) {
        self.initialDelay = initialDelay
        self.maximumDelay = maximumDelay
        self.multiplier = multiplier
        self.maximumAttempts = maximumAttempts
        self.overallTimeout = overallTimeout
        self.jitterFraction = max(0, min(jitterFraction, 0.999))
    }

    /// Computes the delay before the given 1-based attempt index.
    public func delay(beforeAttempt attempt: Int) -> TimeInterval {
        guard attempt > 1 else { return initialDelay }
        let exponent = Double(attempt - 1)
        let raw = initialDelay * pow(multiplier, exponent - 1)
        let capped = min(raw, maximumDelay)
        guard jitterFraction > 0 else { return capped }
        let jitter = capped * jitterFraction * Double.random(in: 0..<1)
        return min(capped + jitter, maximumDelay)
    }
}
