import Foundation
import Testing
@testable import UltraTrain

@Suite("GoalProgressCalculator")
struct GoalProgressCalculatorTests {

    // MARK: - Helpers

    private func makeGoal(
        period: GoalPeriod = .weekly,
        targetDistanceKm: Double? = nil,
        targetElevationM: Double? = nil,
        targetRunCount: Int? = nil,
        targetDurationSeconds: TimeInterval? = nil,
        startDate: Date,
        endDate: Date
    ) -> TrainingGoal {
        TrainingGoal(
            id: UUID(),
            period: period,
            targetDistanceKm: targetDistanceKm,
            targetElevationM: targetElevationM,
            targetRunCount: targetRunCount,
            targetDurationSeconds: targetDurationSeconds,
            startDate: startDate,
            endDate: endDate
        )
    }

    private func makeRun(
        date: Date,
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
            elevationLossM: 0,
            duration: duration,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components)!
    }

    // MARK: - Runs In Range

    @Test("Runs within range are summed correctly")
    func testCalculate_runsInRange_sumsCorrectly() {
        let startDate = date(2026, 1, 1)
        let endDate = date(2026, 1, 7)

        let goal = makeGoal(
            targetDistanceKm: 50,
            targetElevationM: 1000,
            targetRunCount: 4,
            targetDurationSeconds: 14400,
            startDate: startDate,
            endDate: endDate
        )

        let runs = [
            makeRun(date: date(2026, 1, 2), distanceKm: 12, elevationGainM: 300, duration: 4000),
            makeRun(date: date(2026, 1, 5), distanceKm: 8, elevationGainM: 150, duration: 2800)
        ]

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)

        #expect(progress.actualDistanceKm == 20)
        #expect(progress.actualElevationM == 450)
        #expect(progress.actualRunCount == 2)
        #expect(progress.actualDurationSeconds == 6800)
        #expect(progress.distancePercent == 20.0 / 50.0)
        #expect(progress.elevationPercent == 450.0 / 1000.0)
        #expect(progress.runCountPercent == 2.0 / 4.0)
        #expect(progress.durationPercent == 6800.0 / 14400.0)
    }

    // MARK: - Runs Outside Range

    @Test("Runs outside range are excluded")
    func testCalculate_runsOutsideRange_excluded() {
        let startDate = date(2026, 1, 1)
        let endDate = date(2026, 1, 7)

        let goal = makeGoal(
            targetDistanceKm: 50,
            targetRunCount: 3,
            startDate: startDate,
            endDate: endDate
        )

        let runs = [
            makeRun(date: date(2025, 12, 31), distanceKm: 15),  // before range
            makeRun(date: date(2026, 1, 9), distanceKm: 20)     // after range
        ]

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)

        #expect(progress.actualDistanceKm == 0)
        #expect(progress.actualRunCount == 0)
    }

    @Test("Runs on boundary dates are included")
    func testCalculate_runsOnBoundary_included() {
        let startDate = date(2026, 2, 1)
        let endDate = date(2026, 2, 7)

        let goal = makeGoal(
            targetDistanceKm: 50,
            startDate: startDate,
            endDate: endDate
        )

        let runs = [
            makeRun(date: date(2026, 2, 1, hour: 8), distanceKm: 5),   // start day
            makeRun(date: date(2026, 2, 7, hour: 20), distanceKm: 10)  // end day
        ]

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)

        #expect(progress.actualDistanceKm == 15)
        #expect(progress.actualRunCount == 2)
    }

    // MARK: - No Runs

    @Test("No runs returns zero actuals")
    func testCalculate_noRuns_returnsZero() {
        let goal = makeGoal(
            targetDistanceKm: 50,
            targetElevationM: 1000,
            targetRunCount: 4,
            targetDurationSeconds: 14400,
            startDate: date(2026, 1, 1),
            endDate: date(2026, 1, 7)
        )

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: [])

        #expect(progress.actualDistanceKm == 0)
        #expect(progress.actualElevationM == 0)
        #expect(progress.actualRunCount == 0)
        #expect(progress.actualDurationSeconds == 0)
        #expect(progress.distancePercent == 0)
        #expect(progress.elevationPercent == 0)
        #expect(progress.runCountPercent == 0)
        #expect(progress.durationPercent == 0)
    }

    // MARK: - Percentages Capped

    @Test("Percentages are capped at 1.0 when actuals exceed targets")
    func testCalculate_percentagesCappedAtOne() {
        let goal = makeGoal(
            targetDistanceKm: 10,
            targetElevationM: 100,
            targetRunCount: 1,
            targetDurationSeconds: 1800,
            startDate: date(2026, 1, 1),
            endDate: date(2026, 1, 7)
        )

        let runs = [
            makeRun(date: date(2026, 1, 3), distanceKm: 20, elevationGainM: 500, duration: 5000),
            makeRun(date: date(2026, 1, 5), distanceKm: 15, elevationGainM: 300, duration: 4000)
        ]

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)

        #expect(progress.actualDistanceKm == 35)
        #expect(progress.distancePercent == 1.0)
        #expect(progress.elevationPercent == 1.0)
        #expect(progress.runCountPercent == 1.0)
        #expect(progress.durationPercent == 1.0)
    }

    // MARK: - Nil Targets

    @Test("Nil targets produce zero percent")
    func testCalculate_nilTargets_zeroPercent() {
        let goal = makeGoal(
            targetDistanceKm: nil,
            targetElevationM: nil,
            targetRunCount: nil,
            targetDurationSeconds: nil,
            startDate: date(2026, 1, 1),
            endDate: date(2026, 1, 7)
        )

        let runs = [
            makeRun(date: date(2026, 1, 3), distanceKm: 20, elevationGainM: 500, duration: 5000)
        ]

        let progress = GoalProgressCalculator.calculate(goal: goal, runs: runs)

        // Actuals are still tracked
        #expect(progress.actualDistanceKm == 20)
        #expect(progress.actualElevationM == 500)
        #expect(progress.actualRunCount == 1)
        #expect(progress.actualDurationSeconds == 5000)

        // But percentages are zero because targets are nil
        #expect(progress.distancePercent == 0)
        #expect(progress.elevationPercent == 0)
        #expect(progress.runCountPercent == 0)
        #expect(progress.durationPercent == 0)
    }
}
