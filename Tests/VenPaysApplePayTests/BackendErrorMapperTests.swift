import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("BackendErrorMapper")
struct BackendErrorMapperTests {
    @Test func mapsKnownBackendCodes() {
        let pairs: [(String, VenPaysErrorCode)] = [
            ("invalid_payment_token", .invalidApplePayToken),
            ("idempotency_key_required", .idempotencyConflict),
            ("unauthorized", .unauthorized),
            ("invalid_native_session", .unauthorized),
            ("native_session_expired", .sessionExpired),
            ("wrong_track_id", .invalidSession),
            ("apple_pay_not_enabled", .invalidApplePayConfiguration),
            ("idempotency_conflict", .idempotencyConflict),
            ("payment_already_processing", .paymentAlreadyProcessing),
            ("payment_already_completed", .paymentAlreadyCompleted),
            ("processor_declined", .processorDeclined),
            ("processor_unavailable", .processorUnavailable),
            ("processor_timeout", .requestTimeout),
            ("internal_error", .internalError)
        ]

        for (backend, expected) in pairs {
            let error = BackendErrorMapper.map(
                backendCode: backend,
                message: "m",
                httpStatus: 400,
                requestID: "r"
            )
            #expect(error.code == expected)
        }
    }

    @Test func retryableFlags() {
        let timeout = BackendErrorMapper.map(
            backendCode: "processor_timeout",
            message: "t",
            httpStatus: 504,
            requestID: nil
        )
        #expect(timeout.isRetryable == true)

        let declined = BackendErrorMapper.map(
            backendCode: "processor_declined",
            message: "d",
            httpStatus: 402,
            requestID: nil
        )
        #expect(declined.isRetryable == false)
    }

    @Test func sessionDoesNotExposeTokenInErrorOrDescription() throws {
        let session = try Fixtures.validSession()
        #expect(!String(describing: session).contains(Fixtures.token))
        let error = VenPaysError(code: .unauthorized, message: "denied", requestID: "abc")
        #expect(!error.description.contains(Fixtures.token))
        #expect(error.description.contains("unauthorized"))
    }
}
