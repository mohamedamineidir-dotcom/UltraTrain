import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalChallengeRepository Tests")
@MainActor
struct LocalChallengeRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([ChallengeEnrollmentSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeEnrollment(
        id: UUID = UUID(),
        challengeDefinitionId: String = "weekly_50k",
        startDate: Date = Date(),
        status: ChallengeStatus = .active,
        completedDate: Date? = nil
    ) -> ChallengeEnrollment {
        ChallengeEnrollment(
            id: id,
            challengeDefinitionId: challengeDefinitionId,
            startDate: startDate,
            status: status,
            completedDate: completedDate
        )
    }

    @Test("Save and get enrollments")
    func saveAndGetEnrollments() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)

        let enrollment = makeEnrollment(challengeDefinitionId: "monthly_100k")
        try await repo.saveEnrollment(enrollment)

        let results = try await repo.getEnrollments()
        #expect(results.count == 1)
        #expect(results.first?.challengeDefinitionId == "monthly_100k")
    }

    @Test("Get active enrollments filters by status")
    func getActiveEnrollmentsFiltersByStatus() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)

        let active = makeEnrollment(challengeDefinitionId: "active_one", status: .active)
        let completed = makeEnrollment(challengeDefinitionId: "completed_one", status: .completed)
        try await repo.saveEnrollment(active)
        try await repo.saveEnrollment(completed)

        let results = try await repo.getActiveEnrollments()
        #expect(results.count == 1)
        #expect(results.first?.challengeDefinitionId == "active_one")
    }

    @Test("Update enrollment modifies status")
    func updateEnrollmentModifiesStatus() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)
        let enrollmentId = UUID()

        let enrollment = makeEnrollment(id: enrollmentId, status: .active)
        try await repo.saveEnrollment(enrollment)

        var updated = enrollment
        updated.completedDate = Date()
        // We need to create a new enrollment with completed status for the update
        let completedEnrollment = ChallengeEnrollment(
            id: enrollmentId,
            challengeDefinitionId: enrollment.challengeDefinitionId,
            startDate: enrollment.startDate,
            status: .completed,
            completedDate: Date()
        )
        try await repo.updateEnrollment(completedEnrollment)

        let results = try await repo.getActiveEnrollments()
        #expect(results.isEmpty)
    }

    @Test("Update enrollment throws when not found")
    func updateEnrollmentThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)

        let enrollment = makeEnrollment()
        await #expect(throws: DomainError.self) {
            try await repo.updateEnrollment(enrollment)
        }
    }

    @Test("Delete enrollment removes it")
    func deleteEnrollmentRemovesIt() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)
        let enrollmentId = UUID()

        try await repo.saveEnrollment(makeEnrollment(id: enrollmentId))
        try await repo.deleteEnrollment(id: enrollmentId)

        let results = try await repo.getEnrollments()
        #expect(results.isEmpty)
    }

    @Test("Delete enrollment throws when not found")
    func deleteEnrollmentThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalChallengeRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.deleteEnrollment(id: UUID())
        }
    }
}
