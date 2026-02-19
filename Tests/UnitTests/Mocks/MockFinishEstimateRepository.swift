import Foundation
@testable import UltraTrain

final class MockFinishEstimateRepository: FinishEstimateRepository, @unchecked Sendable {
    var savedEstimate: FinishEstimate?
    var estimates: [UUID: FinishEstimate] = [:]
    var shouldThrow = false

    func getEstimate(for raceId: UUID) async throws -> FinishEstimate? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return estimates[raceId]
    }

    func saveEstimate(_ estimate: FinishEstimate) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedEstimate = estimate
        estimates[estimate.raceId] = estimate
    }
}
