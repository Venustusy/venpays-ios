import Foundation
import Testing
@testable import VenPaysApplePay

/// Parent suite keeps MockURLProtocol static state from racing across suites.
@Suite("Networking", .serialized)
struct NetworkingTests {

    @Suite("APIClient")
    struct APIClientTests {
        init() {
            MockURLProtocol.reset()
        }

        @Test func authorizationHeadersAndBodyShape() async throws {
            MockURLProtocol.reset()
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Fixtures.token)")
                #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == "idem-1")
                #expect(request.value(forHTTPHeaderField: "X-Request-ID") != nil)
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
                #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
                #expect(request.value(forHTTPHeaderField: "User-Agent") == "VenPaysApplePay-iOS/0.1.0")
                #expect(request.url?.path.contains("/v1/sdk/apple-pay/payments/\(Fixtures.trackID)/authorize") == true)

                guard let bodyData = request.httpBody ?? request.venpays_httpBodyFromStream() else {
                    Issue.record("Missing HTTP body")
                    return .init(statusCode: 500, body: Data())
                }
                let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
                #expect(body?["payment_data"] != nil)
                #expect((body?["sdk"] as? [String: Any])?["platform"] as? String == "ios")

                return .init(statusCode: 200, body: Fixtures.authorizeSuccessBody())
            }

            let client = try makeClient()
            let session = try Fixtures.validSession()
            let outcome = try await client.authorize(
                session: session,
                token: Fixtures.encodedToken(),
                idempotencyKey: "idem-1"
            )
            #expect(outcome.result.status == .succeeded)
            #expect(outcome.httpStatus == 200)
            #expect(outcome.requiresRecovery == false)
        }

        @Test func accepts202Processing() async throws {
            MockURLProtocol.reset()
            MockURLProtocol.requestHandler = { _ in
                .init(statusCode: 202, body: Fixtures.authorizeSuccessBody(status: "processing"))
            }
            let client = try makeClient()
            let outcome = try await client.authorize(
                session: Fixtures.validSession(),
                token: Fixtures.encodedToken(),
                idempotencyKey: "idem-2"
            )
            #expect(outcome.httpStatus == 202)
            #expect(outcome.result.status == .processing)
            #expect(outcome.requiresRecovery == true)
        }

        @Test func structuredBackendErrorMapped() async throws {
            MockURLProtocol.reset()
            MockURLProtocol.requestHandler = { _ in
                .init(statusCode: 422, body: Fixtures.backendErrorBody(code: "invalid_payment_token"))
            }
            let client = try makeClient()
            do {
                _ = try await client.authorize(
                    session: Fixtures.validSession(),
                    token: Fixtures.encodedToken(),
                    idempotencyKey: "idem-3"
                )
                Issue.record("Expected error")
            } catch let error as VenPaysError {
                #expect(error.code == .invalidApplePayToken)
                #expect(error.requestID == "req-1")
                #expect(error.httpStatus == 422)
            }
        }

        @Test func malformedResponseThrows() async throws {
            MockURLProtocol.reset()
            MockURLProtocol.requestHandler = { _ in
                .init(statusCode: 200, body: Data("not-json".utf8))
            }
            let client = try makeClient()
            do {
                _ = try await client.authorize(
                    session: Fixtures.validSession(),
                    token: Fixtures.encodedToken(),
                    idempotencyKey: "idem-4"
                )
                Issue.record("Expected error")
            } catch let error as VenPaysError {
                #expect(error.code == .invalidBackendResponse)
                #expect(error.isRetryable == true)
            }
        }

        @Test func timeoutMapped() async throws {
            MockURLProtocol.reset()
            MockURLProtocol.requestHandler = { _ in
                .init(error: URLError(.timedOut))
            }
            let client = try makeClient(maxTransportRetries: 0)
            do {
                _ = try await client.authorize(
                    session: Fixtures.validSession(),
                    token: Fixtures.encodedToken(),
                    idempotencyKey: "idem-5"
                )
                Issue.record("Expected timeout")
            } catch let error as VenPaysError {
                #expect(error.code == .requestTimeout)
                #expect(error.isRetryable == true)
            }
        }

        @Test func transportRetryReusesIdempotencyKey() async throws {
            MockURLProtocol.reset()
            var callCount = 0
            MockURLProtocol.requestHandler = { request in
                callCount += 1
                #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == "idem-reuse")
                if callCount == 1 {
                    return .init(error: URLError(.networkConnectionLost))
                }
                return .init(statusCode: 200, body: Fixtures.authorizeSuccessBody())
            }

            let client = try makeClient(maxTransportRetries: 1)
            let outcome = try await client.authorize(
                session: Fixtures.validSession(),
                token: Fixtures.encodedToken(),
                idempotencyKey: "idem-reuse"
            )
            #expect(outcome.result.status == .succeeded)
            #expect(callCount == 2)
            #expect(MockURLProtocol.requests.count == 2)
        }

        private func makeClient(maxTransportRetries: Int = 1) throws -> APIClient {
            let config = try VenPaysConfiguration(
                environment: .custom(URL(string: "https://api.test.venpays.local")!),
                requestTimeout: 5,
                loggingEnabled: false
            )
            return APIClient(
                configuration: config,
                urlSession: MockSessionFactory.make(),
                logger: Logger(enabled: false),
                maxTransportRetries: maxTransportRetries
            )
        }
    }

    @Suite("RecoveryService")
    struct RecoveryServiceTests {
        init() {
            MockURLProtocol.reset()
        }

        @Test func immediateSuccess() async throws {
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
            MockURLProtocol.reset()
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
                sleepHandler: { _ in }
            )
        }
    }
}
