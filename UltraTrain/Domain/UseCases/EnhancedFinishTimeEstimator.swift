import Foundation
import os

/// Blends algorithmic finish time estimates with ML-based predictions.
///
/// The blend weight between the two approaches depends on how much training data
/// is available. With few runs the algorithmic approach dominates; as data grows
/// the ML model receives progressively more weight.
enum EnhancedFinishTimeEstimator {

    private static let logger = Logger.enhancedEstimator

    // MARK: - Public API

    static func blend(
        algorithmicTimeSeconds: TimeInterval,
        mlPredictionService: (any FinishTimePredictionServiceProtocol)?,
        effectiveDistanceKm: Double,
        experienceLevel: ExperienceLevel,
        recentAvgPaceSecondsPerKm: Double,
        ctl: Double,
        tsb: Double,
        terrainDifficulty: Double,
        elevationPerKm: Double,
        calibrationFactor: Double,
        runCount: Int
    ) async -> MLFinishTimePrediction {

        // Determine blend weight and confidence based on data availability
        let (algorithmicWeight, confidence) = weights(for: runCount)

        // Not enough data for ML -- pure algorithmic
        guard confidence > 30 else {
            return pureAlgorithmicResult(
                algorithmicTimeSeconds: algorithmicTimeSeconds,
                runCount: runCount
            )
        }

        // Attempt ML prediction
        guard let mlService = mlPredictionService else {
            logger.info("No ML service available, returning algorithmic-only prediction")
            return pureAlgorithmicResult(
                algorithmicTimeSeconds: algorithmicTimeSeconds,
                runCount: runCount
            )
        }

        let mlTimeSeconds: TimeInterval
        do {
            mlTimeSeconds = try await mlService.predict(
                effectiveDistanceKm: effectiveDistanceKm,
                experienceLevel: experienceLevel,
                recentAvgPaceSecondsPerKm: recentAvgPaceSecondsPerKm,
                ctl: ctl,
                tsb: tsb,
                terrainDifficulty: terrainDifficulty,
                elevationPerKm: elevationPerKm,
                calibrationFactor: calibrationFactor
            )
        } catch {
            logger.warning("ML prediction failed, using algorithmic only: \(error.localizedDescription)")
            return pureAlgorithmicResult(
                algorithmicTimeSeconds: algorithmicTimeSeconds,
                runCount: runCount
            )
        }

        let mlWeight = 1.0 - algorithmicWeight
        let blended = algorithmicTimeSeconds * algorithmicWeight + mlTimeSeconds * mlWeight

        logger.debug("Blended prediction: \(blended, privacy: .public)s (algo=\(algorithmicTimeSeconds, privacy: .public)s * \(algorithmicWeight, privacy: .public) + ml=\(mlTimeSeconds, privacy: .public)s * \(mlWeight, privacy: .public))")

        return MLFinishTimePrediction(
            id: UUID(),
            predictedTimeSeconds: blended,
            confidencePercent: confidence,
            algorithmicTimeSeconds: algorithmicTimeSeconds,
            mlTimeSeconds: mlTimeSeconds,
            blendWeight: mlWeight,
            modelVersion: AppConfiguration.MLPredictor.modelVersion,
            predictionDate: Date.now,
            runCount: runCount
        )
    }

    // MARK: - Private Helpers

    private static func weights(for runCount: Int) -> (algorithmicWeight: Double, confidence: Int) {
        if runCount >= AppConfiguration.MLPredictor.minRunsForHighConfidence {
            return (AppConfiguration.MLPredictor.algorithmicWeightHigh, 80)
        } else if runCount >= AppConfiguration.MLPredictor.minRunsForMediumConfidence {
            return (AppConfiguration.MLPredictor.algorithmicWeightMedium, 60)
        } else if runCount >= AppConfiguration.MLPredictor.minRunsForLowConfidence {
            return (AppConfiguration.MLPredictor.algorithmicWeightLow, 40)
        } else {
            return (1.0, 30)
        }
    }

    private static func pureAlgorithmicResult(
        algorithmicTimeSeconds: TimeInterval,
        runCount: Int
    ) -> MLFinishTimePrediction {
        MLFinishTimePrediction(
            id: UUID(),
            predictedTimeSeconds: algorithmicTimeSeconds,
            confidencePercent: 30,
            algorithmicTimeSeconds: algorithmicTimeSeconds,
            mlTimeSeconds: 0,
            blendWeight: 0,
            modelVersion: AppConfiguration.MLPredictor.modelVersion,
            predictionDate: Date.now,
            runCount: runCount
        )
    }
}
