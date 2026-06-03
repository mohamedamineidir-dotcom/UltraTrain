import Foundation
import Testing
@testable import UltraTrain

@Suite("Comeback adjustment + plan softening")
struct ComebackAdjustmentTests {

    // MARK: - Calculator

    @Test("Kept training => no adjustment regardless of gap")
    func keptTrainingNoAdjustment() {
        let adj = ComebackAdjustmentCalculator.compute(
            gapLevel: .keptTraining, weeksAway: 10,
            experience: .intermediate, raceDistanceKm: 42.195, weeksUntilRace: 16
        )
        #expect(adj == .none)
    }

    @Test("Stopped + long gap => significant dampening + easy-only weeks")
    func stoppedLongGap() {
        let adj = ComebackAdjustmentCalculator.compute(
            gapLevel: .stopped, weeksAway: 10,
            experience: .intermediate, raceDistanceKm: 42.195, weeksUntilRace: 16
        )
        #expect(adj.fitnessChange == .significant)
        #expect(adj.easyOnlyWeeks >= 3)
    }

    @Test("A very short break softens the severity")
    func shortBreakSoftens() {
        let short = ComebackAdjustmentCalculator.compute(
            gapLevel: .occasional, weeksAway: 1,
            experience: .intermediate, raceDistanceKm: 21.1, weeksUntilRace: 16
        )
        let normal = ComebackAdjustmentCalculator.compute(
            gapLevel: .occasional, weeksAway: 3,
            experience: .intermediate, raceDistanceKm: 21.1, weeksUntilRace: 16
        )
        #expect(short.easyOnlyWeeks <= normal.easyOnlyWeeks)
    }

    @Test("Beginners get a gentler ramp than elites")
    func experienceModulatesRamp() {
        let beginner = ComebackAdjustmentCalculator.compute(
            gapLevel: .stopped, weeksAway: 5,
            experience: .beginner, raceDistanceKm: 21.1, weeksUntilRace: 20
        )
        let elite = ComebackAdjustmentCalculator.compute(
            gapLevel: .stopped, weeksAway: 5,
            experience: .elite, raceDistanceKm: 21.1, weeksUntilRace: 20
        )
        #expect(beginner.easyOnlyWeeks > elite.easyOnlyWeeks)
    }

    @Test("Easy-only weeks are capped to leave race-specific work")
    func cappedByTimeToRace() {
        let adj = ComebackAdjustmentCalculator.compute(
            gapLevel: .stopped, weeksAway: 10,
            experience: .beginner, raceDistanceKm: 100, weeksUntilRace: 6
        )
        #expect(adj.easyOnlyWeeks <= 2)  // 6 / 3
    }

    // MARK: - Plan adjuster

    private func session(_ type: SessionType, daysFromNow: Int) -> TrainingSession {
        TrainingSession(
            id: UUID(), date: Date.now.addingTimeInterval(Double(daysFromNow) * 86400),
            type: type, plannedDistanceKm: 8, plannedElevationGainM: 0,
            plannedDuration: 2400, intensity: type == .intervals ? .hard : .easy,
            description: "x", isCompleted: false, isSkipped: false, linkedRunId: nil,
            intervalWorkoutId: type == .intervals ? UUID() : nil
        )
    }

    private func week(_ number: Int, startOffsetDays: Int) -> TrainingWeek {
        let start = Date.now.addingTimeInterval(Double(startOffsetDays) * 86400)
        return TrainingWeek(
            id: UUID(), weekNumber: number,
            startDate: start, endDate: start.addingTimeInterval(6 * 86400),
            phase: .build,
            sessions: [session(.intervals, daysFromNow: startOffsetDays + 1),
                       session(.longRun, daysFromNow: startOffsetDays + 3)],
            isRecoveryWeek: false, targetVolumeKm: 40,
            targetElevationGainM: 0, targetDurationSeconds: 0
        )
    }

    @Test("Softening converts early quality to easy, leaves later weeks + long runs")
    func softenEarlyQuality() {
        var plan = TrainingPlan(
            id: UUID(), athleteId: UUID(), targetRaceId: UUID(), createdAt: .now,
            weeks: [week(1, startOffsetDays: 0),    // contains today
                    week(2, startOffsetDays: 7),
                    week(3, startOffsetDays: 14)],
            intermediateRaceIds: [], intermediateRaceSnapshots: []
        )

        ComebackPlanAdjuster.softenEarlyQuality(in: &plan, easyOnlyWeeks: 2)

        // Weeks 1-2 intervals softened to easy recovery; the long run kept.
        #expect(plan.weeks[0].sessions[0].type == .recovery)
        #expect(plan.weeks[0].sessions[0].intensity == .easy)
        #expect(plan.weeks[0].sessions[0].intervalWorkoutId == nil)
        #expect(plan.weeks[0].sessions[0].plannedDuration == 2400)  // volume kept
        #expect(plan.weeks[0].sessions[1].type == .longRun)
        #expect(plan.weeks[1].sessions[0].type == .recovery)
        // Week 3 (beyond the window) keeps its quality.
        #expect(plan.weeks[2].sessions[0].type == .intervals)

        // Long run ramps back: first easy week trimmed (×0.6), last easy
        // week at full; week beyond the window untouched.
        #expect(plan.weeks[0].sessions[1].plannedDuration == 2400 * 0.6)
        #expect(plan.weeks[1].sessions[1].plannedDuration == 2400)
        #expect(plan.weeks[2].sessions[1].plannedDuration == 2400)
    }
}
