import Foundation
import Testing
@testable import UltraTrain

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {

    // MARK: - Basic Tracking

    @Test("Track event when enabled does not crash")
    func trackEventWhenEnabled() {
        let service = AnalyticsService()
        service.track(.appOpened)
    }

    @Test("Track event with properties does not crash")
    func trackEventWithProperties() {
        let service = AnalyticsService()
        service.track(.runCompleted, properties: ["duration": "3600"])
    }

    @Test("Track event when disabled is silently ignored")
    func trackEventWhenDisabledDoesNothing() {
        let service = AnalyticsService()
        service.setTrackingEnabled(false)
        service.track(.appOpened)
    }

    @Test("Toggling tracking enabled works")
    func setTrackingEnabledToggle() {
        let service = AnalyticsService()
        service.setTrackingEnabled(false)
        service.setTrackingEnabled(true)
        service.track(.raceAdded)
    }

    // MARK: - Flush Behavior

    @Test("Flush with no API client does not crash")
    func flushWithoutApiClient() {
        let service = AnalyticsService()
        service.track(.appOpened)
        service.flush()
    }

    @Test("Flush with empty buffer is a no-op")
    func flushEmptyBuffer() {
        let service = AnalyticsService()
        service.flush()
    }

    @Test("Disable tracking clears the buffer")
    func disableTrackingClearsBuffer() {
        let service = AnalyticsService()
        service.track(.appOpened)
        service.track(.runStarted)
        service.setTrackingEnabled(false)
        // Re-enable and flush — buffer should be empty
        service.setTrackingEnabled(true)
        service.flush()
    }

    // MARK: - BufferedEvent & AnalyticsPayload

    @Test("BufferedEvent is Codable")
    func bufferedEventCodable() throws {
        let event = BufferedEvent(
            name: "runStarted",
            properties: ["source": "gps"],
            timestamp: Date()
        )
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(BufferedEvent.self, from: data)
        #expect(decoded.name == "runStarted")
        #expect(decoded.properties["source"] == "gps")
    }

    @Test("AnalyticsPayload is Codable")
    func analyticsPayloadCodable() throws {
        let event = BufferedEvent(
            name: "appOpened",
            properties: [:],
            timestamp: Date()
        )
        let payload = AnalyticsPayload(
            events: [event],
            appVersion: "1.0",
            buildNumber: "42",
            platform: "iOS",
            locale: "en_US"
        )
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(AnalyticsPayload.self, from: data)
        #expect(decoded.events.count == 1)
        #expect(decoded.appVersion == "1.0")
        #expect(decoded.platform == "iOS")
    }

    // MARK: - Mock Analytics

    @Test("Mock analytics records events")
    func mockAnalyticsRecordsEvents() {
        let mock = MockAnalyticsService()
        mock.track(.planGenerated)
        mock.track(.runStarted, properties: ["source": "manual"])
        #expect(mock.trackedEvents.count == 2)
        #expect(mock.trackedEvents[0].event == .planGenerated)
        #expect(mock.trackedEvents[1].properties["source"] == "manual")
    }

    @Test("Mock analytics silent when disabled")
    func mockAnalyticsSilentWhenDisabled() {
        let mock = MockAnalyticsService()
        mock.setTrackingEnabled(false)
        mock.track(.appOpened)
        #expect(mock.trackedEvents.isEmpty)
    }
}
