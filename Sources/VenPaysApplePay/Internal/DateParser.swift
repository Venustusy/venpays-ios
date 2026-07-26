import Foundation

/// Parses ISO-8601 expiry timestamps from backend responses.
enum DateParser {
    private static let lock = NSLock()

    nonisolated(unsafe) private static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parseISO8601(_ string: String) throws -> Date {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        lock.lock()
        defer { lock.unlock() }
        if let date = fractional.date(from: trimmed) ?? standard.date(from: trimmed) {
            return date
        }
        throw VenPaysError(
            code: .invalidSession,
            message: "expires_at is not a valid ISO-8601 date."
        )
    }

    static func formatISO8601(_ date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return fractional.string(from: date)
    }
}
