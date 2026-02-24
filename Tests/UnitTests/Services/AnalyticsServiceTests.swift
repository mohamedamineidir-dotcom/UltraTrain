import Testing
@testable import UltraTrain

struct AnalyticsServiceTests {

    @Test func trackEventWhenEnabled() {
        let service = AnalyticsService()
        service.track(.appOpened)
        // No crash = success (logging only, no observable side effect)
    }

    @Test func trackEventWithProperties() {
        let service = AnalyticsService()
        service.track(.runCompleted, properties: ["duration": "3600"])
    }

    @Test func trackEventWhenDisabledDoesNothing() {
        let service = AnalyticsService()
        service.setTrackingEnabled(false)
        service.track(.appOpened)
        // No crash = success
    }

    @Test func setTrackingEnabledToggle() {
        let service = AnalyticsService()
        service.setTrackingEnabled(false)
        service.setTrackingEnabled(true)
        service.track(.raceAdded)
    }

    @Test func mockAnalyticsRecordsEvents() {
        let mock = MockAnalyticsService()
        mock.track(.planGenerated)
        mock.track(.runStarted, properties: ["source": "manual"])
        #expect(mock.trackedEvents.count == 2)
        #expect(mock.trackedEvents[0].event == .planGenerated)
        #expect(mock.trackedEvents[1].properties["source"] == "manual")
    }

    @Test func mockAnalyticsSilentWhenDisabled() {
        let mock = MockAnalyticsService()
        mock.setTrackingEnabled(false)
        mock.track(.appOpened)
        #expect(mock.trackedEvents.isEmpty)
    }
}
