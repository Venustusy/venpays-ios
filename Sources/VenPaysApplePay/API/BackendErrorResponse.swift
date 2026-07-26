import Foundation

struct BackendErrorResponse: Decodable, Sendable, Equatable {
    let error: BackendErrorBody

    struct BackendErrorBody: Decodable, Sendable, Equatable {
        let code: String
        let message: String
        let requestID: String?
        let details: [String: AnyCodable]?

        enum CodingKeys: String, CodingKey {
            case code
            case message
            case requestID = "request_id"
            case details
        }
    }
}
