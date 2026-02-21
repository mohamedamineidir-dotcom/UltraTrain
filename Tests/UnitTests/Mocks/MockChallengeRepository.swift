import Foundation
@testable import UltraTrain

final class MockChallengeRepository: ChallengeRepository, @unchecked Sendable {
    var enrollments: [ChallengeEnrollment] = []
    var saveCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var shouldThrow = false

    func getEnrollments() async throws -> [ChallengeEnrollment] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return enrollments
    }

    func getActiveEnrollments() async throws -> [ChallengeEnrollment] {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return enrollments.filter { $0.status == .active }
    }

    func saveEnrollment(_ enrollment: ChallengeEnrollment) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        saveCallCount += 1
        enrollments.append(enrollment)
    }

    func updateEnrollment(_ enrollment: ChallengeEnrollment) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        updateCallCount += 1
        if let index = enrollments.firstIndex(where: { $0.id == enrollment.id }) {
            enrollments[index] = enrollment
        }
    }

    func deleteEnrollment(id: UUID) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        deleteCallCount += 1
        enrollments.removeAll { $0.id == id }
    }
}
