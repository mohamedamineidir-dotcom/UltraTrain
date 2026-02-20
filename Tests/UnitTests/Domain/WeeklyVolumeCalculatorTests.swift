import Foundation
import Testing
@testable import UltraTrain

@Suite("WeeklyVolumeCalculator Tests")
struct WeeklyVolumeCalculatorTests {

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    @Test("Empty runs returns volumes with zero values")
    func emptyRuns() {
        let volumes = WeeklyVolumeCalculator.compute(from: [], weekCount: 4)
        #expect(volumes.count == 4)
        #expect(volumes.allSatisfy { $0.runCount == 0 })
        #expect(volumes.allSatisfy { $0.distanceKm == 0 })
    }

    @Test("Respects weekCount parameter")
    func weekCountParam() {
        let volumes3 = WeeklyVolumeCalculator.compute(from: [], weekCount: 3)
        let volumes8 = WeeklyVolumeCalculator.compute(from: [], weekCount: 8)
        #expect(volumes3.count == 3)
        #expect(volumes8.count == 8)
    }

    @Test("Current week run included in last volume entry")
    func currentWeekRun() {
        let run = makeRun(date: .now, distanceKm: 15, elevationGainM: 300)
        let volumes = WeeklyVolumeCalculator.compute(from: [run], weekCount: 2)

        let lastWeek = volumes.last!
        #expect(lastWeek.distanceKm == 15)
        #expect(lastWeek.elevationGainM == 300)
        #expect(lastWeek.runCount == 1)
    }

    // MARK: - Planned Targets

    private func makePlan(
        weekStart: Date,
        targetVolumeKm: Double = 50,
        targetElevationGainM: Double = 1200
    ) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: weekStart,
            endDate: weekStart.adding(days: 7),
            phase: .base,
            sessions: [],
            isRecoveryWeek: false,
            targetVolumeKm: targetVolumeKm,
            targetElevationGainM: targetElevationGainM
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    @Test("Plan with matching week populates planned targets")
    func plannedTargetsFromPlan() {
        let weekStart = Date.now.startOfWeek
        let plan = makePlan(weekStart: weekStart, targetVolumeKm: 50, targetElevationGainM: 1200)

        let volumes = WeeklyVolumeCalculator.compute(from: [], plan: plan, weekCount: 2)
        let currentWeek = volumes.last!
        #expect(currentWeek.plannedDistanceKm == 50)
        #expect(currentWeek.plannedElevationGainM == 1200)
    }

    @Test("No plan means zero planned targets")
    func noPlanZeroPlanned() {
        let volumes = WeeklyVolumeCalculator.compute(from: [], plan: nil, weekCount: 2)
        #expect(volumes.allSatisfy { $0.plannedDistanceKm == 0 })
        #expect(volumes.allSatisfy { $0.plannedElevationGainM == 0 })
    }

    @Test("Non-matching plan week dates produce zero planned")
    func unmatchedWeekZeroPlanned() {
        let futureStart = Date.now.adding(weeks: 10).startOfWeek
        let plan = makePlan(weekStart: futureStart)

        let volumes = WeeklyVolumeCalculator.compute(from: [], plan: plan, weekCount: 4)
        #expect(volumes.allSatisfy { $0.plannedDistanceKm == 0 })
    }

    // MARK: - Grouping

    @Test("Runs grouped into correct weeks")
    func runsGroupedCorrectly() {
        let thisWeek = makeRun(date: .now, distanceKm: 10)
        let lastWeek = makeRun(
            date: Date.now.adding(weeks: -1),
            distanceKm: 20
        )

        let volumes = WeeklyVolumeCalculator.compute(from: [thisWeek, lastWeek], weekCount: 2)

        let older = volumes.first!
        let newer = volumes.last!
        #expect(older.distanceKm == 20)
        #expect(newer.distanceKm == 10)
    }
}
