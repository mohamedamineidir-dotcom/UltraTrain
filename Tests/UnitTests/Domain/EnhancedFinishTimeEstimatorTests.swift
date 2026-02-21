import Foundation
import Testing
@testable import UltraTrain

@Suite("EnhancedFinishTimeEstimator Tests")
struct EnhancedFinishTimeEstimatorTests {

    // MARK: - Helpers

    private let algorithmicTime: TimeInterval = 36000  // 10 hours
    private let mlPredictionTime: Double = 34200        // 9.5 hours

    private func makeMLService(
        result: Double = 34200,
        shouldThrow: Bool = false
    ) -> MockFinishTimePredictionService {
        let service = MockFinishTimePredictionService()
        service.predictionResult = result
        service.shouldThrow = shouldThrow
        return service
    }

    // MARK: - Tests

    @Test("Few runs returns pure algorithmic prediction with low confidence")
    func fewRuns_pureAlgorithmic() async {
        // runCount = 5, below minRunsForLowConfidence (10), confidence <= 30
        let result = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicTime,
            mlPredictionService: makeMLService(),
            effectiveDistanceKm: 100,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 400,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.2,
            elevationPerKm: 40,
            calibrationFactor: 1.0,
            runCount: 5
        )

        #expect(result.predictedTimeSeconds == algorithmicTime)
        #expect(result.confidencePercent == 30)
        #expect(result.blendWeight == 0)
        #expect(result.mlTimeSeconds == 0)
    }

    @Test("Medium runs (20-49) blends 50/50 between algorithmic and ML")
    func mediumRuns_blends5050() async {
        let service = makeMLService(result: mlPredictionTime)

        let result = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicTime,
            mlPredictionService: service,
            effectiveDistanceKm: 100,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 400,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.2,
            elevationPerKm: 40,
            calibrationFactor: 1.0,
            runCount: 25
        )

        // algorithmicWeightMedium = 0.50, so mlWeight = 0.50
        let expectedBlend = algorithmicTime * 0.50 + mlPredictionTime * 0.50
        #expect(result.predictedTimeSeconds == expectedBlend)
        #expect(result.confidencePercent == 60)
        #expect(result.blendWeight == 0.50)
        #expect(result.mlTimeSeconds == mlPredictionTime)
    }

    @Test("Many runs (50+) weights ML heavily at 70%")
    func manyRuns_heavyMLWeight() async {
        let service = makeMLService(result: mlPredictionTime)

        let result = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicTime,
            mlPredictionService: service,
            effectiveDistanceKm: 100,
            experienceLevel: .advanced,
            recentAvgPaceSecondsPerKm: 380,
            ctl: 70,
            tsb: 10,
            terrainDifficulty: 1.2,
            elevationPerKm: 40,
            calibrationFactor: 1.0,
            runCount: 60
        )

        // algorithmicWeightHigh = 0.30, so mlWeight = 0.70
        let expectedBlend = algorithmicTime * 0.30 + mlPredictionTime * 0.70
        #expect(result.predictedTimeSeconds == expectedBlend)
        #expect(result.confidencePercent == 80)
        #expect(result.blendWeight == 0.70)
    }

    @Test("No ML service falls back to pure algorithmic result")
    func noMLService_fallsBackToAlgorithmic() async {
        let result = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicTime,
            mlPredictionService: nil,
            effectiveDistanceKm: 100,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 400,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.2,
            elevationPerKm: 40,
            calibrationFactor: 1.0,
            runCount: 30
        )

        #expect(result.predictedTimeSeconds == algorithmicTime)
        #expect(result.confidencePercent == 30)
        #expect(result.blendWeight == 0)
        #expect(result.mlTimeSeconds == 0)
    }

    @Test("ML service failure falls back to pure algorithmic result")
    func mlServiceFailure_fallsBackToAlgorithmic() async {
        let service = makeMLService(shouldThrow: true)

        let result = await EnhancedFinishTimeEstimator.blend(
            algorithmicTimeSeconds: algorithmicTime,
            mlPredictionService: service,
            effectiveDistanceKm: 100,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 400,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.2,
            elevationPerKm: 40,
            calibrationFactor: 1.0,
            runCount: 30
        )

        #expect(result.predictedTimeSeconds == algorithmicTime)
        #expect(result.confidencePercent == 30)
        #expect(result.blendWeight == 0)
    }
}
