import Foundation
import Testing
@testable import UltraTrain

@Suite("VoiceCoachingHandler Tests")
@MainActor
struct VoiceCoachingHandlerTests {

    // MARK: - Helpers

    private func makeConfig(
        enabled: Bool = true,
        announceDistanceSplits: Bool = true,
        announceTimeSplits: Bool = false,
        timeSplitIntervalMinutes: Int = 5,
        announceHRZoneChanges: Bool = true,
        announceNutritionReminders: Bool = true,
        announceCheckpoints: Bool = true,
        announcePacingAlerts: Bool = true,
        announceZoneDriftAlerts: Bool = true
    ) -> VoiceCoachingConfig {
        var config = VoiceCoachingConfig()
        config.enabled = enabled
        config.announceDistanceSplits = announceDistanceSplits
        config.announceTimeSplits = announceTimeSplits
        config.timeSplitIntervalMinutes = timeSplitIntervalMinutes
        config.announceHRZoneChanges = announceHRZoneChanges
        config.announceNutritionReminders = announceNutritionReminders
        config.announceCheckpoints = announceCheckpoints
        config.announcePacingAlerts = announcePacingAlerts
        config.announceZoneDriftAlerts = announceZoneDriftAlerts
        return config
    }

    private func makeSnapshot(
        distanceKm: Double = 0,
        elapsedTime: TimeInterval = 0,
        currentPace: TimeInterval? = nil,
        elevationGainM: Double = 0,
        currentHeartRate: Int? = nil,
        currentZoneName: String? = nil,
        previousZoneName: String? = nil,
        isMetric: Bool = true
    ) -> VoiceCueBuilder.RunSnapshot {
        VoiceCueBuilder.RunSnapshot(
            distanceKm: distanceKm,
            elapsedTime: elapsedTime,
            currentPace: currentPace,
            elevationGainM: elevationGainM,
            currentHeartRate: currentHeartRate,
            currentZoneName: currentZoneName,
            previousZoneName: previousZoneName,
            isMetric: isMetric
        )
    }

    // MARK: - Tests

    @Test("No announcements when config is disabled")
    func noAnnouncementsWhenDisabled() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: false)
        )

        let snapshot = makeSnapshot(distanceKm: 2.0, elapsedTime: 600)
        handler.tick(snapshot: snapshot)

        #expect(mock.spokenCues.isEmpty)
    }

    @Test("Distance split triggered at km boundary")
    func distanceSplitTriggeredAtKmBoundary() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true, announceDistanceSplits: true)
        )

        // Tick at 0.5 km — should not trigger a split
        handler.tick(snapshot: makeSnapshot(distanceKm: 0.5))
        #expect(mock.spokenCues.isEmpty)

        // Tick at 1.01 km — should trigger the first km split
        handler.tick(snapshot: makeSnapshot(distanceKm: 1.01))
        #expect(mock.spokenCues.count == 1)
        #expect(mock.spokenCues[0].type == .distanceSplit)
    }

    @Test("No duplicate distance split for same km boundary")
    func noDuplicateDistanceSplit() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true, announceDistanceSplits: true)
        )

        // First tick at 1.01 km — triggers split
        handler.tick(snapshot: makeSnapshot(distanceKm: 1.01))
        #expect(mock.spokenCues.count == 1)

        // Second tick still at 1.01 km — should NOT trigger another split
        handler.tick(snapshot: makeSnapshot(distanceKm: 1.01))
        #expect(mock.spokenCues.count == 1)
    }

    @Test("Time split triggered at configured interval")
    func timeSplitTriggeredAtInterval() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(
                enabled: true,
                announceTimeSplits: true,
                timeSplitIntervalMinutes: 5
            )
        )

        // Tick at 4 minutes — should not trigger
        handler.tick(snapshot: makeSnapshot(elapsedTime: 4 * 60))
        #expect(mock.spokenCues.isEmpty)

        // Tick at 5 minutes — should trigger time split
        handler.tick(snapshot: makeSnapshot(elapsedTime: 5 * 60))
        #expect(mock.spokenCues.count == 1)
        #expect(mock.spokenCues[0].type == .timeSplit)
    }

    @Test("HR zone change detected when zone changes")
    func hrZoneChangeDetected() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(
                enabled: true,
                announceDistanceSplits: false,
                announceHRZoneChanges: true
            )
        )

        // First tick with zone "2, easy" — sets lastZone but no cue (no previous zone)
        handler.tick(snapshot: makeSnapshot(currentZoneName: "2, easy"))
        #expect(mock.spokenCues.isEmpty)

        // Second tick with zone "3, tempo" — should fire zone change cue
        handler.tick(snapshot: makeSnapshot(currentZoneName: "3, tempo"))
        #expect(mock.spokenCues.count == 1)
        #expect(mock.spokenCues[0].type == .heartRateZoneChange)
    }

    @Test("No HR zone cue when zone is unchanged")
    func noHRZoneCueWhenUnchanged() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(
                enabled: true,
                announceDistanceSplits: false,
                announceHRZoneChanges: true
            )
        )

        // First tick sets lastZone
        handler.tick(snapshot: makeSnapshot(currentZoneName: "2, easy"))
        #expect(mock.spokenCues.isEmpty)

        // Second tick with same zone — no cue should fire
        handler.tick(snapshot: makeSnapshot(currentZoneName: "2, easy"))
        #expect(mock.spokenCues.isEmpty)
    }

    @Test("Nutrition reminder fires when enabled")
    func nutritionReminderFires() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true, announceNutritionReminders: true)
        )

        handler.announceNutritionReminder()

        #expect(mock.spokenCues.count == 1)
        #expect(mock.spokenCues[0].type == .nutritionReminder)
    }

    @Test("Nutrition reminder blocked when config flag is disabled")
    func nutritionReminderBlockedWhenDisabled() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true, announceNutritionReminders: false)
        )

        handler.announceNutritionReminder()

        #expect(mock.spokenCues.isEmpty)
    }

    @Test("Checkpoint crossing fires cue")
    func checkpointCrossingFires() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true, announceCheckpoints: true)
        )

        handler.announceCheckpointCrossing(name: "Aid Station 1", timeDelta: -120)

        #expect(mock.spokenCues.count == 1)
        #expect(mock.spokenCues[0].type == .checkpointCrossing)
    }

    @Test("Stop speaking calls service stop")
    func stopSpeakingCallsServiceStop() {
        let mock = MockVoiceCoachingService()
        let handler = VoiceCoachingHandler(
            voiceService: mock,
            config: makeConfig(enabled: true)
        )

        handler.stopSpeaking()

        #expect(mock.stopCallCount == 1)
    }
}
