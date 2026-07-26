import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("RecoveryService")
struct RecoveryServiceTests {
    init() {
        MockURLProtocol.reset()
    }

    @Test func immediateSuccess() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Fixtures.token)")
            #expect(request.value(forHTTPHeaderField: "X-Request-ID") != nil)
            #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == nil)
            return .init(statusCode: 200, body: Fixtures.statusBody(status: "succeeded"))
        }

        let result = try await makeService().recover(session: Fixtures.validSession(), seed: nil)
        #expect(result.status == .succeeded)
        #expect(result.transactionID == "txn_123")
    }

    @Test func processingThenSuccess() async throws {
        var call = 0
        MockURLProtocol.requestHandler = { _ in
            call += 1
            if call == 1 {
                return .init(statusCode: 200, body: Fixtures.statusBody(status: "processing"))
            }
            return .init(statusCode: 200, body: Fixtures.statusBody(status: "succeeded"))
        }

        let result = try await makeService(maxAttempts: 3).recover(
            session: Fixtures.validSession(),
            seed: VenPaysPaymentResult(trackID: Fixtures.trackID, status: .processing)
        )
        #expect(result.status == .succeeded)
        #expect(call == 2)
    }

    @Test func processingThenFailure() async throws {
        var call = 0
        MockURLProtocol.requestHandler = { _ in
            call += 1
            if call == 1 {
                return .init(statusCode: 200, body: Fixtures.statusBody(status: "pending"))
            }
            return .init(statusCode: 200, body: Fixtures.statusBody(status: "failed"))
        }

        let result = try await makeService(maxAttempts: 3).recover(
            session: Fixtures.validSession(),
            seed: nil
        )
        #expect(result.status == .failed)
    }

    @Test func timeoutExhaustionReturnsUnknown() async throws {
        MockURLProtocol.requestHandler = { _ in
            .init(statusCode: 200, body: Fixtures.statusBody(status: "processing"))
        }

        let result = try await makeService(
            maxAttempts: 2,
            overallTimeout: 0.01,
            initialDelay: 0
        ).recover(session: Fixtures.validSession(), seed: nil)
        #expect(result.status == .unknown)
    }

    @Test func authenticationFailureSurfaces() async throws {
        MockURLProtocol.requestHandler = { _ in
            .init(statusCode: 401, body: Fixtures.backendErrorBody(code: "unauthorized"))
        }

        do {
            _ = try await makeService().recover(session: Fixtures.validSession(), seed: nil)
            Issue.record("Expected unauthorized")
        } catch let error as VenPaysError {
            #expect(error.code == .unauthorized)
        }
    }

    @Test func sessionExpiryBeforeRecovery() async throws {
        let session = try Fixtures.validSession(expiresAt: Date().addingTimeInterval(30))
        let config = try VenPaysConfiguration(
            environment: .custom(URL(string: "https://api.test.venpays.local")!),
            statusRecoveryPolicy: PaymentRecoveryPolicy(
                initialDelay: 0,
                maximumDelay: 0,
                maximumAttempts: 1,
                overallTimeout: 5,
                jitterFraction: 0
            )
        )
        let api = APIClient(
            configuration: config,
            urlSession: MockSessionFactory.make(),
            maxTransportRetries: 0
        )
        let service = PaymentStatusRecoveryService(
            apiClient: api,
            policy: config.statusRecoveryPolicy,
            sleepHandler: { _ in },
            now: { session.expiresAt.addingTimeInterval(1) }
        )

        do {
            _ = try await service.recover(session: session, seed: nil)
            Issue.record("Expected sessionExpired")
        } catch let error as VenPaysError {
            #expect(error.code == .sessionExpired)
        }
    }

    @Test func maximumAttemptsHonored() async throws {
        var calls = 0
        MockURLProtocol.requestHandler = { _ in
            calls += 1
            return .init(statusCode: 200, body: Fixtures.statusBody(status: "processing"))
        }
        let result = try await makeService(maxAttempts: 3, initialDelay: 0).recover(
            session: Fixtures.validSession(),
            seed: nil
        )
        #expect(result.status == .unknown)
        #expect(calls == 3)
    }

    @Test func seedFinalShortCircuits() async throws {
        MockURLProtocol.requestHandler = { _ in
            Issue.record("Should not call network")
            return .init(statusCode: 500, body: Data())
        }
        let seed = VenPaysPaymentResult(trackID: Fixtures.trackID, status: .succeeded, transactionID: "t")
        let result = try await makeService().recover(session: Fixtures.validSession(), seed: seed)
        #expect(result.status == .succeeded)
        #expect(MockURLProtocol.requests.isEmpty)
    }

    private func makeService(
        maxAttempts: Int = 5,
        overallTimeout: TimeInterval = 15,
        initialDelay: TimeInterval = 0
    ) throws -> PaymentStatusRecoveryService {
        let policy = PaymentRecoveryPolicy(
            initialDelay: initialDelay,
            maximumDelay: 0.01,
            multiplier: 2,
            maximumAttempts: maxAttempts,
            overallTimeout: overallTimeout,
            jitterFraction: 0
        )
        let config = try VenPaysConfiguration(
            environment: .custom(URL(string: "https://api.test.venpays.local")!),
            statusRecoveryPolicy: policy
        )
        let api = APIClient(
            configuration: config,
            urlSession: MockSessionFactory.make(),
            maxTransportRetries: 0
        )
        return PaymentStatusRecoveryService(
            apiClient: api,
            policy: policy,
            sleepHandler: { _ in /* no-op for fast tests when delay already 0; still allow tiny sleeps */ }
        )
    }
}
