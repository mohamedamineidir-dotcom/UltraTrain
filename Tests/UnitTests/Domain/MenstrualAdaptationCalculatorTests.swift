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
}
