import Foundation
import VenPaysApplePay

/// Calls the merchant backend only. Never sends VenPays X-API-KEY from the app.
actor ExampleMerchantBackendClient {
    /// Placeholder merchant endpoint — replace with your backend.
    static let sessionURL = URL(
        string: "https://merchant.example.com/api/payments/apple-pay/session"
    )!

    func fetchNativeSession() async throws -> VenPaysNativePaymentSession {
        var request = URLRequest(url: Self.sessionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // No X-API-KEY here. Your backend holds the VenPays merchant secret.

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Prefer decoding directly into the SDK session model.
        return try JSONDecoder().decode(VenPaysNativePaymentSession.self, from: data)
    }
}
