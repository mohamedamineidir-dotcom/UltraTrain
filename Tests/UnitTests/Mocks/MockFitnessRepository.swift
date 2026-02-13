import Foundation
@testable import UltraTrain

final class MockFitnessRepository: FitnessRepository, @unchecked Sendable {
    var snapshots: [FitnessSnapshot] = []
    var savedSnapshot: FitnessSnapshot?
    var shouldThrow = false

    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [FitnessSnapshot] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return snapshots.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func getLatestSnapshot() async throws -> FitnessSnapshot? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return snapshots.sorted(by: { $0.date > $1.date }).first
    }

    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedSnapshot = snapshot
        snapshots.append(snapshot)
    }
}
