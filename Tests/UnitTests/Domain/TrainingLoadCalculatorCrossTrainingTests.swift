import Testing
import Foundation
@testable import UltraTrain

@Suite("TrainingLoadCalculator Cross-Training Tests")
struct TrainingLoadCalculatorCrossTrainingTests {

    private func makeRun(
        distanceKm: Double = 10,
        elevationGainM: Double = 0,
        duration: TimeInterval = 3600,
        activityType: ActivityType = .running,
        tss: Double? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 0,
            duration: duration,
            averagePaceSecondsPerKm: distanceKm > 0 ? duration / distanceKm : 0,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0,
            trainingStressScore: tss,
            activityType: activityType
        )
    }

    // MARK: - Running Load

    @Test("Running load uses distance + elevation/100")
    func runningLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 20, elevationGainM: 500, activityType: .running)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = 20.0 + (500.0 / 100.0)
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    @Test("Trail running load uses same formula as running")
    func trailRunningLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 15, elevationGainM: 1000, activityType: .trailRunning)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = 15.0 + (1000.0 / 100.0)
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    @Test("Hiking load uses same formula as running")
    func hikingLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 12, elevationGainM: 800, activityType: .hiking)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = 12.0 + (800.0 / 100.0)
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    // MARK: - Cycling Load

    @Test("Cycling load uses distance/3 + elevation/100")
    func cyclingLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 60, elevationGainM: 600, activityType: .cycling)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = (60.0 / 3.0) + (600.0 / 100.0)
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    // MARK: - Swimming Load

    @Test("Swimming load uses distance * 4")
    func swimmingLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 3, activityType: .swimming)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = 3.0 * 4.0
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    // MARK: - Duration-Based Load

    @Test("Strength load uses duration-based formula")
    func strengthLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 0, duration: 3600, activityType: .strength)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = (3600.0 / 3600.0) * 30.0
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    @Test("Yoga load uses duration-based formula")
    func yogaLoad() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 0, duration: 5400, activityType: .yoga)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let expectedLoad = (5400.0 / 3600.0) * 30.0
        #expect(result.currentWeekLoad.actualLoad == expectedLoad)
    }

    // MARK: - TSS Override

    @Test("TSS overrides sport-specific calculation")
    func tssOverride() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [makeRun(distanceKm: 100, activityType: .cycling, tss: 42)]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        #expect(result.currentWeekLoad.actualLoad == 42.0)
    }

    // MARK: - Mixed Activities

    @Test("Mixed activity types accumulate correctly")
    func mixedActivities() async throws {
        let calculator = TrainingLoadCalculator()
        let runs = [
            makeRun(distanceKm: 10, elevationGainM: 200, activityType: .running),
            makeRun(distanceKm: 30, elevationGainM: 300, activityType: .cycling),
            makeRun(distanceKm: 2, activityType: .swimming)
        ]
        let result = try await calculator.execute(runs: runs, plan: nil, asOf: .now)

        let runLoad = 10.0 + (200.0 / 100.0)
        let cycleLoad = (30.0 / 3.0) + (300.0 / 100.0)
        let swimLoad = 2.0 * 4.0
        #expect(result.currentWeekLoad.actualLoad == runLoad + cycleLoad + swimLoad)
    }
}
