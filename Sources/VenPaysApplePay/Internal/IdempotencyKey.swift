import Foundation

/// Generates idempotency keys for logical payment authorization attempts.
enum IdempotencyKey {
    static func generate() -> String {
        UUID().uuidString.lowercased()
    }
}
