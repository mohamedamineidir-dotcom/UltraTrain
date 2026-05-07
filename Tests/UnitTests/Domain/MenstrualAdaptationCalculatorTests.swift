import Foundation
import Testing
@testable import UltraTrain

@Suite("MenstrualAdaptationCalculator Tests")
struct MenstrualAdaptationCalculatorTests {

    // MARK: - Multi-skip pattern detection (the only menstrual signal we surface)

    @Test("multi-skip pattern: nothing when fewer than 2 menstrual skips in window")
    func multiSkipBelowThreshold() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var session1 = makeSession(daysFromNow: -3, type: .longRun, now: now)
        session1.isSkipped = true
        session1.skipReason = .menstrualCycle
        let week = makeWeek(sessions: [session1])
        let recs = MenstrualAdaptationCalculator.analyzeMultiSkipPattern(
            weeks: [week], now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("multi-skip pattern: fires when ≥2 menstrual skips in 7-day window")
    func multiSkipAboveThreshold() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var s1 = makeSession(daysFromNow: -2, type: .longRun, now: now)
        s1.isSkipped = true
        s1.skipReason = .menstrualCycle
        var s2 = makeSession(daysFromNow: -5, type: .intervals, now: now)
        s2.isSkipped = true
        s2.skipReason = .menstrualCycle
        let week = makeWeek(sessions: [s1, s2])
        let recs = MenstrualAdaptationCalculator.analyzeMultiSkipPattern(
            weeks: [week], now: now
        )
        #expect(recs.count == 1)
        #expect(recs.first?.type == .menstrualMultiSkipPattern)
        #expect(recs.first?.severity == .recommended)
    }

    @Test("multi-skip pattern: ignores skips outside 7-day window")
    func multiSkipOutsideWindowIgnored() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var s1 = makeSession(daysFromNow: -10, type: .longRun, now: now)
        s1.isSkipped = true
        s1.skipReason = .menstrualCycle
        var s2 = makeSession(daysFromNow: -12, type: .intervals, now: now)
        s2.isSkipped = true
        s2.skipReason = .menstrualCycle
        let week = makeWeek(sessions: [s1, s2])
        let recs = MenstrualAdaptationCalculator.analyzeMultiSkipPattern(
            weeks: [week], now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("multi-skip pattern: ignores non-menstrual skips")
    func multiSkipIgnoresOtherReasons() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var s1 = makeSession(daysFromNow: -2, type: .longRun, now: now)
        s1.isSkipped = true
        s1.skipReason = .fatigue
        var s2 = makeSession(daysFromNow: -5, type: .intervals, now: now)
        s2.isSkipped = true
        s2.skipReason = .noTime
        let week = makeWeek(sessions: [s1, s2])
        let recs = MenstrualAdaptationCalculator.analyzeMultiSkipPattern(
            weeks: [week], now: now
        )
        #expect(recs.isEmpty)
    }

    // MARK: - Helpers

    private func makeSession(
        daysFromNow: Int,
        type: SessionType,
        now: Date
    ) -> TrainingSession {
        let date = Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!
        return TrainingSession(
            id: UUID(),
            date: date,
            type: type,
            plannedDistanceKm: 5,
            plannedElevationGainM: 0,
            plannedDuration: 1800,
            intensity: .moderate,
            description: "test",
            isCompleted: false,
            isSkipped: false
        )
    }

    private func makeWeek(sessions: [TrainingSession]) -> TrainingWeek {
        let start = sessions.first?.date ?? Date()
        let end = sessions.last?.date ?? start
        return TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: start,
            endDate: end,
            phase: .build,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 30,
            targetElevationGainM: 0,
            targetDurationSeconds: 0
        )
    }
}
