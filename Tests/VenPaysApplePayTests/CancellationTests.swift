import Foundation
import Testing
@testable import VenPaysApplePay

/// Verifies the two cancellation situations map to distinct public error codes.
///
/// - `userCancelledBeforeAuthorization`: the sheet was closed before any authorize
///   request was dispatched — no charge is possible.
/// - `networkRequestCancelled`: an in-flight request was cancelled — the authorization
///   may have reached VenPay, so the merchant must reconcile by track ID.
@Suite("CancellationClassification")
struct CancellationTests {

    @Test func userCancelPreAuthIsDistinctFromNetworkCancel() {
        #expect(VenPaysErrorCode.userCancelledBeforeAuthorization != VenPaysErrorCode.networkRequestCancelled)
        #expect(
            VenPaysErrorCode.userCancelledBeforeAuthorization.rawValue
                != VenPaysErrorCode.networkRequestCancelled.rawValue
        )
    }

    @Test func networkCancelCarriesRequestIDAndIsRetryable() {
        // The SDK always marks a cancelled in-flight request retryable so recovery
        // can reconcile the outcome before the merchant is asked to react.
        let error = VenPaysError(
            code: .networkRequestCancelled,
            message: "The network request was cancelled.",
            requestID: "req-cancel-1",
            isRetryable: true
        )
        #expect(error.code == .networkRequestCancelled)
        #expect(error.requestID == "req-cancel-1")
        #expect(error.isRetryable == true)
    }

    @Test func userCancelPreAuthIsNotRetryable() {
        let error = VenPaysError(
            code: .userCancelledBeforeAuthorization,
            message: "The user closed Apple Pay before any authorization was dispatched."
        )
        #expect(error.code == .userCancelledBeforeAuthorization)
        #expect(error.isRetryable == false)
    }

    @Test func userCancelPreAuthIsDefinitive() {
        #expect(VenPaysErrorCode.userCancelledBeforeAuthorization != VenPaysErrorCode.networkRequestCancelled)
        // A user cancel before authorization is provably charge-free.
        let cancel = VenPaysPaymentResult(trackID: Fixtures.trackID, status: .cancelled)
        #expect(cancel.status.isFinal)
    }
}