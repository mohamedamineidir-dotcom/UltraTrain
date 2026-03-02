import Foundation
import Testing
@testable import UltraTrain

@Suite("FinishTimeMLService Tests")
struct FinishTimeMLServiceTests {

    // NOTE: The CoreML model may not be available in the test environment.
    // FinishTimeMLService gracefully falls back to regression when the model is unavailable.
    // We test the regression fallback logic, input validation, and component calculations.

    // MARK: - Input Validation

    @Test("predict returns 0 for zero effective distance")
    func predictReturnsZeroForZeroDistance() async throws {
        let service = FinishTimeMLService()
        let result = try await service.predict(
            effectiveDistanceKm: 0,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        #expect(result == 0)
    }

    @Test("predict returns 0 for zero pace")
    func predictReturnsZeroForZeroPace() async throws {
        let service = FinishTimeMLService()
        let result = try await service.predict(
            effectiveDistanceKm: 100,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 0,
            ctl: 50,
            tsb: 5,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        #expect(result == 0)
    }

    @Test("predict returns 0 for negative distance")
    func predictReturnsZeroForNegativeDistance() async throws {
        let service = FinishTimeMLService()
        let result = try await service.predict(
            effectiveDistanceKm: -10,
            experienceLevel: .advanced,
            recentAvgPaceSecondsPerKm: 300,
            ctl: 80,
            tsb: 10,
            terrainDifficulty: 1.0,
            elevationPerKm: 20,
            calibrationFactor: 1.0
        )
        #expect(result == 0)
    }

    // MARK: - Regression Fallback

    @Test("regression fallback produces positive result for valid inputs")
    func regressionFallbackProducesPositiveResult() async throws {
        let service = FinishTimeMLService()
        let result = try await service.predict(
            effectiveDistanceKm: 50,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        #expect(result > 0)
    }

    @Test("beginner experience level predicts slower than elite for same inputs")
    func beginnerSlowerThanElite() async throws {
        let service = FinishTimeMLService()
        let beginnerTime = try await service.predict(
            effectiveDistanceKm: 100,
            experienceLevel: .beginner,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        let eliteTime = try await service.predict(
            effectiveDistanceKm: 100,
            experienceLevel: .elite,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        #expect(beginnerTime > eliteTime)
    }

    @Test("higher terrain difficulty produces longer predicted time")
    func higherTerrainDifficultySlower() async throws {
        let service = FinishTimeMLService()
        let easyTerrain = try await service.predict(
            effectiveDistanceKm: 80,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        let hardTerrain = try await service.predict(
            effectiveDistanceKm: 80,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 3.0,
            elevationPerKm: 80,
            calibrationFactor: 1.0
        )
        #expect(hardTerrain > easyTerrain)
    }

    @Test("different calibration factor produces different predicted time")
    func calibrationFactorAffectsResult() async throws {
        let service = FinishTimeMLService()
        let baseTime = try await service.predict(
            effectiveDistanceKm: 50,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.0
        )
        let scaledTime = try await service.predict(
            effectiveDistanceKm: 50,
            experienceLevel: .intermediate,
            recentAvgPaceSecondsPerKm: 360,
            ctl: 50,
            tsb: 0,
            terrainDifficulty: 1.0,
            elevationPerKm: 30,
            calibrationFactor: 1.5
        )
        // Changing calibration factor should produce a different (nonzero) result
        // (direction depends on whether CoreML model or regression fallback is used)
        #expect(baseTime > 0)
        #expect(scaledTime > 0)
        #expect(baseTime != scaledTime)
    }

    @Test("result is never negative even with extreme negative TSB")
    func resultNeverNegative() async throws {
        let service = FinishTimeMLService()
        let result = try await service.predict(
            effectiveDistanceKm: 10,
            experienceLevel: .elite,
            recentAvgPaceSecondsPerKm: 300,
            ctl: 200,
            tsb: -50,
            terrainDifficulty: 1.0,
            elevationPerKm: 10,
            calibrationFactor: 0.5
        )
        #expect(result >= 0)
    }
}
