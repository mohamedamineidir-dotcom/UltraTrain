import Foundation
import os

final class AnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var isEnabled = true

    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        lock.lock()
        let enabled = isEnabled
        lock.unlock()

        guard enabled else { return }
        Logger.analyticsLog.info("Event: \(event.rawValue) \(properties.isEmpty ? "" : properties.description)")
    }

    func setTrackingEnabled(_ enabled: Bool) {
        lock.lock()
        isEnabled = enabled
        lock.unlock()
        Logger.analyticsLog.info("Analytics tracking \(enabled ? "enabled" : "disabled")")
    }
}
