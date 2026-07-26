import Foundation

struct APIRequest: Sendable {
    let endpoint: APIEndpoint
    let bearerToken: String
    let idempotencyKey: String?
    let requestID: String
    let body: Data?

    func urlRequest(baseURL: URL, timeout: TimeInterval) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw VenPaysError(code: .invalidConfiguration, message: "Invalid base URL.")
        }
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpointPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            components.path = "/" + endpointPath
        } else {
            components.path = "/" + basePath + "/" + endpointPath
        }
        guard let url = components.url else {
            throw VenPaysError(code: .invalidConfiguration, message: "Unable to build request URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = timeout
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(SDKVersion.userAgent, forHTTPHeaderField: "User-Agent")
        if let idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
