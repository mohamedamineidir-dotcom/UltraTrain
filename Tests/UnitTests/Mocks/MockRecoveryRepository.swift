import Foundation
@testable import UltraTrain

final class MockRecoveryRepository: RecoveryRepository, @unchecked Sendable {
    var snapshots: [RecoverySnapshot] = []
    var shouldThrow = false
    var saveSnapshotCalled = false
    var savedSnapshot: RecoverySnapshot?

    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [RecoverySnapshot] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return snapshots.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func getLatestSnapshot() async throws -> RecoverySnapshot? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return snapshots.sorted(by: { $0.date > $1.date }).first
    }

    func saveSnapshot(_ snapshot: RecoverySnapshot) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        saveSnapshotCalled = true
        savedSnapshot = snapshot
        snapshots.append(snapshot)
    }
}
