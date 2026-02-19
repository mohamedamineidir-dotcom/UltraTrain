import Foundation
import Testing
@testable import UltraTrain

@Suite("AdvancedRunMetrics Calculator Tests")
struct AdvancedRunMetricsCalculatorTests {

    // MARK: - Helpers

    private func makeSplits(paces: [Double]) -> [Split] {
        paces.enumerated().map { index, pace in
            Split(
                id: UUID(),
                kilometerNumber: index + 1,
                duration: pace,
                elevationChangeM: 0,
                averageHeartRate: 150
            )
        }
    }

    private func makeRun(
        distanceKm: Double = 10,
        elevationGainM: Double = 300,
        duration: TimeInterval = 3600,
        splits: [Split]? = nil,
        gpsTrack: [TrackPoint] = []
    ) -> CompletedRun {
        let defaultSplits = splits ?? makeSplits(paces: Array(repeating: 360, count: 10))
        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 250,
            duration: duration,
            averageHeartRate: 155,
            maxHeartRate: 180,
            averagePaceSecondsPerKm: duration / distanceKm,
            gpsTrack: gpsTrack,
            splits: defaultSplits,
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    // MARK: - Pace Variability

    @Test("Pace variability is 0 for identical splits")
    func identicalSplitsVariability() {
        let splits = makeSplits(paces: [360, 360, 360, 360, 360])
        let result = AdvancedRunMetricsCalculator.paceVariabilityIndex(splits: splits)
        #expect(result == 0)
    }

    @Test("Pace variability increases with varied splits")
    func variedSplitsVariability() {
        let uniform = makeSplits(paces: [360, 360, 360, 360])
        let varied = makeSplits(paces: [300, 420, 330, 390])

        let uniformCV = AdvancedRunMetricsCalculator.paceVariabilityIndex(splits: uniform)
        let variedCV = AdvancedRunMetricsCalculator.paceVariabilityIndex(splits: varied)

        #expect(variedCV > uniformCV)
    }

    @Test("Pace variability returns 0 for single split")
    func singleSplitVariability() {
        let splits = makeSplits(paces: [360])
        let result = AdvancedRunMetricsCalculator.paceVariabilityIndex(splits: splits)
        #expect(result == 0)
    }

    // MARK: - Climbing Efficiency

    @Test("Climbing efficiency nil when not enough uphill splits")
    func noUphillSplits() {
        let splits = makeSplits(paces: [360, 360, 360])
        let run = makeRun(splits: splits)
        let result = AdvancedRunMetricsCalculator.climbingEfficiency(run: run)
        #expect(result == nil)
    }

    @Test("Climbing efficiency calculated with uphill and flat splits")
    func climbingEfficiencyCalculated() {
        var splits: [Split] = []
        for i in 1...3 {
            splits.append(Split(id: UUID(), kilometerNumber: i, duration: 360, elevationChangeM: 0, averageHeartRate: 150))
        }
        for i in 4...6 {
            splits.append(Split(id: UUID(), kilometerNumber: i, duration: 420, elevationChangeM: 50, averageHeartRate: 160))
        }
        let run = makeRun(splits: splits)
        let result = AdvancedRunMetricsCalculator.climbingEfficiency(run: run)
        #expect(result != nil)
        #expect(result! > 0)
    }

    // MARK: - Calorie Burn

    @Test("Calorie estimate scales with weight")
    func caloriesScaleWithWeight() {
        let light = AdvancedRunMetricsCalculator.estimatedCalories(duration: 3600, weightKg: 60, averagePace: 360)
        let heavy = AdvancedRunMetricsCalculator.estimatedCalories(duration: 3600, weightKg: 90, averagePace: 360)
        #expect(heavy > light)
    }

    @Test("Calorie estimate uses default weight when nil")
    func caloriesDefaultWeight() {
        let result = AdvancedRunMetricsCalculator.estimatedCalories(duration: 3600, weightKg: nil, averagePace: 360)
        #expect(result > 0)
    }

    @Test("Faster pace gives higher MET and more calories")
    func fasterPaceHigherCalories() {
        let fast = AdvancedRunMetricsCalculator.estimatedCalories(duration: 3600, weightKg: 70, averagePace: 280)
        let slow = AdvancedRunMetricsCalculator.estimatedCalories(duration: 3600, weightKg: 70, averagePace: 480)
        #expect(fast > slow)
    }

    // MARK: - Training Effect

    @Test("Training effect uses duration when no HR data")
    func trainingEffectNoHR() {
        let short = AdvancedRunMetricsCalculator.trainingEffectScore(gpsTrack: [], duration: 600, maxHeartRate: 185)
        let long = AdvancedRunMetricsCalculator.trainingEffectScore(gpsTrack: [], duration: 5400, maxHeartRate: 185)
        #expect(long > short)
    }

    @Test("Training effect is between 1 and 5")
    func trainingEffectRange() {
        let result = AdvancedRunMetricsCalculator.trainingEffectScore(gpsTrack: [], duration: 3600, maxHeartRate: nil)
        #expect(result >= 1.0)
        #expect(result <= 5.0)
    }

    // MARK: - Gradient-Adjusted Pace

    @Test("Gradient-adjusted pace accounts for elevation")
    func gradientAdjustedPace() {
        let flatRun = makeRun(distanceKm: 10, elevationGainM: 0, duration: 3600)
        let hillyRun = makeRun(distanceKm: 10, elevationGainM: 500, duration: 3600)

        let flatPace = AdvancedRunMetricsCalculator.gradientAdjustedPace(run: flatRun)
        let hillyPace = AdvancedRunMetricsCalculator.gradientAdjustedPace(run: hillyRun)

        #expect(hillyPace < flatPace)
    }

    // MARK: - Full Calculate

    @Test("Calculate returns complete metrics")
    func fullCalculate() {
        let run = makeRun()
        let result = AdvancedRunMetricsCalculator.calculate(
            run: run,
            athleteWeightKg: 70,
            maxHeartRate: 185
        )

        #expect(result.paceVariabilityIndex >= 0)
        #expect(result.estimatedCalories > 0)
        #expect(result.trainingEffectScore >= 1.0)
        #expect(result.trainingEffectScore <= 5.0)
        #expect(result.averageGradientAdjustedPace > 0)
    }
}
