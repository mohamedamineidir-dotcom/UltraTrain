import Foundation
import Testing
@testable import UltraTrain

@Suite("Missed Session Redistributor Tests")
struct MissedSessionRedistributorTests {

    // MARK: - Helpers

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeSession(
        id: UUID = UUID(),
        daysFromNow: Int,
        type: SessionType = .tempo,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        distanceKm: Double = 10,
        elevationGainM: Double = 200
    ) -> TrainingSession {
        TrainingSession(
            id: id,
            date: Calendar.current.date(byAdding: .day, value: daysFromNow, to: now)!,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: elevationGainM,
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
        isRecoveryWeek: Bool = false
    ) -> TrainingWeek {
        let start = Calendar.current.date(byAdding: .day, value: daysOffset, to: now)!
        let end = Calendar.current.date(byAdding: .day, value: daysOffset + 6, to: now)!
        return TrainingWeek(
            id: UUID(),
            weekNumber: weekNumber,
            startDate: start,
            endDate: end,
            phase: .build,
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

    // MARK: - No Redistribution Needed

    @Test("No missed sessions returns empty result")
    func noMissedSessions() {
        let sessions = [
            makeSession(daysFromNow: -2, type: .longRun, isCompleted: true),
            makeSession(daysFromNow: 2, type: .tempo)
        ]
        let week = makeWeek(daysOffset: -3, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        #expect(result.recommendations.isEmpty)
        #expect(result.unrecoverableDistanceKm == 0)
        #expect(result.unrecoverableElevationM == 0)
    }

    @Test("Nil currentWeekIndex returns empty result")
    func nilWeekIndex() {
        let sessions = [makeSession(daysFromNow: -1, type: .longRun)]
        let week = makeWeek(daysOffset: -3, sessions: sessions)
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: nil)

        #expect(result.recommendations.isEmpty)
    }

    @Test("Missed sessions handled by rest slots produce no redistribution")
    func missedWithRestSlot() {
        let missed = makeSession(daysFromNow: -2, type: .longRun)
        let rest = makeSession(daysFromNow: 2, type: .rest)
        let future = makeSession(daysFromNow: 3, type: .tempo)
        let week = makeWeek(daysOffset: -3, sessions: [missed, rest, future])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        // The one missed session can be rescheduled to the rest slot
        #expect(result.recommendations.isEmpty)
    }

    // MARK: - Volume Redistribution

    @Test("Missed long run without rest slot triggers volume redistribution")
    func missedLongRunRedistributes() {
        let missed = makeSession(daysFromNow: -2, type: .longRun, distanceKm: 20, elevationGainM: 500)
        let future1 = makeSession(daysFromNow: 1, type: .tempo, distanceKm: 10, elevationGainM: 200)
        let future2 = makeSession(daysFromNow: 3, type: .recovery, distanceKm: 8, elevationGainM: 100)
        let future3 = makeSession(daysFromNow: 5, type: .longRun, distanceKm: 22, elevationGainM: 600)
        let week = makeWeek(daysOffset: -3, sessions: [missed, future1, future2, future3])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let redistRecs = result.recommendations.filter { $0.type == .redistributeMissedVolume }
        #expect(redistRecs.count == 1)
        #expect(redistRecs[0].volumeAdjustments.count <= 3)
        #expect(redistRecs[0].affectedSessionIds.contains(missed.id))
    }

    @Test("Volume adjustments respect 20% cap per session")
    func volumeAdjustmentsCapped() {
        let missed = makeSession(daysFromNow: -2, type: .longRun, distanceKm: 100, elevationGainM: 5000)
        let future = makeSession(daysFromNow: 2, type: .tempo, distanceKm: 10, elevationGainM: 200)
        let week = makeWeek(daysOffset: -3, sessions: [missed, future])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let redistRecs = result.recommendations.filter { $0.type == .redistributeMissedVolume }
        #expect(redistRecs.count == 1)
        for adj in redistRecs[0].volumeAdjustments {
            // Each adjustment should be <= 20% of the target session's distance (10km * 0.2 = 2km)
            #expect(adj.addedDistanceKm <= 10 * 0.2 + 0.001)
        }
        // With such a large missed volume and small target, most is unrecoverable
        #expect(result.unrecoverableDistanceKm > 0)
    }

    @Test("Missed verticalGain triggers volume redistribution")
    func missedVerticalGainRedistributes() {
        let missed = makeSession(daysFromNow: -1, type: .verticalGain, distanceKm: 15, elevationGainM: 800)
        let future = makeSession(daysFromNow: 2, type: .tempo, distanceKm: 12, elevationGainM: 300)
        let week = makeWeek(daysOffset: -3, sessions: [missed, future])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let redistRecs = result.recommendations.filter { $0.type == .redistributeMissedVolume }
        #expect(redistRecs.count == 1)
    }

    @Test("Missed backToBack triggers volume redistribution")
    func missedBackToBackRedistributes() {
        let missed = makeSession(daysFromNow: -1, type: .backToBack, distanceKm: 18, elevationGainM: 400)
        let future = makeSession(daysFromNow: 2, type: .longRun, distanceKm: 20, elevationGainM: 500)
        let week = makeWeek(daysOffset: -3, sessions: [missed, future])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let redistRecs = result.recommendations.filter { $0.type == .redistributeMissedVolume }
        #expect(redistRecs.count == 1)
    }

    @Test("No future sessions means fully unrecoverable volume")
    func noFutureSessionsUnrecoverable() {
        let missed = makeSession(daysFromNow: -1, type: .longRun, distanceKm: 20, elevationGainM: 500)
        let week = makeWeek(daysOffset: -3, sessions: [missed])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        #expect(result.recommendations.isEmpty)
        #expect(result.unrecoverableDistanceKm == 20)
        #expect(result.unrecoverableElevationM == 500)
    }

    // MARK: - Quality Conversion

    @Test("Missed intervals converts recovery to quality")
    func missedIntervalsConvertsRecovery() {
        let missed = makeSession(daysFromNow: -1, type: .intervals, distanceKm: 8, elevationGainM: 100)
        let futureRecovery = makeSession(daysFromNow: 2, type: .recovery, distanceKm: 5, elevationGainM: 50)
        let week = makeWeek(daysOffset: -3, sessions: [missed, futureRecovery])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let convertRecs = result.recommendations.filter { $0.type == .convertEasyToQuality }
        #expect(convertRecs.count == 1)
        #expect(convertRecs[0].affectedSessionIds.contains(missed.id))
        #expect(convertRecs[0].affectedSessionIds.contains(futureRecovery.id))
        #expect(convertRecs[0].volumeAdjustments.first?.newType == .intervals)
    }

    @Test("Missed tempo with no recovery session is unrecoverable")
    func missedTempoNoRecovery() {
        let missed = makeSession(daysFromNow: -1, type: .tempo, distanceKm: 12, elevationGainM: 250)
        let futureHard = makeSession(daysFromNow: 2, type: .longRun, distanceKm: 20, elevationGainM: 500)
        let week = makeWeek(daysOffset: -3, sessions: [missed, futureHard])
        let plan = makePlan(weeks: [week])

        let result = MissedSessionRedistributor.analyzeRedistribution(plan: plan, now: now, currentWeekIndex: 0)

        let convertRecs = result.recommendations.filter { $0.type == .convertEasyToQuality }
        #expect(convertRecs.isEmpty)
        #expect(result.unrecoverableDistanceKm == 12)
        #expect(result.unrecoverableElevationM == 250)
    }

    // MARK: - Accumulated Missed Volume

    @Test("Accumulated missed volume counts sessions in lookback window")
    func accumulatedMissedVolume() {
        let missed1 = makeSession(daysFromNow: -3, type: .tempo, distanceKm: 10, elevationGainM: 200)
        let missed2 = makeSession(daysFromNow: -5, type: .longRun, distanceKm: 20, elevationGainM: 500)
        let completed = makeSession(daysFromNow: -4, type: .recovery, isCompleted: true, distanceKm: 5, elevationGainM: 50)
        let week = makeWeek(daysOffset: -7, sessions: [missed1, missed2, completed])
        let plan = makePlan(weeks: [week])

        let (dist, elev) = MissedSessionRedistributor.calculateAccumulatedMissedVolume(
            plan: plan, now: now, lookbackWeeks: 2
        )

        #expect(dist == 30) // 10 + 20
        #expect(elev == 700) // 200 + 500
    }

    @Test("Completed and skipped sessions excluded from accumulated missed")
    func accumulatedExcludesCompletedSkipped() {
        let completed = makeSession(daysFromNow: -3, type: .tempo, isCompleted: true, distanceKm: 10)
        let skipped = makeSession(daysFromNow: -2, type: .longRun, isSkipped: true, distanceKm: 20)
        let rest = makeSession(daysFromNow: -1, type: .rest, distanceKm: 0)
        let week = makeWeek(daysOffset: -4, sessions: [completed, skipped, rest])
        let plan = makePlan(weeks: [week])

        let (dist, _) = MissedSessionRedistributor.calculateAccumulatedMissedVolume(
            plan: plan, now: now, lookbackWeeks: 2
        )

        #expect(dist == 0)
    }

    @Test("Sessions outside lookback window excluded")
    func accumulatedLookbackWindow() {
        let old = makeSession(daysFromNow: -20, type: .longRun, distanceKm: 25, elevationGainM: 600)
        let recent = makeSession(daysFromNow: -3, type: .tempo, distanceKm: 10, elevationGainM: 200)
        let week1 = makeWeek(weekNumber: 1, daysOffset: -21, sessions: [old])
        let week2 = makeWeek(weekNumber: 2, daysOffset: -4, sessions: [recent])
        let plan = makePlan(weeks: [week1, week2])

        let (dist, _) = MissedSessionRedistributor.calculateAccumulatedMissedVolume(
            plan: plan, now: now, lookbackWeeks: 2
        )

        #expect(dist == 10) // Only the recent one
    }
}
