@testable import UltraTrain

final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    var trackedEvents: [(event: AnalyticsEvent, properties: [String: String])] = []
    var isEnabled = true

    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        guard isEnabled else { return }
        trackedEvents.append((event: event, properties: properties))
    }

    func setTrackingEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
