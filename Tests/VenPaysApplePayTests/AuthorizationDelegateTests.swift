import Foundation
import Testing
@testable import VenPaysApplePay

/// Verifies the public authorization lifecycle delegate contract.
///
/// The PassKit-dependent coordinator flow requires a physical device (real Apple
/// Pay authorization), so these tests validate the delegate contract and payload
/// threading directly.
@Suite("AuthorizationDelegate")
struct AuthorizationDelegateTests {

    @MainActor
    @Test func recordsAuthorizationStartedWithSession() throws {
        let delegate = MockAuthorizationDelegate()
        let session = try Fixtures.validSession()

        delegate.applePayAuthorizationDidStart(session: session)

        #expect(delegate.startedSessions.count == 1)
        #expect(delegate.startedSessions.first?.trackID == Fixtures.trackID)
        #expect(delegate.sentRequests.isEmpty)
    }

    @MainActor
    @Test func recordsRequestSentWithRequestID() throws {
        let delegate = MockAuthorizationDelegate()
        let session = try Fixtures.validSession()

        delegate.applePayAuthorizationRequestWasSent(requestID: "req-abc", session: session)

        #expect(delegate.sentRequests.count == 1)
        #expect(delegate.sentRequests.first?.requestID == "req-abc")
        #expect(delegate.sentRequests.first?.session.trackID == Fixtures.trackID)
        #expect(delegate.startedSessions.isEmpty)
    }

    @MainActor
    @Test func lifecycleOrderIsStartBeforeRequestSent() throws {
        let delegate = MockAuthorizationDelegate()
        let session = try Fixtures.validSession()

        delegate.applePayAuthorizationDidStart(session: session)
        delegate.applePayAuthorizationRequestWasSent(requestID: "req-123", session: session)

        #expect(delegate.eventOrder == [.started, .requestSent])
    }
}

/// Records delegate callbacks for lifecycle assertions.
@MainActor
private final class MockAuthorizationDelegate: VenPaysApplePayAuthorizationDelegate {
    enum Event: Equatable {
        case started
        case requestSent
    }

    struct SentRequest: Equatable {
        let requestID: String
        let session: VenPaysNativePaymentSession
    }

    private(set) var startedSessions: [VenPaysNativePaymentSession] = []
    private(set) var sentRequests: [SentRequest] = []
    private(set) var eventOrder: [Event] = []

    func applePayAuthorizationDidStart(session: VenPaysNativePaymentSession) {
        startedSessions.append(session)
        eventOrder.append(.started)
    }

    func applePayAuthorizationRequestWasSent(
        requestID: String,
        session: VenPaysNativePaymentSession
    ) {
        sentRequests.append(SentRequest(requestID: requestID, session: session))
        eventOrder.append(.requestSent)
    }
}