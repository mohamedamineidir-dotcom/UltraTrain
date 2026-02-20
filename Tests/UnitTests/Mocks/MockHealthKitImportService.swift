import Foundation
@testable import UltraTrain

final class MockHealthKitImportService: HealthKitImportServiceProtocol, @unchecked Sendable {
    var shouldThrow = false
    var result = HealthKitImportResult(importedCount: 0, skippedCount: 0, matchedSessionCount: 0)
    var importCalled = false
    var importAthleteId: UUID?

    func importNewWorkouts(athleteId: UUID) async throws -> HealthKitImportResult {
        importCalled = true
        importAthleteId = athleteId
        if shouldThrow { throw DomainError.healthKitUnavailable }
        return result
    }
}
