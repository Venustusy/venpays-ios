import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

enum APIEndpoint: Sendable {
    case authorize(trackID: String)
    case paymentStatus(trackID: String)

    var path: String {
        switch self {
        case .authorize(let trackID):
            return "/v1/sdk/apple-pay/payments/\(trackID)/authorize"
        case .paymentStatus(let trackID):
            return "/v1/sdk/apple-pay/payments/\(trackID)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .authorize:
            return .post
        case .paymentStatus:
            return .get
        }
    }
}
