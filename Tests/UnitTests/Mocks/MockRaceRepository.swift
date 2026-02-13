import Foundation
@testable import UltraTrain

final class MockRaceRepository: RaceRepository, @unchecked Sendable {
    var savedRace: Race?
    var races: [Race] = []
    var shouldThrow = false

    func getRaces() async throws -> [Race] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return races
    }

    func getRace(id: UUID) async throws -> Race? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return races.first { $0.id == id }
    }

    func saveRace(_ race: Race) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedRace = race
        races.append(race)
    }

    func updateRace(_ race: Race) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        if let index = races.firstIndex(where: { $0.id == race.id }) {
            races[index] = race
        }
        savedRace = race
    }

    func deleteRace(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        races.removeAll { $0.id == id }
    }
}
