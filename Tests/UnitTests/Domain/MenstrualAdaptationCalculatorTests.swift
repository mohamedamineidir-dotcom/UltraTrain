import Foundation
import Testing
@testable import UltraTrain

@Suite("MenstrualAdaptationCalculator Tests")
struct MenstrualAdaptationCalculatorTests {

    // MARK: - Asymptomatic + unspecified

    @Test("asymptomatic logs produce no recommendations")
    func asymptomaticNoRecommendations() {
        let context = makeContext(cluster: .asymptomatic)
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
        #expect(result.note.contains("No plan change"))
    }

    @Test("unspecified produces no recommendations and a fall-through note")
    func unspecifiedNoRecommendations() {
        let context = makeContext(cluster: .unspecified)
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
    }

    // MARK: - Bleed-day

    @Test("bleed-day surfaces options for the next quality session in 48h window")
    func bleedDaySurfacesQuality() {
        // Skipped session = today (recovery), tomorrow has intervals
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let intervalsTomorrow = makeSession(daysFromNow: 1, type: .intervals, now: now)
        let longRunFriday = makeSession(daysFromNow: 4, type: .longRun, now: now)

        let week = makeWeek(sessions: [skipped, intervalsTomorrow, longRunFriday])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .bleedDay,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.count == 1)
        let rec = result.recommendations[0]
        #expect(rec.type == .menstrualBleedDayOptions)
        #expect(rec.severity == .suggestion)
        // Should target the intervals session, not the long run (intervals fits in 48h window)
        #expect(rec.affectedSessionIds == [intervalsTomorrow.id])
    }

    @Test("bleed-day with no quality session in 48h window produces no recommendation")
    func bleedDayNoQualityNoRecommendation() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        // Long run is 4 days out — outside the 48h bleed-day window
        let longRunDistant = makeSession(daysFromNow: 4, type: .longRun, now: now)

        let week = makeWeek(sessions: [skipped, longRunDistant])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .bleedDay,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
        #expect(result.note.contains("next 1-2 days"))
    }

    @Test("bleed-day skips already-completed and skipped sessions")
    func bleedDayIgnoresCompletedSessions() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        var intervalsTomorrow = makeSession(daysFromNow: 1, type: .intervals, now: now)
        intervalsTomorrow.isCompleted = true
        let tempoDayAfter = makeSession(daysFromNow: 2, type: .tempo, now: now)

        let week = makeWeek(sessions: [skipped, intervalsTomorrow, tempoDayAfter])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .bleedDay,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.count == 1)
        // Should target tempo (2 days), not the completed intervals
        #expect(result.recommendations[0].affectedSessionIds == [tempoDayAfter.id])
    }

    // MARK: - Pre-period

    @Test("pre-period prioritises hardest session in 5-day window")
    func prePeriodPicksHardest() {
        // Long run today, intervals in 3 days, tempo in 4 days
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let longRunDay1 = makeSession(daysFromNow: 1, type: .longRun, now: now)
        let intervalsDay3 = makeSession(daysFromNow: 3, type: .intervals, now: now)
        let tempoDay4 = makeSession(daysFromNow: 4, type: .tempo, now: now)

        let week = makeWeek(sessions: [skipped, longRunDay1, intervalsDay3, tempoDay4])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .prePeriod,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.count == 1)
        let rec = result.recommendations[0]
        #expect(rec.type == .menstrualPrePeriodOptions)
        // Intervals are highest priority per the calculator's hierarchy
        #expect(rec.affectedSessionIds == [intervalsDay3.id])
    }

    @Test("pre-period falls back to long run when no intervals present")
    func prePeriodFallsBackToLongRun() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let longRunDay4 = makeSession(daysFromNow: 4, type: .longRun, now: now)

        let week = makeWeek(sessions: [skipped, longRunDay4])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .prePeriod,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.count == 1)
        #expect(result.recommendations[0].affectedSessionIds == [longRunDay4.id])
        // Heat-sensitivity note for long run
        #expect(result.recommendations[0].message.contains("warm conditions"))
    }

    @Test("pre-period with no hard session in 5-day window produces no recommendation")
    func prePeriodNoHardNoRecommendation() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let easy1 = makeSession(daysFromNow: 1, type: .recovery, now: now)
        let easy2 = makeSession(daysFromNow: 2, type: .recovery, now: now)

        let week = makeWeek(sessions: [skipped, easy1, easy2])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .prePeriod,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
    }

    @Test("pre-period reaches into next week when current week is exhausted")
    func prePeriodSpansWeeks() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let skipped = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let intervalsNextWeek = makeSession(daysFromNow: 4, type: .intervals, now: now)

        let currentWeek = makeWeek(sessions: [skipped])
        let nextWeek = makeWeek(sessions: [intervalsNextWeek])
        let context = MenstrualAdaptationCalculator.Context(
            skippedSession: skipped,
            cluster: .prePeriod,
            currentWeek: currentWeek,
            nextWeek: nextWeek,
            now: now
        )
        let result = MenstrualAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.count == 1)
        #expect(result.recommendations[0].affectedSessionIds == [intervalsNextWeek.id])
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

    private func makeContext(cluster: MenstrualSymptomCluster) -> MenstrualAdaptationCalculator.Context {
        let now = Date()
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [session])
        return MenstrualAdaptationCalculator.Context(
            skippedSession: session,
            cluster: cluster,
            currentWeek: week,
            nextWeek: nil,
            now: now
        )
    }

    // MARK: - v2: Multi-skip pattern detection

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
        // Both skips 10+ days ago → outside 7-day default window
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

    // MARK: - v2: Amenorrhea screening

    @Test("amenorrhea screening: nothing when cycleAware is off")
    func amenorrheaSkipsWhenCycleAwareOff() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -120, to: now)
        var completed = makeSession(daysFromNow: -3, type: .longRun, now: now)
        completed.isCompleted = true
        let week = makeWeek(sessions: [completed])
        let recs = MenstrualAdaptationCalculator.analyzeAmenorrheaScreening(
            cycleAware: false,
            lastPeriodStartDate: lastPeriod,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("amenorrhea screening: nothing when never logged a period")
    func amenorrheaSkipsWhenNoPeriodLogged() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var completed = makeSession(daysFromNow: -3, type: .longRun, now: now)
        completed.isCompleted = true
        let week = makeWeek(sessions: [completed])
        let recs = MenstrualAdaptationCalculator.analyzeAmenorrheaScreening(
            cycleAware: true,
            lastPeriodStartDate: nil,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("amenorrhea screening: fires when 90+ days no period and recently active")
    func amenorrheaFiresAfter90Days() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -100, to: now)
        var completed = makeSession(daysFromNow: -3, type: .longRun, now: now)
        completed.isCompleted = true
        let week = makeWeek(sessions: [completed])
        let recs = MenstrualAdaptationCalculator.analyzeAmenorrheaScreening(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            weeks: [week],
            now: now
        )
        #expect(recs.count == 1)
        #expect(recs.first?.type == .menstrualAmenorrheaScreening)
        #expect(recs.first?.severity == .suggestion)
    }

    @Test("amenorrhea screening: nothing when training has stopped")
    func amenorrheaSkipsWhenInactive() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -100, to: now)
        // Last completed session 30 days ago — outside the 21-day "active" window
        var completed = makeSession(daysFromNow: -30, type: .longRun, now: now)
        completed.isCompleted = true
        let week = makeWeek(sessions: [completed])
        let recs = MenstrualAdaptationCalculator.analyzeAmenorrheaScreening(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            weeks: [week],
            now: now
        )
        // Athlete stopped training — RED-S prompt would be misplaced
        #expect(recs.isEmpty)
    }

    @Test("amenorrhea screening: nothing when last period was recent")
    func amenorrheaSkipsWhenRecentPeriod() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -30, to: now)
        var completed = makeSession(daysFromNow: -3, type: .longRun, now: now)
        completed.isCompleted = true
        let week = makeWeek(sessions: [completed])
        let recs = MenstrualAdaptationCalculator.analyzeAmenorrheaScreening(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    // MARK: - v2: Predictive flagging

    @Test("predictive flag: nothing when cycleAware is off")
    func predictiveSkipsWhenCycleAwareOff() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -20, to: now)
        var hard = makeSession(daysFromNow: 7, type: .intervals, now: now)
        hard.isKeySession = true
        let week = makeWeek(sessions: [hard])
        let recs = MenstrualAdaptationCalculator.analyzePredictiveFlag(
            cycleAware: false,
            lastPeriodStartDate: lastPeriod,
            cycleLengthDays: 28,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("predictive flag: fires when key session falls in expected symptomatic window")
    func predictiveFiresInWindow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Last period 25 days ago, cycle 28 → next expected in 3 days
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -25, to: now)
        // Hard session in 4 days = day +1 from expected (within +2 window)
        var hard = makeSession(daysFromNow: 4, type: .intervals, now: now)
        hard.isKeySession = true
        let week = makeWeek(sessions: [hard])
        let recs = MenstrualAdaptationCalculator.analyzePredictiveFlag(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            cycleLengthDays: 28,
            weeks: [week],
            now: now
        )
        #expect(recs.count == 1)
        #expect(recs.first?.type == .menstrualPredictiveFlag)
        #expect(recs.first?.affectedSessionIds.contains(hard.id) == true)
    }

    @Test("predictive flag: nothing when no hard session in symptomatic window")
    func predictiveNoHardInWindow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Last period 25 days ago, cycle 28 → next expected in 3 days
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -25, to: now)
        // Easy session in 4 days — not key, doesn't count
        var easy = makeSession(daysFromNow: 4, type: .recovery, now: now)
        easy.isKeySession = false
        let week = makeWeek(sessions: [easy])
        let recs = MenstrualAdaptationCalculator.analyzePredictiveFlag(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            cycleLengthDays: 28,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("predictive flag: nothing when next expected period is beyond look-ahead window")
    func predictiveSkipsBeyondLookAhead() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Last period 1 day ago, cycle 28 → next expected in 27 days
        // Default lookAhead is 14, so should NOT fire.
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -1, to: now)
        var hard = makeSession(daysFromNow: 27, type: .intervals, now: now)
        hard.isKeySession = true
        let week = makeWeek(sessions: [hard])
        let recs = MenstrualAdaptationCalculator.analyzePredictiveFlag(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            cycleLengthDays: 28,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }

    @Test("predictive flag: walks past missed cycles to project the next future start")
    func predictivePastMultipleCycles() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Last logged period 60 days ago, cycle 28 → expected starts
        // were -32d and -4d (both past). Next future start is at +24d.
        // That's beyond the 14-day look-ahead → should NOT fire.
        let lastPeriod = Calendar.current.date(byAdding: .day, value: -60, to: now)
        var hard = makeSession(daysFromNow: 5, type: .intervals, now: now)
        hard.isKeySession = true
        let week = makeWeek(sessions: [hard])
        let recs = MenstrualAdaptationCalculator.analyzePredictiveFlag(
            cycleAware: true,
            lastPeriodStartDate: lastPeriod,
            cycleLengthDays: 28,
            weeks: [week],
            now: now
        )
        #expect(recs.isEmpty)
    }
}
