import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Load Calculator Tests")
struct TrainingLoadCalculatorTests {

    private let calculator = TrainingLoadCalculator()
    private let athleteId = UUID()

    private func makeRun(
        daysAgo: Int = 0,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now.adding(days: -daysAgo),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makePlan() -> TrainingPlan {
        let weeks = (0..<4).map { i in
            TrainingWeek(
                id: UUID(),
                weekNumber: i + 1,
                startDate: Date.now.adding(weeks: -3 + i).startOfWeek,
                endDate: Date.now.adding(weeks: -3 + i).startOfWeek.adding(days: 7),
                phase: .base,
                sessions: [],
                isRecoveryWeek: false,
                targetVolumeKm: 50,
                targetElevationGainM: 1000
            )
        }
        return TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: UUID(),
            createdAt: .now,
            weeks: weeks,
            intermediateRaceIds: []
        )
    }

    // MARK: - Empty / Basic

    @Test("Empty runs returns empty history with zero load")
    func emptyRuns() async throws {
        let summary = try await calculator.execute(runs: [], plan: nil, asOf: .now)
        #expect(summary.currentWeekLoad.actualLoad == 0)
        #expect(summary.weeklyHistory.count == 12)
        #expect(summary.acrTrend.isEmpty)
        #expect(summary.monotony == 0)
        #expect(summary.monotonyLevel == .low)
    }

    @Test("Single run produces non-zero load in current week")
    func singleRun() async throws {
        let run = makeRun(daysAgo: 0, distanceKm: 10, elevationGainM: 200)
        let summary = try await calculator.execute(runs: [run], plan: nil, asOf: .now)

        // Load = 10 + 200/100 = 12
        #expect(summary.currentWeekLoad.actualLoad > 0)
        #expect(summary.currentWeekLoad.distanceKm == 10)
    }

    // MARK: - Effort Load Formula

    @Test("Effort load uses distance plus elevation/100")
    func effortLoadFormula() async throws {
        let run = makeRun(daysAgo: 0, distanceKm: 20, elevationGainM: 500)
        let summary = try await calculator.execute(runs: [run], plan: nil, asOf: .now)

        // Expected: 20 + 500/100 = 25
        let expectedLoad = 25.0
        #expect(abs(summary.currentWeekLoad.actualLoad - expectedLoad) < 0.01)
    }

    // MARK: - Planned vs Actual

    @Test("Planned load comes from training plan weeks")
    func plannedLoad() async throws {
        let plan = makePlan()
        let run = makeRun(daysAgo: 0)
        let summary = try await calculator.execute(runs: [run], plan: plan, asOf: .now)

        let currentWeek = summary.weeklyHistory.last!
        // Planned = 50 + 1000/100 = 60
        #expect(currentWeek.plannedLoad > 0)
    }

    @Test("No plan means zero planned load")
    func noPlanZeroPlannedLoad() async throws {
        let run = makeRun(daysAgo: 0)
        let summary = try await calculator.execute(runs: [run], plan: nil, asOf: .now)
        #expect(summary.currentWeekLoad.plannedLoad == 0)
    }

    // MARK: - Weekly History

    @Test("History contains 12 weeks")
    func historyLength() async throws {
        let runs = (0..<20).map { makeRun(daysAgo: $0) }
        let summary = try await calculator.execute(runs: runs, plan: nil, asOf: .now)
        #expect(summary.weeklyHistory.count == 12)
    }

    @Test("Old runs outside 12-week window are excluded")
    func oldRunsExcluded() async throws {
        let oldRun = makeRun(daysAgo: 100, distanceKm: 50)
        let summary = try await calculator.execute(runs: [oldRun], plan: nil, asOf: .now)

        let totalLoad = summary.weeklyHistory.reduce(0.0) { $0 + $1.actualLoad }
        #expect(totalLoad == 0)
    }

    // MARK: - ACR Trend

    @Test("ACR trend has data points when runs exist")
    func acrTrendPopulated() async throws {
        let runs = (0..<14).map { makeRun(daysAgo: $0) }
        let summary = try await calculator.execute(runs: runs, plan: nil, asOf: .now)
        #expect(summary.acrTrend.count == 28)
    }

    @Test("ACR is zero with no runs")
    func acrZeroNoRuns() async throws {
        let summary = try await calculator.execute(runs: [], plan: nil, asOf: .now)
        #expect(summary.acrTrend.isEmpty)
    }

    // MARK: - Monotony

    @Test("Monotony is zero with no runs")
    func monotonyZeroNoRuns() async throws {
        let summary = try await calculator.execute(runs: [], plan: nil, asOf: .now)
        #expect(summary.monotony == 0)
    }

    @Test("Same daily load produces high monotony")
    func highMonotony() async throws {
        // Same load every day for 7 days
        let runs = (0..<7).map { makeRun(daysAgo: $0, distanceKm: 10, elevationGainM: 200) }
        let summary = try await calculator.execute(runs: runs, plan: nil, asOf: .now)
        #expect(summary.monotony > 2.0)
        #expect(summary.monotonyLevel == .high)
    }

    @Test("Varied loads produce lower monotony")
    func lowMonotony() async throws {
        // Vary the load significantly
        let runs = [
            makeRun(daysAgo: 0, distanceKm: 30, elevationGainM: 1000),
            makeRun(daysAgo: 2, distanceKm: 5, elevationGainM: 50),
            makeRun(daysAgo: 4, distanceKm: 15, elevationGainM: 300),
        ]
        let summary = try await calculator.execute(runs: runs, plan: nil, asOf: .now)
        #expect(summary.monotony < 2.0)
    }
}
