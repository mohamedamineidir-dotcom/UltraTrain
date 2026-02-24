import Foundation
import CoreML
import os

/// CoreML-based finish time prediction service.
///
/// Attempts to load a trained `FinishTimePredictor` CoreML model.
/// Falls back to the regression approximation if the model is unavailable.
actor FinishTimeMLService: FinishTimePredictionServiceProtocol {

    private let logger = Logger.ml
    private var coreMLModel: FinishTimePredictor?

    init() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly
            coreMLModel = try FinishTimePredictor(configuration: config)
            logger.info("CoreML FinishTimePredictor model loaded successfully")
        } catch {
            logger.info("CoreML model not available, using regression fallback: \(error.localizedDescription)")
            coreMLModel = nil
        }
    }

    // MARK: - Prediction

    func predict(
        effectiveDistanceKm: Double,
        experienceLevel: ExperienceLevel,
        recentAvgPaceSecondsPerKm: Double,
        ctl: Double,
        tsb: Double,
        terrainDifficulty: Double,
        elevationPerKm: Double,
        calibrationFactor: Double
    ) async throws -> Double {
        guard effectiveDistanceKm > 0, recentAvgPaceSecondsPerKm > 0 else {
            logger.warning("Invalid inputs: distance=\(effectiveDistanceKm), pace=\(recentAvgPaceSecondsPerKm)")
            return 0
        }

        if let model = coreMLModel {
            do {
                let result = try coreMLPrediction(
                    model: model,
                    effectiveDistanceKm: effectiveDistanceKm,
                    experienceLevel: experienceLevel,
                    recentAvgPaceSecondsPerKm: recentAvgPaceSecondsPerKm,
                    ctl: ctl,
                    tsb: tsb,
                    terrainDifficulty: terrainDifficulty,
                    elevationPerKm: elevationPerKm,
                    calibrationFactor: calibrationFactor
                )
                logger.debug("CoreML prediction: \(result)s for \(effectiveDistanceKm)km effective")
                return max(0, result)
            } catch {
                logger.warning("CoreML prediction failed, falling back to regression: \(error.localizedDescription)")
            }
        }

        return regressionFallback(
            effectiveDistanceKm: effectiveDistanceKm,
            experienceLevel: experienceLevel,
            recentAvgPaceSecondsPerKm: recentAvgPaceSecondsPerKm,
            ctl: ctl,
            tsb: tsb,
            terrainDifficulty: terrainDifficulty,
            elevationPerKm: elevationPerKm,
            calibrationFactor: calibrationFactor
        )
    }

    // MARK: - CoreML Prediction

    private func coreMLPrediction(
        model: FinishTimePredictor,
        effectiveDistanceKm: Double,
        experienceLevel: ExperienceLevel,
        recentAvgPaceSecondsPerKm: Double,
        ctl: Double,
        tsb: Double,
        terrainDifficulty: Double,
        elevationPerKm: Double,
        calibrationFactor: Double
    ) throws -> Double {
        let experienceNumeric: Double = switch experienceLevel {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        case .elite: 3
        }

        let input = FinishTimePredictorInput(
            effectiveDistanceKm: effectiveDistanceKm,
            experienceLevel: experienceNumeric,
            avgPaceSecondsPerKm: recentAvgPaceSecondsPerKm,
            ctl: ctl,
            tsb: tsb,
            terrainDifficulty: terrainDifficulty,
            elevationPerKm: elevationPerKm,
            calibrationFactor: calibrationFactor
        )

        let output = try model.prediction(input: input)
        return output.predictedTimeSeconds
    }

    // MARK: - Regression Fallback

    private func regressionFallback(
        effectiveDistanceKm: Double,
        experienceLevel: ExperienceLevel,
        recentAvgPaceSecondsPerKm: Double,
        ctl: Double,
        tsb: Double,
        terrainDifficulty: Double,
        elevationPerKm: Double,
        calibrationFactor: Double
    ) -> Double {
        let expMult = experienceMultiplier(for: experienceLevel)
        let basePrediction = effectiveDistanceKm * recentAvgPaceSecondsPerKm * expMult
        let fitnessAdjustment = computeFitnessAdjustment(ctl: ctl, tsb: tsb)
        let terrainAdjustment = computeTerrainAdjustment(
            terrainDifficulty: terrainDifficulty,
            elevationPerKm: elevationPerKm
        )

        let calibrated = basePrediction * fitnessAdjustment * terrainAdjustment * calibrationFactor

        let debugMessage: String = "Regression fallback: \(calibrated)s for \(effectiveDistanceKm)km effective"
            + " (base=\(basePrediction), fitness=\(fitnessAdjustment),"
            + " terrain=\(terrainAdjustment), cal=\(calibrationFactor))"
        logger.debug("\(debugMessage, privacy: .public)")

        return max(0, calibrated)
    }

    // MARK: - Component Calculations

    private func experienceMultiplier(for level: ExperienceLevel) -> Double {
        switch level {
        case .beginner: return 1.15
        case .intermediate: return 1.0
        case .advanced: return 0.92
        case .elite: return 0.85
        }
    }

    private func computeFitnessAdjustment(ctl: Double, tsb: Double) -> Double {
        let ctlEffect = ctl * 0.001
        let tsbEffect: Double
        if tsb < 0 {
            tsbEffect = abs(tsb) * 0.002
        } else {
            tsbEffect = -tsb * 0.001
        }
        return max(0.80, min(1.20, 1.0 - ctlEffect + tsbEffect))
    }

    private func computeTerrainAdjustment(
        terrainDifficulty: Double,
        elevationPerKm: Double
    ) -> Double {
        let difficultyEffect = 1.0 + (terrainDifficulty - 1.0) * 0.1
        let elevationEffect = 1.0 + max(0, elevationPerKm - 30) * 0.002
        return difficultyEffect * elevationEffect
    }
}
