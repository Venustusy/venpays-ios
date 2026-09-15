import Foundation
import SwiftUI
import UIKit
import VenPaysApplePay

@MainActor
final class ExamplePaymentViewModel: ObservableObject {
    @Published var session: VenPaysNativePaymentSession?
    @Published var isLoadingSession = false
    @Published var isPaying = false
    @Published var statusMessage: String?
    @Published var statusColor: Color = .primary
    @Published var availabilityText: String?

    private let merchantBackend = ExampleMerchantBackendClient()
    private let client: VenPaysApplePayClient
    private let lifecycleTracker = ExampleLifecycleTracker()

    init() {
        let configuration = try! VenPaysConfiguration(
            environment: .production,
            loggingEnabled: true
        )
        self.client = VenPaysApplePayClient(configuration: configuration)
    }

    func loadSession() async {
        isLoadingSession = true
        statusMessage = nil
        defer { isLoadingSession = false }

        do {
            let session = try await merchantBackend.fetchNativeSession()
            self.session = session
            let availability = client.applePayAvailability(for: session)
            availabilityText = "Availability: \(String(describing: availability))"
            statusMessage = "Session ready for \(session.currency) \(session.amount)"
            statusColor = .primary
        } catch {
            statusMessage = "Failed to load session: \(error.localizedDescription)"
            statusColor = .red
        }
    }

    func startPayment(from presenter: UIViewController) async {
        guard let session else {
            statusMessage = "Load a session first."
            statusColor = .orange
            return
        }
        guard !isPaying else { return }

        isPaying = true
        defer { isPaying = false }

        do {
            let result = try await client.presentApplePay(
                session: session,
                from: presenter,
                delegate: lifecycleTracker
            )
            apply(result: result)
        } catch let error as VenPaysError where error.code == .paymentCancelled {
            statusMessage = "Payment cancelled."
            statusColor = .orange
        } catch let error as VenPaysError {
            statusMessage = "Error (\(error.code.rawValue)): \(error.message)"
            statusColor = .red
        } catch {
            statusMessage = "Unexpected error: \(error.localizedDescription)"
            statusColor = .red
        }
    }

    private func apply(result: VenPaysPaymentResult) {
        switch result.status {
        case .succeeded:
            statusMessage = "Success. transactionID=\(result.transactionID ?? "nil")"
            statusColor = .green
        case .failed:
            statusMessage = "Failed. \(result.backendError?.message ?? "")"
            statusColor = .red
        case .cancelled:
            statusMessage = "Cancelled."
            statusColor = .orange
        case .processing:
            statusMessage = "Processing… trackID=\(result.trackID)"
            statusColor = .blue
        case .unknown:
            statusMessage = "Unknown status after recovery. Reconcile trackID=\(result.trackID)"
            statusColor = .purple
        }
    }
}

/// Example lifecycle observer that logs authorization events.
@MainActor
private final class ExampleLifecycleTracker: VenPaysApplePayAuthorizationDelegate {
    func applePayAuthorizationDidStart(session: VenPaysNativePaymentSession) {
        print("Apple Pay authorization started for trackID=\(session.trackID)")
    }

    func applePayAuthorizationRequestWasSent(requestID: String, session: VenPaysNativePaymentSession) {
        print("Authorization request sent requestID=\(requestID) trackID=\(session.trackID)")
    }
}
