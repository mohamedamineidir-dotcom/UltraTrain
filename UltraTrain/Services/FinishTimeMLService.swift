import Foundation
import os

/// CoreML-based finish time prediction service.
///
/// Currently uses a regression approximation as a stub implementation.
/// When a real `.mlmodel` file is added to the project, this service
/// should be updated to load the model and run CoreML inference instead.
///
/// The regression formula accounts for:
/// - Base pace adjusted for effective distance
/// - Experience level multiplier
/// - Fitness (CTL) and freshness (TSB) adjustments
/// - Terrain difficulty factor
/// - Elevation density impact
/// - Per-athlete calibration factor
actor FinishTimeMLService: FinishTimePredictionServiceProtocol {

    private let logger = Logger.ml

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

        let experienceMultiplier = experienceMultiplier(for: experienceLevel)
        let basePrediction = computeBasePrediction(
            effectiveDistanceKm: effectiveDistanceKm,
            paceSecondsPerKm: recentAvgPaceSecondsPerKm,
            experienceMultiplier: experienceMultiplier
        )

        let fitnessAdjustment = computeFitnessAdjustment(ctl: ctl, tsb: tsb)
        let terrainAdjustment = computeTerrainAdjustment(
            terrainDifficulty: terrainDifficulty,
            elevationPerKm: elevationPerKm
        )

        let calibrated = basePrediction * fitnessAdjustment * terrainAdjustment * calibrationFactor

        let debugMessage: String = "ML prediction: \(calibrated)s for \(effectiveDistanceKm)km effective"
            + " (base=\(basePrediction), fitness=\(fitnessAdjustment),"
            + " terrain=\(terrainAdjustment), cal=\(calibrationFactor))"
        logger.debug("\(debugMessage, privacy: .public)")

        return max(0, calibrated)
    }

    // MARK: - Component Calculations

    /// Returns a multiplier based on experience level.
    /// Beginners tend to slow down more over ultra distances; elites pace better.
    private func experienceMultiplier(for level: ExperienceLevel) -> Double {
        switch level {
        case .beginner: return 1.15
        case .intermediate: return 1.0
        case .advanced: return 0.92
        case .elite: return 0.85
        }
    }

    /// Computes the base predicted time from pace, distance, and experience.
    private func computeBasePrediction(
        effectiveDistanceKm: Double,
        paceSecondsPerKm: Double,
        experienceMultiplier: Double
    ) -> Double {
        effectiveDistanceKm * paceSecondsPerKm * experienceMultiplier
    }

    /// Adjusts prediction based on chronic training load (CTL) and training stress balance (TSB).
    ///
    /// - Higher CTL (fitter) = slight speed-up
    /// - Positive TSB (fresh) = slight speed-up
    /// - Negative TSB (fatigued) = slight slow-down
    private func computeFitnessAdjustment(ctl: Double, tsb: Double) -> Double {
        let ctlEffect = ctl * 0.001
        let tsbEffect: Double
        if tsb < 0 {
            // Fatigued: slow down proportional to negative TSB
            tsbEffect = abs(tsb) * 0.002
        } else {
            // Fresh: speed up proportional to positive TSB
            tsbEffect = -tsb * 0.001
        }
        return max(0.80, min(1.20, 1.0 - ctlEffect + tsbEffect))
    }

    /// Adjusts prediction for terrain difficulty and elevation density.
    ///
    /// `terrainDifficulty` of 1.0 = standard trail, higher = more technical.
    /// `elevationPerKm` in meters of D+ per kilometer of distance.
    private func computeTerrainAdjustment(
        terrainDifficulty: Double,
        elevationPerKm: Double
    ) -> Double {
        let difficultyEffect = 1.0 + (terrainDifficulty - 1.0) * 0.1
        let elevationEffect = 1.0 + max(0, elevationPerKm - 30) * 0.002
        return difficultyEffect * elevationEffect
    }
}
