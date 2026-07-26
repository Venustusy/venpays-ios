import Foundation
import PassKit

/// Intermediate outcome of Apple Pay sheet authorization before/after backend calls.
enum ApplePayAuthorizationResult: Sendable, Equatable {
    case authorized(EncodedApplePayToken)
    case cancelled
    case presentationFailed(String)
}
