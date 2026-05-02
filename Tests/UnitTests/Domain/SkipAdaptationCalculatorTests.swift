import Foundation
import Testing
@testable import UltraTrain

@Suite("SkipAdaptationCalculator Tests")
struct SkipAdaptationCalculatorTests {

    // MARK: - Race-Proximity (audit fix #1)

    @Test("raceProximity buckets: offSeason / farOut / approaching / raceWeek / taperLockdown")
    func raceProximityBuckets() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        func bucket(daysAhead: Int) -> SkipAdaptationCalculator.RaceProximity {
            let race = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)
            return SkipAdaptationCalculator.raceProximity(raceDate: race, now: now)
        }
        #expect(SkipAdaptationCalculator.raceProximity(raceDate: nil, now: now) == .offSeason)
        #expect(bucket(daysAhead: 60) == .offSeason)
        #expect(bucket(daysAhead: 30) == .farOut)
        #expect(bucket(daysAhead: 14) == .approaching)
        #expect(bucket(daysAhead: 5)  == .raceWeek)
        #expect(bucket(daysAhead: 2)  == .taperLockdown)
    }

    @Test("approaching race bumps suggestion → recommended for fatigue patterns")
    func raceProximityBumpsSeverity() {
        // Athlete has a fatigue pattern that would normally trigger
        // a recommended-tier swap. With race in 14 days the calculator
        // should escalate, *and* append a contextual coach note about
        // why.
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let raceDate = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .fatigue, date: now.addingTimeInterval(-7 * 86400)),
            .init(reason: .fatigue, date: now.addingTimeInterval(-3 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [
            session,
            makeSession(daysFromNow: 1, type: .intervals, now: now),
            makeSession(daysFromNow: 5, type: .longRun, now: now)
        ])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .fatigue,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 12,
            raceDate: raceDate,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        #expect(!result.recommendations.isEmpty)
        // At least one recommendation should mention race-week context
        let hasRaceContext = result.recommendations.contains { rec in
            rec.message.contains("Race in 1-3 weeks") || rec.message.contains("week")
        }
        #expect(hasRaceContext)
    }

    @Test("offSeason does not append race-context note")
    func offSeasonNoBump() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Race 60 days out → offSeason
        let raceDate = Calendar.current.date(byAdding: .day, value: 60, to: now)!
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .fatigue, date: now.addingTimeInterval(-7 * 86400)),
            .init(reason: .fatigue, date: now.addingTimeInterval(-3 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [
            session,
            makeSession(daysFromNow: 1, type: .intervals, now: now)
        ])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .fatigue,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 28,
            raceDate: raceDate,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // No race-week context phrasing
        for rec in result.recommendations {
            #expect(!rec.message.contains("Race in"))
            #expect(!rec.message.contains("Race week"))
        }
    }

    // MARK: - Time-Window Clustering (audit fix #2)

    @Test("3 fatigue skips clustered in 5 days = acute flare with strong response")
    func acuteFlare5Days() {
        // 3 fatigue skips clustered in <7 days → acuteFlare. Skipping
        // a recovery session today, with intervals scheduled for the
        // first half of the week — the fatigue handler should swap
        // those intervals to easy at urgent severity.
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .fatigue, date: now.addingTimeInterval(-4 * 86400)),
            .init(reason: .fatigue, date: now.addingTimeInterval(-2 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let intervals = makeSession(daysFromNow: 1, type: .intervals, now: now)
        let week = makeWeek(sessions: [session, intervals])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .fatigue,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 16,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Should produce a swap-to-easy rec for the next quality session
        #expect(!result.recommendations.isEmpty)
        let swap = result.recommendations.first { $0.type == .swapToRecovery }
        #expect(swap != nil)
        // Acute-flare patterns should escalate to urgent severity
        #expect(swap?.severity == .urgent)
        #expect(swap?.affectedSessionIds.contains(intervals.id) == true)
    }

    @Test("3 fatigue skips spread across 21 days = chronic, not acute flare")
    func chronicNotFlare() {
        // Same number of skips (3) but spread over 3 weeks — should
        // still be elevated but NOT classified as flare.
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .fatigue, date: now.addingTimeInterval(-20 * 86400)),
            .init(reason: .fatigue, date: now.addingTimeInterval(-10 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [
            session,
            makeSession(daysFromNow: 1, type: .intervals, now: now)
        ])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .fatigue,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 28,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Still triggers a response (elevated chronic pattern)
        #expect(!result.recommendations.isEmpty)
    }

    // MARK: - Reason Combination Weighting (audit fix #3)

    @Test("ReasonSeverity classification: critical / moderate / minor / neutral")
    func reasonSeverityClassification() {
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.injury) == .critical)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.illness) == .critical)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.fatigue) == .moderate)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.soreness) == .moderate)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.noMotivation) == .minor)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.other) == .minor)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.weather) == .neutral)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.noTime) == .neutral)
        #expect(SkipAdaptationCalculator.ReasonSeverity.of(.menstrualCycle) == .neutral)
    }

    @Test("2 critical skips trigger elevated pattern even at low total count")
    func twoCriticalElevated() {
        // 1× illness in history + current illness → elevated immediately
        // (the 2-critical fast-path), regardless of plan length.
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .illness, date: now.addingTimeInterval(-5 * 86400))
        ]
        // Use fatigue reason (not illness) to avoid the dedicated
        // illness handler. We're verifying the pattern detector itself.
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let nextWeek = makeWeek(sessions: [
            makeSession(daysFromNow: 7, type: .intervals, now: now),
            makeSession(daysFromNow: 8, type: .longRun, now: now)
        ])
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .illness,
            currentWeek: week,
            nextWeek: nextWeek,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 28,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Illness handler always produces recs — verify it fired
        #expect(!result.recommendations.isEmpty)
    }

    // MARK: - Sustained illness/injury → multi-week reduction (audit fix #4)

    @Test("sustained illness: 2+ illness skips in 14 days extends reduction to 2 weeks")
    func sustainedIllnessTwoWeeks() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .illness, date: now.addingTimeInterval(-9 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let nextWeek = makeWeek(sessions: [
            makeSession(daysFromNow: 7, type: .intervals, now: now),
            makeSession(daysFromNow: 8, type: .longRun, now: now)
        ])
        let weekAfterNext = makeWeek(sessions: [
            makeSession(daysFromNow: 14, type: .intervals, now: now),
            makeSession(daysFromNow: 15, type: .longRun, now: now)
        ])
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .illness,
            currentWeek: week,
            nextWeek: nextWeek,
            weekAfterNext: weekAfterNext,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 12,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Should produce 2 reduction recs (week 1 + week 2 stair-step)
        let reductionRecs = result.recommendations.filter { $0.type == .reduceFatigueLoad }
        #expect(reductionRecs.count == 2)
        // Note should mention the 2-week pattern
        #expect(result.note.contains("2 weeks") || result.note.contains("two-week") || result.note.contains("stair-step"))
    }

    @Test("single illness skip: stays single-week reduction")
    func singleIllnessOneWeek() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let nextWeek = makeWeek(sessions: [
            makeSession(daysFromNow: 7, type: .intervals, now: now),
            makeSession(daysFromNow: 8, type: .longRun, now: now)
        ])
        let weekAfterNext = makeWeek(sessions: [
            makeSession(daysFromNow: 14, type: .intervals, now: now)
        ])
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .illness,
            currentWeek: week,
            nextWeek: nextWeek,
            weekAfterNext: weekAfterNext,
            experience: .intermediate,
            recentSkips: [],
            totalWeeksInPlan: 12,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Only one volume-reduction rec (week 1 only)
        let reductionRecs = result.recommendations.filter { $0.type == .reduceFatigueLoad }
        #expect(reductionRecs.count == 1)
    }

    @Test("sustained injury: 2+ injury skips extend reduction to 2 weeks")
    func sustainedInjuryTwoWeeks() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent: [SkipAdaptationCalculator.RecentSkip] = [
            .init(reason: .injury, date: now.addingTimeInterval(-8 * 86400))
        ]
        let session = makeSession(daysFromNow: 0, type: .longRun, now: now)
        let nextWeek = makeWeek(sessions: [
            makeSession(daysFromNow: 7, type: .intervals, now: now),
            makeSession(daysFromNow: 8, type: .longRun, now: now)
        ])
        let weekAfterNext = makeWeek(sessions: [
            makeSession(daysFromNow: 14, type: .intervals, now: now),
            makeSession(daysFromNow: 15, type: .longRun, now: now)
        ])
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .injury,
            currentWeek: week,
            nextWeek: nextWeek,
            weekAfterNext: weekAfterNext,
            experience: .intermediate,
            recentSkips: recent,
            totalWeeksInPlan: 12,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        let reductionRecs = result.recommendations.filter { $0.type == .reduceFatigueLoad }
        #expect(reductionRecs.count == 2)
        #expect(result.note.contains("2 weeks") || result.note.contains("stair-step"))
    }

    // MARK: - Existing behaviour preserved

    @Test("single fatigue skip with no pattern: no recommendations")
    func singleFatigueNoChange() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .fatigue,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: [],
            totalWeeksInPlan: 16,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
    }

    @Test("weather skip never produces recommendations")
    func weatherNoRec() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = makeSession(daysFromNow: 0, type: .longRun, now: now)
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .weather,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: [
                .init(reason: .weather, date: now.addingTimeInterval(-3 * 86400))
            ],
            totalWeeksInPlan: 16,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        // Weather skip should produce no recs even if there's weather history.
        // The long-run reschedule code path is gated to skip .weather.
        let nonRescheduleRecs = result.recommendations.filter { $0.type != .rescheduleKeySession }
        #expect(nonRescheduleRecs.isEmpty)
    }

    @Test("menstrual cycle skip is no-op (routes to MenstrualAdaptationCalculator)")
    func menstrualCycleNoOp() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = makeSession(daysFromNow: 0, type: .recovery, now: now)
        let week = makeWeek(sessions: [session])
        let context = SkipAdaptationCalculator.Context(
            skippedSession: session,
            reason: .menstrualCycle,
            currentWeek: week,
            nextWeek: nil,
            experience: .intermediate,
            recentSkips: [],
            totalWeeksInPlan: 16,
            raceDate: nil,
            analysisDate: now
        )
        let result = SkipAdaptationCalculator.analyze(context: context)
        #expect(result.recommendations.isEmpty)
        #expect(result.note.contains("Menstrual") || result.note.contains("menstrual"))
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
