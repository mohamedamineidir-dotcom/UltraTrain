import Foundation
@testable import UltraTrain

final class MockRunRepository: RunRepository, @unchecked Sendable {
    var savedRun: CompletedRun?
    var runs: [CompletedRun] = []
    var deletedId: UUID?
    var updatedRun: CompletedRun?
    var linkedSessionUpdate: (runId: UUID, sessionId: UUID)?
    var shouldThrow = false

    func getRuns(for athleteId: UUID) async throws -> [CompletedRun] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return runs.filter { $0.athleteId == athleteId }
    }

    func getRun(id: UUID) async throws -> CompletedRun? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return runs.first { $0.id == id }
    }

    func saveRun(_ run: CompletedRun) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedRun = run
        runs.append(run)
    }

    func deleteRun(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deletedId = id
        runs.removeAll { $0.id == id }
    }

    func updateRun(_ run: CompletedRun) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updatedRun = run
        if let index = runs.firstIndex(where: { $0.id == run.id }) {
            runs[index] = run
        }
    }

    func updateLinkedSession(runId: UUID, sessionId: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        linkedSessionUpdate = (runId, sessionId)
    }

    func getRecentRuns(limit: Int) async throws -> [CompletedRun] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return Array(runs.prefix(limit))
    }
}
