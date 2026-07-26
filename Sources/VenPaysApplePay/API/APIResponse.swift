import Foundation

struct APIResponse: Sendable {
    let statusCode: Int
    let data: Data
    let requestID: String
}
