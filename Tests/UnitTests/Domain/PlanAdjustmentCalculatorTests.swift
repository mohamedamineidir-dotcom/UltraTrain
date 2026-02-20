import Foundation
import Testing
@testable import UltraTrain

@Suite("Plan Adjustment Calculator Tests")
struct PlanAdjustmentCalculatorTests {

    // MARK: - Helpers

    private let now = Date(timeIntervalSince1970: 1_700_000_000) // Fixed reference

    private func makeSession(
        id: UUID = UUID(),
        daysFromNow: Int,
        type: SessionType = .tempo,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        distanceKm: Double = 10
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: 200,
            plannedDuration: 3600,
            intensity: .moderate,
            description: "\(type.rawValue) session",
            nutritionNotes: nil,
            isCompleted: isCompleted,
            isSkipped: isSkipped,
            linkedRunId: nil
        )
    }

    private func makeWeek(
        weekNumber: Int = 1,
        daysOffset: Int = 0,
        sessions: [TrainingSession],
        isRecoveryWeek: Bool = false,
        phase: TrainingPhase = .build
    ) -> TrainingWeek {
        let start = Calendar.current.date(byAdding: .day, value: daysOffset, to: now)!
        let end = Calendar.current.date(byAdding: .day, value: daysOffset + 6, to: now)!
        return TrainingWeek(
            id: UUID(),
            weekNumber: weekNumber,
            startDate: start,
            endDate: end,
            phase: phase,
            sessions: sessions,
            isRecoveryWeek: isRecoveryWeek,
            targetVolumeKm: 50,
            targetElevationGainM: 1000
        )
    }

    private func makePlan(weeks: [TrainingWeek]) -> TrainingPlan {
        TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: now.addingTimeInterval(-86400 * 30),
            weeks: weeks,
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    // MARK: - Reschedule Key Session

    @Test("Missed long run with available rest day suggests reschedule")
    func missedLongRunWithRestDay() {
        let missedLongRun = makeSession(daysFromNow: -2, type: .longRun)
        let restDay = makeSession(daysFromNow: 2, type: .rest)
        let week = makeWeek(daysOffset: -3, sessions: [missedLongRun, restDay])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.count == 1)
        #expect(reschedules[0].affectedSessionIds.contains(missedLongRun.id))
        #expect(reschedules[0].affectedSessionIds.contains(restDay.id))
    }

    @Test("Missed key session with no rest day produces no reschedule")
    func missedKeyNoRestDay() {
        let missedTempo = makeSession(daysFromNow: -1, type: .tempo)
        let futureTempo = makeSession(daysFromNow: 2, type: .tempo)
        let week = makeWeek(daysOffset: -3, sessions: [missedTempo, futureTempo])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.isEmpty)
    }

    @Test("Missed recovery run is not considered key session")
    func missedRecoveryNotKey() {
        let missedRecovery = makeSession(daysFromNow: -1, type: .recovery)
        let restDay = makeSession(daysFromNow: 2, type: .rest)
        let week = makeWeek(daysOffset: -3, sessions: [missedRecovery, restDay])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.isEmpty)
    }

    @Test("Completed key session produces no reschedule")
    func completedKeyNoReschedule() {
        let completed = makeSession(daysFromNow: -1, type: .intervals, isCompleted: true)
        let restDay = makeSession(daysFromNow: 2, type: .rest)
        let week = makeWeek(daysOffset: -3, sessions: [completed, restDay])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.isEmpty)
    }

    @Test("Skipped key session produces no reschedule")
    func skippedKeyNoReschedule() {
        let skipped = makeSession(daysFromNow: -1, type: .verticalGain, isSkipped: true)
        let restDay = makeSession(daysFromNow: 2, type: .rest)
        let week = makeWeek(daysOffset: -3, sessions: [skipped, restDay])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.isEmpty)
    }

    @Test("Rest day in the past is not a valid slot")
    func restDayInPastNotValid() {
        let missedTempo = makeSession(daysFromNow: -2, type: .tempo)
        let pastRest = makeSession(daysFromNow: -1, type: .rest)
        let week = makeWeek(daysOffset: -3, sessions: [missedTempo, pastRest])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        #expect(reschedules.isEmpty)
    }

    // MARK: - Low Adherence

    @Test("Previous week below 50% adherence suggests volume reduction")
    func lowAdherenceSuggestsReduction() {
        // Previous week: 1/4 non-rest completed = 25%
        let prevSessions = [
            makeSession(daysFromNow: -10, type: .rest),
            makeSession(daysFromNow: -9, type: .tempo, isCompleted: true),
            makeSession(daysFromNow: -8, type: .intervals),
            makeSession(daysFromNow: -7, type: .longRun),
            makeSession(daysFromNow: -6, type: .recovery)
        ]
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -10, sessions: prevSessions)

        // Current week: one past completed (prevents extended gap) + future sessions
        let currentSessions = [
            makeSession(daysFromNow: -1, type: .recovery, isCompleted: true),
            makeSession(daysFromNow: 0, type: .rest),
            makeSession(daysFromNow: 1, type: .tempo),
            makeSession(daysFromNow: 2, type: .longRun)
        ]
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -2, sessions: currentSessions)
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reductions = results.filter { $0.type == .reduceVolumeAfterLowAdherence }
        #expect(reductions.count == 1)
        #expect(reductions[0].affectedSessionIds.count == 2) // tempo + longRun (not rest)
    }

    @Test("Previous week above 50% adherence produces no reduction")
    func goodAdherenceNoReduction() {
        let prevSessions = [
            makeSession(daysFromNow: -10, type: .tempo, isCompleted: true),
            makeSession(daysFromNow: -9, type: .intervals, isCompleted: true),
            makeSession(daysFromNow: -8, type: .longRun),
            makeSession(daysFromNow: -7, type: .recovery, isCompleted: true)
        ]
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -10, sessions: prevSessions)

        let currentSessions = [makeSession(daysFromNow: 1, type: .tempo)]
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -1, sessions: currentSessions)
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reductions = results.filter { $0.type == .reduceVolumeAfterLowAdherence }
        #expect(reductions.isEmpty)
    }

    @Test("Affected sessions are future only")
    func reductionAffectsFutureOnly() {
        // Prev week: 0/2 non-rest completed = 0% adherence
        let prevSessions = [
            makeSession(daysFromNow: -10, type: .tempo),
            makeSession(daysFromNow: -9, type: .longRun)
        ]
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -10, sessions: prevSessions)

        // Current week: one recent completed (prevents extended gap), one past, one future
        let recentCompleted = makeSession(daysFromNow: -1, type: .recovery, isCompleted: true)
        let pastSession = makeSession(daysFromNow: -2, type: .tempo)
        let futureSession = makeSession(daysFromNow: 2, type: .longRun)
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -3, sessions: [recentCompleted, pastSession, futureSession])
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let reductions = results.filter { $0.type == .reduceVolumeAfterLowAdherence }
        #expect(reductions.count == 1)
        #expect(!reductions[0].affectedSessionIds.contains(pastSession.id))
        #expect(reductions[0].affectedSessionIds.contains(futureSession.id))
    }

    // MARK: - Extended Gap

    @Test("No sessions completed in 7+ days suggests recovery conversion")
    func extendedGapSuggestsRecovery() {
        let oldCompleted = makeSession(daysFromNow: -10, type: .tempo, isCompleted: true)
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -13, sessions: [oldCompleted])

        let futureSessions = [
            makeSession(daysFromNow: 1, type: .tempo),
            makeSession(daysFromNow: 3, type: .longRun)
        ]
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -1, sessions: futureSessions)
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let conversions = results.filter { $0.type == .convertToRecoveryWeek }
        #expect(conversions.count == 1)
        #expect(conversions[0].severity == .urgent)
    }

    @Test("Recent activity produces no recovery conversion")
    func recentActivityNoConversion() {
        let recentCompleted = makeSession(daysFromNow: -2, type: .tempo, isCompleted: true)
        let futureLongRun = makeSession(daysFromNow: 2, type: .longRun)
        let week = makeWeek(daysOffset: -3, sessions: [recentCompleted, futureLongRun])
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let conversions = results.filter { $0.type == .convertToRecoveryWeek }
        #expect(conversions.isEmpty)
    }

    @Test("Already recovery week produces no conversion")
    func alreadyRecoveryNoConversion() {
        let oldCompleted = makeSession(daysFromNow: -10, type: .tempo, isCompleted: true)
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -13, sessions: [oldCompleted])

        let futureSessions = [makeSession(daysFromNow: 1, type: .recovery)]
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -1, sessions: futureSessions, isRecoveryWeek: true)
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let conversions = results.filter { $0.type == .convertToRecoveryWeek }
        #expect(conversions.isEmpty)
    }

    @Test("Recovery conversion suppresses low adherence and reschedule")
    func recoverySuppressesOthers() {
        // Extended gap + low adherence
        let prevSessions = [
            makeSession(daysFromNow: -10, type: .tempo, isCompleted: true), // last completed 10 days ago
            makeSession(daysFromNow: -9, type: .longRun),
            makeSession(daysFromNow: -8, type: .intervals)
        ]
        let prevWeek = makeWeek(weekNumber: 1, daysOffset: -13, sessions: prevSessions)

        let currentSessions = [
            makeSession(daysFromNow: -1, type: .longRun), // missed key session
            makeSession(daysFromNow: 1, type: .rest),     // available rest slot
            makeSession(daysFromNow: 2, type: .tempo)
        ]
        let currentWeek = makeWeek(weekNumber: 2, daysOffset: -2, sessions: currentSessions)
        let plan = makePlan(weeks: [prevWeek, currentWeek])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let conversions = results.filter { $0.type == .convertToRecoveryWeek }
        let reschedules = results.filter { $0.type == .rescheduleKeySession }
        let reductions = results.filter { $0.type == .reduceVolumeAfterLowAdherence }

        #expect(conversions.count == 1)
        #expect(reschedules.isEmpty)
        #expect(reductions.isEmpty)
    }

    // MARK: - Bulk Mark Missed

    @Test("Three or more missed sessions suggests bulk skip")
    func bulkSkipThreeMissed() {
        let sessions = [
            makeSession(daysFromNow: -5, type: .tempo),
            makeSession(daysFromNow: -4, type: .intervals),
            makeSession(daysFromNow: -3, type: .longRun),
            makeSession(daysFromNow: 2, type: .rest)
        ]
        let week = makeWeek(daysOffset: -6, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let bulkSkips = results.filter { $0.type == .bulkMarkMissedAsSkipped }
        #expect(bulkSkips.count == 1)
        #expect(bulkSkips[0].affectedSessionIds.count == 3)
        #expect(bulkSkips[0].severity == .suggestion)
    }

    @Test("Two missed sessions does not trigger bulk skip")
    func twoMissedNoBulkSkip() {
        let sessions = [
            makeSession(daysFromNow: -3, type: .tempo),
            makeSession(daysFromNow: -2, type: .intervals),
            makeSession(daysFromNow: 1, type: .longRun)
        ]
        let week = makeWeek(daysOffset: -4, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let bulkSkips = results.filter { $0.type == .bulkMarkMissedAsSkipped }
        #expect(bulkSkips.isEmpty)
    }

    @Test("Missed rest sessions are not counted")
    func missedRestNotCounted() {
        let sessions = [
            makeSession(daysFromNow: -5, type: .rest),
            makeSession(daysFromNow: -4, type: .rest),
            makeSession(daysFromNow: -3, type: .rest),
            makeSession(daysFromNow: -2, type: .tempo),
            makeSession(daysFromNow: 1, type: .longRun)
        ]
        let week = makeWeek(daysOffset: -6, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        let bulkSkips = results.filter { $0.type == .bulkMarkMissedAsSkipped }
        #expect(bulkSkips.isEmpty)
    }

    // MARK: - General

    @Test("Clean plan with no missed sessions produces no recommendations")
    func cleanPlanNoRecommendations() {
        let sessions = [
            makeSession(daysFromNow: -2, type: .tempo, isCompleted: true),
            makeSession(daysFromNow: -1, type: .intervals, isCompleted: true),
            makeSession(daysFromNow: 1, type: .longRun),
            makeSession(daysFromNow: 2, type: .rest)
        ]
        let week = makeWeek(daysOffset: -3, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        #expect(results.isEmpty)
    }

    @Test("Recommendations sorted by severity descending")
    func sortedBySeverity() {
        // Create conditions for both bulk skip (suggestion) and reschedule (recommended)
        let sessions = [
            makeSession(daysFromNow: -5, type: .tempo),
            makeSession(daysFromNow: -4, type: .intervals),
            makeSession(daysFromNow: -3, type: .longRun),
            makeSession(daysFromNow: 1, type: .rest)
        ]
        let week = makeWeek(daysOffset: -6, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let results = PlanAdjustmentCalculator.analyze(plan: plan, now: now)

        guard results.count >= 2 else { return }
        // First should be higher severity than last
        #expect(results.first!.severity >= results.last!.severity)
    }
}
