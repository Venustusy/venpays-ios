import Foundation

/// Parses decimal amount strings from backend responses.
enum DecimalParser {
    /// Parses a decimal string (e.g. `"10.000"`) into a `Decimal`.
    static func parse(_ string: String) throws -> Decimal {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VenPaysError(
                code: .invalidAmount,
                message: "Amount string is empty."
            )
        }

        var decimal = Decimal()
        let success = Scanner(string: trimmed).scanDecimal(&decimal)
        guard success else {
            throw VenPaysError(
                code: .invalidAmount,
                message: "Amount string is not a valid decimal."
            )
        }
        return decimal
    }

    /// Formats a decimal for Apple Pay / display using a fixed scale when possible.
    static func format(_ decimal: Decimal, scale: Int = 3) -> String {
        var value = decimal
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, scale, .plain)
        let number = NSDecimalNumber(decimal: rounded)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = scale
        formatter.maximumFractionDigits = scale
        return formatter.string(from: number) ?? "\(rounded)"
    }
}
