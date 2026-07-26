import SwiftUI
import VenPaysApplePay

struct ContentView: View {
    @StateObject private var viewModel = ExamplePaymentViewModel()
    @State private var presenter: UIViewController?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("VenPays Apple Pay Example")
                    .font(.title2.bold())

                Text("Fetches a native session from your merchant backend, then presents Apple Pay after a direct button tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let availability = viewModel.availabilityText {
                    Text(availability)
                        .font(.footnote)
                }

                if viewModel.isLoadingSession {
                    ProgressView("Loading session…")
                }

                if viewModel.isPaying {
                    ProgressView("Processing payment…")
                }

                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.body)
                        .foregroundStyle(viewModel.statusColor)
                }

                if viewModel.session != nil {
                    SwiftUIApplePayButton(
                        type: .buy,
                        style: .automatic,
                        isPaymentInProgress: viewModel.isPaying
                    ) {
                        guard let presenter else { return }
                        Task { await viewModel.startPayment(from: presenter) }
                    }
                    .frame(height: 48)
                }

                Button("Load payment session") {
                    Task { await viewModel.loadSession() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoadingSession || viewModel.isPaying)

                Spacer()
            }
            .padding()
            .navigationTitle("Checkout")
            .background(PresenterCapture(presenter: $presenter))
        }
    }
}

/// Captures a UIViewController for PassKit presentation from SwiftUI.
private struct PresenterCapture: UIViewControllerRepresentable {
    @Binding var presenter: UIViewController?

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            presenter = controller
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            presenter = uiViewController
        }
    }
}
