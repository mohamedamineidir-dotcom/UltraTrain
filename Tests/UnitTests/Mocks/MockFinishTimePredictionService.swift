import Foundation
@testable import UltraTrain

final class MockFinishTimePredictionService: FinishTimePredictionServiceProtocol, @unchecked Sendable {
    var predictionResult: Double = 36000  // 10 hours default
    var shouldThrow = false

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
        if shouldThrow { throw DomainError.unknown(message: "ML failed") }
        return predictionResult
    }
}
