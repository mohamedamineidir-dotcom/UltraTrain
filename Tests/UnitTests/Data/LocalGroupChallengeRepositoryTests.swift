import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalGroupChallengeRepository Tests")
@MainActor
struct LocalGroupChallengeRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            GroupChallengeSwiftDataModel.self,
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeChallenge(
        id: UUID = UUID(),
        name: String = "Weekly 50K",
        status: GroupChallengeStatus = .active,
        endDate: Date = Date().addingTimeInterval(604800)
    ) -> GroupChallenge {
        GroupChallenge(
            id: id,
            creatorProfileId: "creator-1",
            creatorDisplayName: "Trail Runner",
            name: name,
            descriptionText: "Run 50km this week",
            type: .distance,
            targetValue: 50.0,
            startDate: Date(),
            endDate: endDate,
            status: status,
            participants: []
        )
    }

    @Test("Create and fetch active challenges")
    func createAndFetchActiveChallenges() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        _ = try await repo.createChallenge(makeChallenge(name: "Active Challenge", status: .active))

        let results = try await repo.fetchActiveChallenges()
        #expect(results.count == 1)
        #expect(results.first?.name == "Active Challenge")
    }

    @Test("Fetch completed challenges returns completed and expired")
    func fetchCompletedChallengesReturnsCompletedAndExpired() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        _ = try await repo.createChallenge(makeChallenge(name: "Active", status: .active))
        _ = try await repo.createChallenge(makeChallenge(name: "Completed", status: .completed))
        _ = try await repo.createChallenge(makeChallenge(name: "Expired", status: .expired))

        let results = try await repo.fetchCompletedChallenges()
        #expect(results.count == 2)
    }

    @Test("Join challenge throws when challenge not found")
    func joinChallengeThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.joinChallenge(UUID())
        }
    }

    @Test("Leave challenge throws when challenge not found")
    func leaveChallengeThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.leaveChallenge(UUID())
        }
    }

    @Test("Update progress throws when challenge not found")
    func updateProgressThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.updateProgress(challengeId: UUID(), value: 25.0)
        }
    }

    @Test("Create challenge returns the same challenge")
    func createChallengeReturnsSameChallenge() async throws {
        let container = try makeContainer()
        let repo = LocalGroupChallengeRepository(modelContainer: container)

        let challenge = makeChallenge(name: "Mountain Challenge")
        let returned = try await repo.createChallenge(challenge)

        #expect(returned.name == "Mountain Challenge")
        #expect(returned.id == challenge.id)
    }
}
