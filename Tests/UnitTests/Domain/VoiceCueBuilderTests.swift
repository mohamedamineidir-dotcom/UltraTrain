import Foundation
import Testing
@testable import UltraTrain

@Suite("VoiceCueBuilder Tests")
struct VoiceCueBuilderTests {

    // MARK: - Helpers

    private func makeSnapshot(
        distanceKm: Double = 5.0,
        elapsedTime: TimeInterval = 1500,
        currentPace: TimeInterval? = 330,
        elevationGainM: Double = 200,
        currentHeartRate: Int? = 145,
        currentZoneName: String? = "3, tempo",
        previousZoneName: String? = "2, easy",
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

    // MARK: - Distance Split

    @Test("Distance split cue in metric contains kilometers and has medium priority")
    func distanceSplitMetric() {
        let snapshot = makeSnapshot(distanceKm: 5.0, isMetric: true)
        let cue = VoiceCueBuilder.distanceSplitCue(snapshot: snapshot)

        #expect(cue.type == .distanceSplit)
        #expect(cue.message.contains("kilometers"))
        #expect(cue.message.contains("5"))
        #expect(cue.priority == .medium)
    }

    @Test("Distance split cue in imperial contains miles")
    func distanceSplitImperial() {
        let snapshot = makeSnapshot(distanceKm: 5.0, isMetric: false)
        let cue = VoiceCueBuilder.distanceSplitCue(snapshot: snapshot)

        #expect(cue.type == .distanceSplit)
        #expect(cue.message.contains("miles"))
        #expect(!cue.message.contains("kilometers"))
    }

    @Test("Distance split includes pace when pace is available")
    func distanceSplitIncludesPace() {
        let snapshot = makeSnapshot(currentPace: 330, isMetric: true)
        let cue = VoiceCueBuilder.distanceSplitCue(snapshot: snapshot)

        #expect(cue.message.contains("Pace:"))
        #expect(cue.message.contains("per kilometer"))
    }

    @Test("Distance split excludes pace when pace is nil")
    func distanceSplitExcludesPaceWhenNil() {
        let snapshot = makeSnapshot(currentPace: nil)
        let cue = VoiceCueBuilder.distanceSplitCue(snapshot: snapshot)

        #expect(!cue.message.contains("Pace:"))
    }

    // MARK: - Time Split

    @Test("Time split cue contains elapsed and has low priority")
    func timeSplitFormatting() {
        let snapshot = makeSnapshot(distanceKm: 5.0, elapsedTime: 1500, isMetric: true)
        let cue = VoiceCueBuilder.timeSplitCue(snapshot: snapshot)

        #expect(cue.type == .timeSplit)
        #expect(cue.message.contains("elapsed"))
        #expect(cue.message.contains("kilometers"))
        #expect(cue.message.contains("5.0"))
        #expect(cue.priority == .low)
    }

    // MARK: - Heart Rate Zone Change

    @Test("HR zone change cue contains zone name")
    func heartRateZoneChangeCueContainsZoneName() {
        let snapshot = makeSnapshot(currentZoneName: "3, tempo")
        let cue = VoiceCueBuilder.heartRateZoneChangeCue(snapshot: snapshot)

        #expect(cue.type == .heartRateZoneChange)
        #expect(cue.message.contains("3, tempo"))
        #expect(cue.message.contains("Entering zone"))
        #expect(cue.priority == .medium)
    }

    @Test("HR zone change cue uses unknown when zone name is nil")
    func heartRateZoneChangeNilZone() {
        let snapshot = makeSnapshot(currentZoneName: nil)
        let cue = VoiceCueBuilder.heartRateZoneChangeCue(snapshot: snapshot)

        #expect(cue.message.contains("unknown"))
        #expect(cue.message == "Entering zone unknown.")
    }

    // MARK: - Nutrition Reminder

    @Test("Nutrition reminder has exact message and high priority")
    func nutritionReminder() {
        let cue = VoiceCueBuilder.nutritionReminderCue()

        #expect(cue.type == .nutritionReminder)
        #expect(cue.message == "Time for nutrition.")
        #expect(cue.priority == .high)
    }

    // MARK: - Checkpoint Crossing

    @Test("Checkpoint cue with negative delta says ahead of plan")
    func checkpointAheadOfPlan() {
        let cue = VoiceCueBuilder.checkpointCue(name: "Aid Station 1", timeDelta: -90)

        #expect(cue.type == .checkpointCrossing)
        #expect(cue.message.contains("ahead of plan"))
        #expect(cue.message.contains("Aid Station 1"))
        #expect(cue.message.contains("1 minute 30 seconds"))
        #expect(cue.priority == .high)
    }

    @Test("Checkpoint cue with positive delta says behind plan")
    func checkpointBehindPlan() {
        let cue = VoiceCueBuilder.checkpointCue(name: "Summit", timeDelta: 120)

        #expect(cue.type == .checkpointCrossing)
        #expect(cue.message.contains("behind plan"))
        #expect(cue.message.contains("Summit"))
        #expect(cue.message.contains("2 minutes"))
    }

    @Test("Checkpoint cue with no timeDelta only says reached")
    func checkpointNoDelta() {
        let cue = VoiceCueBuilder.checkpointCue(name: "CP3", timeDelta: nil)

        #expect(cue.message == "Checkpoint CP3 reached.")
        #expect(!cue.message.contains("ahead"))
        #expect(!cue.message.contains("behind"))
    }

    // MARK: - Pacing Alert

    @Test("Pacing alert passes through the provided message")
    func pacingAlertPassThrough() {
        let message = "You are 15% slower than planned pace"
        let cue = VoiceCueBuilder.pacingAlertCue(message: message)

        #expect(cue.type == .pacingAlert)
        #expect(cue.message == message)
        #expect(cue.priority == .high)
    }

    // MARK: - Zone Drift

    @Test("Zone drift cue says slow down when above target zone")
    func zoneDriftAboveTarget() {
        let cue = VoiceCueBuilder.zoneDriftCue(currentZone: 4, targetZone: 2, duration: 180)

        #expect(cue.type == .zoneDriftAlert)
        #expect(cue.message.contains("Slow down"))
        #expect(cue.message.contains("Zone 4"))
        #expect(cue.message.contains("target is zone 2"))
        #expect(cue.priority == .high)
    }

    @Test("Zone drift cue says pick up the pace when below target zone")
    func zoneDriftBelowTarget() {
        let cue = VoiceCueBuilder.zoneDriftCue(currentZone: 1, targetZone: 3, duration: 120)

        #expect(cue.message.contains("Pick up the pace"))
        #expect(cue.message.contains("Zone 1"))
        #expect(cue.message.contains("target is zone 3"))
    }

    // MARK: - Run State

    @Test("Run state cue produces correct messages for each state type")
    func runStateMessages() {
        let started = VoiceCueBuilder.runStateCue(type: .runStarted)
        #expect(started.message == "Run started. Good luck!")
        #expect(started.type == .runStarted)
        #expect(started.priority == .medium)

        let paused = VoiceCueBuilder.runStateCue(type: .runPaused)
        #expect(paused.message == "Run paused.")

        let resumed = VoiceCueBuilder.runStateCue(type: .runResumed)
        #expect(resumed.message == "Run resumed.")

        let autoPaused = VoiceCueBuilder.runStateCue(type: .autoPaused)
        #expect(autoPaused.message == "Auto paused.")
    }

    // MARK: - Spoken Duration

    @Test("spokenDuration formats 0 seconds correctly")
    func spokenDurationZero() {
        let result = VoiceCueBuilder.spokenDuration(0)
        #expect(result == "0 seconds")
    }

    @Test("spokenDuration formats 90 seconds as 1 minute 30 seconds")
    func spokenDuration90Seconds() {
        let result = VoiceCueBuilder.spokenDuration(90)
        #expect(result == "1 minute 30 seconds")
    }

    @Test("spokenDuration formats 3661 seconds as 1 hour 1 minute")
    func spokenDuration3661Seconds() {
        let result = VoiceCueBuilder.spokenDuration(3661)
        #expect(result == "1 hour 1 minute")
    }
}
