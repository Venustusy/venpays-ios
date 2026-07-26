import Foundation
import os.log

/// Internal diagnostic logger. Never logs secrets, tokens, or payment payloads.
struct Logger: Sendable {
    private let enabled: Bool
    private let subsystem = "com.venpays.applepay"
    private let category: String

    init(enabled: Bool, category: String = "SDK") {
        self.enabled = enabled
        self.category = category
    }

    func debug(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: .debug, message())
    }

    func info(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: .info, message())
    }

    func error(_ message: @autoclosure () -> String) {
        guard enabled else { return }
        os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: .error, message())
    }
}
