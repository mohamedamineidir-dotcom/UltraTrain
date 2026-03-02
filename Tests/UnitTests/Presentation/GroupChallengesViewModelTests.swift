import Foundation
import Testing
@testable import UltraTrain

@Suite("GroupChallengesViewModel Tests")
struct GroupChallengesViewModelTests {

    // MARK: - Helpers

    private func makeChallenge(
        id: UUID = UUID(),
        status: GroupChallengeStatus = .active,
        name: String = "Test Challenge"
    ) -> GroupChallenge {
        GroupChallenge(
            id: id,
            creatorProfileId: "creator-1",
            creatorDisplayName: "Creator",
            name: name,
            descriptionText: "A test challenge",
            type: .distance,
            targetValue: 100,
            startDate: Date.now,
            endDate: Date.now.addingTimeInterval(86400 * 7),
            status: status,
            participants: []
        )
    }

    @MainActor
    private func makeSUT(
        challengeRepo: MockGroupChallengeRepository = MockGroupChallengeRepository(),
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository()
    ) -> (GroupChallengesViewModel, MockGroupChallengeRepository) {
        let vm = GroupChallengesViewModel(
            challengeRepository: challengeRepo,
            profileRepository: profileRepo
        )
        return (vm, challengeRepo)
    }

    // MARK: - Tests

    @Test("Load populates active and completed challenges")
    @MainActor
    func loadPopulatesBothLists() async {
        let repo = MockGroupChallengeRepository()
        repo.activeChallenges = [makeChallenge(name: "Active"), makeChallenge(name: "Active 2")]
        repo.completedChallenges = [makeChallenge(status: .completed, name: "Done")]
        let (vm, _) = makeSUT(challengeRepo: repo)

        await vm.load()

        #expect(vm.activeChallenges.count == 2)
        #expect(vm.completedChallenges.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load sets error when repository throws")
    @MainActor
    func loadSetsError() async {
        let failingRepo = FailingGroupChallengeRepoForList()
        let vm = GroupChallengesViewModel(
            challengeRepository: failingRepo,
            profileRepository: MockSocialProfileRepository()
        )

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("joinChallenge calls repository with correct ID")
    @MainActor
    func joinChallengeCallsRepo() async {
        let repo = MockGroupChallengeRepository()
        let challengeId = UUID()
        let (vm, _) = makeSUT(challengeRepo: repo)

        await vm.joinChallenge(id: challengeId)

        #expect(repo.joinedId == challengeId)
    }

    @Test("leaveChallenge calls repository with correct ID")
    @MainActor
    func leaveChallengeCallsRepo() async {
        let repo = MockGroupChallengeRepository()
        let challengeId = UUID()
        let (vm, _) = makeSUT(challengeRepo: repo)

        await vm.leaveChallenge(id: challengeId)

        #expect(repo.leftId == challengeId)
    }

    @Test("joinChallenge sets error on failure")
    @MainActor
    func joinChallengeError() async {
        let failingRepo = FailingGroupChallengeRepoForList()
        let vm = GroupChallengesViewModel(
            challengeRepository: failingRepo,
            profileRepository: MockSocialProfileRepository()
        )

        await vm.joinChallenge(id: UUID())

        #expect(vm.error != nil)
    }

    @Test("leaveChallenge sets error on failure")
    @MainActor
    func leaveChallengeError() async {
        let failingRepo = FailingGroupChallengeRepoForList()
        let vm = GroupChallengesViewModel(
            challengeRepository: failingRepo,
            profileRepository: MockSocialProfileRepository()
        )

        await vm.leaveChallenge(id: UUID())

        #expect(vm.error != nil)
    }
}

// MARK: - Test Double

private final class FailingGroupChallengeRepoForList: GroupChallengeRepository, @unchecked Sendable {
    func fetchActiveChallenges() async throws -> [GroupChallenge] { throw DomainError.networkUnavailable }
    func fetchCompletedChallenges() async throws -> [GroupChallenge] { throw DomainError.networkUnavailable }
    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge {
        throw DomainError.networkUnavailable
    }
    func joinChallenge(_ challengeId: UUID) async throws { throw DomainError.networkUnavailable }
    func leaveChallenge(_ challengeId: UUID) async throws { throw DomainError.networkUnavailable }
    func updateProgress(challengeId: UUID, value: Double) async throws {}
}
