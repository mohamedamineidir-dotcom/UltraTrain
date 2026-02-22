import Foundation
import Testing
@testable import UltraTrain

@Suite("IntervalPhase Tests")
struct IntervalPhaseTests {

    // MARK: - IntervalTrigger displayText

    @Test("Duration trigger with whole minutes displays minutes only")
    func durationTriggerWholeMinutes() {
        let trigger = IntervalTrigger.duration(seconds: 180)

        #expect(trigger.displayText == "3m")
    }

    @Test("Duration trigger with seconds displays minutes and seconds")
    func durationTriggerWithSeconds() {
        let trigger = IntervalTrigger.duration(seconds: 90)

        #expect(trigger.displayText == "1m 30s")
    }

    @Test("Duration trigger with zero seconds displays 0m")
    func durationTriggerZeroSeconds() {
        let trigger = IntervalTrigger.duration(seconds: 0)

        #expect(trigger.displayText == "0m")
    }

    @Test("Distance trigger displays formatted kilometers")
    func distanceTriggerDisplayText() {
        let trigger = IntervalTrigger.distance(km: 1.0)

        #expect(trigger.displayText == "1.00 km")
    }

    @Test("Distance trigger displays decimal kilometers")
    func distanceTriggerDecimalDisplayText() {
        let trigger = IntervalTrigger.distance(km: 0.4)

        #expect(trigger.displayText == "0.40 km")
    }

    // MARK: - IntervalTrigger isDuration / isDistance

    @Test("isDuration returns true for duration trigger")
    func isDurationTrue() {
        let trigger = IntervalTrigger.duration(seconds: 60)

        #expect(trigger.isDuration == true)
        #expect(trigger.isDistance == false)
    }

    @Test("isDistance returns true for distance trigger")
    func isDistanceTrue() {
        let trigger = IntervalTrigger.distance(km: 1.0)

        #expect(trigger.isDistance == true)
        #expect(trigger.isDuration == false)
    }

    // MARK: - IntervalPhaseType rawValue

    @Test("IntervalPhaseType has correct raw values")
    func phaseTypeRawValues() {
        #expect(IntervalPhaseType.warmUp.rawValue == "warmUp")
        #expect(IntervalPhaseType.work.rawValue == "work")
        #expect(IntervalPhaseType.recovery.rawValue == "recovery")
        #expect(IntervalPhaseType.coolDown.rawValue == "coolDown")
    }

    // MARK: - IntervalPhaseType allCases

    @Test("IntervalPhaseType has exactly 4 cases")
    func phaseTypeAllCases() {
        #expect(IntervalPhaseType.allCases.count == 4)
        #expect(IntervalPhaseType.allCases.contains(.warmUp))
        #expect(IntervalPhaseType.allCases.contains(.work))
        #expect(IntervalPhaseType.allCases.contains(.recovery))
        #expect(IntervalPhaseType.allCases.contains(.coolDown))
    }

    // MARK: - IntervalPhaseType displayName

    @Test("IntervalPhaseType displayName returns human-readable text")
    func phaseTypeDisplayNames() {
        #expect(IntervalPhaseType.warmUp.displayName == "Warm Up")
        #expect(IntervalPhaseType.work.displayName == "Work")
        #expect(IntervalPhaseType.recovery.displayName == "Recovery")
        #expect(IntervalPhaseType.coolDown.displayName == "Cool Down")
    }

    // MARK: - IntervalPhase totalDuration

    @Test("totalDuration multiplies duration seconds by repeatCount")
    func totalDurationWithDurationTrigger() {
        let phase = IntervalPhase(
            id: UUID(),
            phaseType: .work,
            trigger: .duration(seconds: 180),
            targetIntensity: .hard,
            repeatCount: 4
        )

        #expect(phase.totalDuration == 720)
    }

    @Test("totalDuration returns 0 for distance trigger")
    func totalDurationWithDistanceTrigger() {
        let phase = IntervalPhase(
            id: UUID(),
            phaseType: .work,
            trigger: .distance(km: 1.0),
            targetIntensity: .hard,
            repeatCount: 4
        )

        #expect(phase.totalDuration == 0)
    }
}
