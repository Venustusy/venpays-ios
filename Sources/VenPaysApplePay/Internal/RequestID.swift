import Foundation

/// Generates opaque request identifiers for backend correlation.
enum RequestID {
    static func generate() -> String {
        UUID().uuidString.lowercased()
    }
}
