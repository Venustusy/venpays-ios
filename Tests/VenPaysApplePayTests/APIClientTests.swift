import Foundation
import Testing
@testable import VenPaysApplePay

@Suite("APIClient")
struct APIClientTests {
    init() {
        MockURLProtocol.reset()
    }

    @Test func authorizationHeadersAndBodyShape() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Fixtures.token)")
            #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == "idem-1")
            #expect(request.value(forHTTPHeaderField: "X-Request-ID") != nil)
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "User-Agent") == "VenPaysApplePay-iOS/0.1.0")
            #expect(request.url?.path.contains("/v1/sdk/apple-pay/payments/\(Fixtures.trackID)/authorize") == true)

            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
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
