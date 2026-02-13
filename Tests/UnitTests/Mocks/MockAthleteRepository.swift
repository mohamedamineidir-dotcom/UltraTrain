import Foundation
@testable import UltraTrain

final class MockAthleteRepository: AthleteRepository, @unchecked Sendable {
    var savedAthlete: Athlete?
    var shouldThrow = false

    func getAthlete() async throws -> Athlete? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return savedAthlete
    }

    func saveAthlete(_ athlete: Athlete) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedAthlete = athlete
    }

    func updateAthlete(_ athlete: Athlete) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedAthlete = athlete
    }
}
