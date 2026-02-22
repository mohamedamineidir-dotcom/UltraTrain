import Foundation
@testable import UltraTrain

final class MockRaceReflectionRepository: RaceReflectionRepository, @unchecked Sendable {
    var reflections: [UUID: RaceReflection] = [:]
    var shouldThrow = false

    func getReflection(for raceId: UUID) async throws -> RaceReflection? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return reflections[raceId]
    }

    func saveReflection(_ reflection: RaceReflection) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        reflections[reflection.raceId] = reflection
    }
}
