import Foundation
@testable import UltraTrain

final class MockRacePrepChecklistRepository: RacePrepChecklistRepository, @unchecked Sendable {
    var checklists: [UUID: RacePrepChecklist] = [:]
    var shouldThrow = false
    var saveChecklistCalled = false
    var deleteChecklistCalled = false

    func getChecklist(for raceId: UUID) async throws -> RacePrepChecklist? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return checklists[raceId]
    }

    func saveChecklist(_ checklist: RacePrepChecklist) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        saveChecklistCalled = true
        checklists[checklist.raceId] = checklist
    }

    func deleteChecklist(for raceId: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deleteChecklistCalled = true
        checklists.removeValue(forKey: raceId)
    }
}
