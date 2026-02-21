import Foundation

protocol FinishTimePredictionServiceProtocol: Sendable {
    func predict(
        effectiveDistanceKm: Double,
        experienceLevel: ExperienceLevel,
        recentAvgPaceSecondsPerKm: Double,
        ctl: Double,
        tsb: Double,
        terrainDifficulty: Double,
        elevationPerKm: Double,
        calibrationFactor: Double
    ) async throws -> Double  // predicted time in seconds
}
