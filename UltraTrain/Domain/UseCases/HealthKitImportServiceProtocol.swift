import Foundation

struct HealthKitImportResult: Sendable, Equatable {
    let importedCount: Int
    let skippedCount: Int
    let matchedSessionCount: Int
}

protocol HealthKitImportServiceProtocol: Sendable {
    func importNewWorkouts(athleteId: UUID) async throws -> HealthKitImportResult
}
