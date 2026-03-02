import Foundation
import Testing
@testable import UltraTrain

@Suite("CreateGroupChallengeViewModel Tests")
struct CreateGroupChallengeViewModelTests {

    // MARK: - Helpers

    private func makeFriend(status: FriendStatus = .accepted) -> FriendConnection {
        FriendConnection(
            id: UUID(),
            friendProfileId: "profile-\(UUID().uuidString.prefix(4))",
            friendDisplayName: "Friend",
            friendPhotoData: nil,
            status: status,
            createdDate: Date.now,
            acceptedDate: status == .accepted ? Date.now : nil
        )
    }

    private func makeProfile() -> SocialProfile {
        SocialProfile(
            id: "creator-id",
            displayName: "Challenge Creator",
            bio: nil,
            profilePhotoData: nil,
            experienceLevel: .advanced,
            totalDistanceKm: 2000,
            totalElevationGainM: 80000,
            totalRuns: 250,
            joinedDate: Date.now,
            isPublicProfile: true
        )
    }

    @MainActor
    private func makeSUT(
        challengeRepo: MockGroupChallengeRepository = MockGroupChallengeRepository(),
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository(),
        friendRepo: MockFriendRepository = MockFriendRepository()
    ) -> (CreateGroupChallengeViewModel, MockGroupChallengeRepository, MockSocialProfileRepository) {
        let vm = CreateGroupChallengeViewModel(
            challengeRepository: challengeRepo,
            profileRepository: profileRepo,
            friendRepository: friendRepo
        )
        return (vm, challengeRepo, profileRepo)
    }

    // MARK: - Tests

    @Test("isValid returns false when name is empty")
    @MainActor
    func isValidFalseWithEmptyName() {
        let (vm, _, _) = makeSUT()
        vm.name = ""
        vm.targetValue = "100"

        #expect(vm.isValid == false)
    }

    @Test("isValid returns false when name is only whitespace")
    @MainActor
    func isValidFalseWithWhitespaceName() {
        let (vm, _, _) = makeSUT()
        vm.name = "   "
        vm.targetValue = "100"

        #expect(vm.isValid == false)
    }

    @Test("isValid returns false when target value is zero or negative")
    @MainActor
    func isValidFalseWithInvalidTarget() {
        let (vm, _, _) = makeSUT()
        vm.name = "Test Challenge"
        vm.targetValue = "0"

        #expect(vm.isValid == false)

        vm.targetValue = "-5"
        #expect(vm.isValid == false)

        vm.targetValue = "abc"
        #expect(vm.isValid == false)
    }

    @Test("isValid returns false when end date is before start date")
    @MainActor
    func isValidFalseWhenEndBeforeStart() {
        let (vm, _, _) = makeSUT()
        vm.name = "Test Challenge"
        vm.targetValue = "100"
        vm.startDate = Date.now
        vm.endDate = Date.now.addingTimeInterval(-3600)

        #expect(vm.isValid == false)
    }

    @Test("isValid returns true with valid inputs")
    @MainActor
    func isValidTrueWithValidInputs() {
        let (vm, _, _) = makeSUT()
        vm.name = "Weekly Distance Challenge"
        vm.targetValue = "100"
        vm.startDate = Date.now
        vm.endDate = Date.now.addingTimeInterval(86400 * 7)

        #expect(vm.isValid == true)
    }

    @Test("loadFriends filters only accepted friends")
    @MainActor
    func loadFriendsFiltersAccepted() async {
        let friendRepo = MockFriendRepository()
        friendRepo.friends = [makeFriend(status: .accepted), makeFriend(status: .pending)]
        let (vm, _, _) = makeSUT(friendRepo: friendRepo)

        await vm.loadFriends()

        #expect(vm.friends.count == 1)
        #expect(vm.friends.first?.status == .accepted)
    }

    @Test("toggleFriend toggles selection state")
    @MainActor
    func toggleFriendSelection() {
        let (vm, _, _) = makeSUT()

        vm.toggleFriend("friend-1")
        #expect(vm.selectedFriendIds.contains("friend-1"))

        vm.toggleFriend("friend-1")
        #expect(!vm.selectedFriendIds.contains("friend-1"))
    }

    @Test("createChallenge succeeds and sets didCreate")
    @MainActor
    func createChallengeSuccess() async {
        let challengeRepo = MockGroupChallengeRepository()
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let (vm, repo, _) = makeSUT(challengeRepo: challengeRepo, profileRepo: profileRepo)

        vm.name = "100km Challenge"
        vm.descriptionText = "Run 100km this week"
        vm.targetValue = "100"
        vm.challengeType = .distance
        vm.startDate = Date.now
        vm.endDate = Date.now.addingTimeInterval(86400 * 7)

        await vm.createChallenge()

        #expect(vm.didCreate == true)
        #expect(repo.createdChallenge != nil)
        #expect(repo.createdChallenge?.name == "100km Challenge")
        #expect(vm.isCreating == false)
        #expect(vm.error == nil)
    }

    @Test("createChallenge does nothing when invalid")
    @MainActor
    func createChallengeGuardsInvalid() async {
        let (vm, repo, _) = makeSUT()
        vm.name = ""
        vm.targetValue = "100"

        await vm.createChallenge()

        #expect(repo.createdChallenge == nil)
        #expect(vm.didCreate == false)
    }

    @Test("createChallenge sets error on failure")
    @MainActor
    func createChallengeError() async {
        let failingRepo = FailingGroupChallengeRepo()
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let vm = CreateGroupChallengeViewModel(
            challengeRepository: failingRepo,
            profileRepository: profileRepo,
            friendRepository: MockFriendRepository()
        )
        vm.name = "Failing Challenge"
        vm.targetValue = "50"
        vm.startDate = Date.now
        vm.endDate = Date.now.addingTimeInterval(86400 * 7)

        await vm.createChallenge()

        #expect(vm.error != nil)
        #expect(vm.didCreate == false)
        #expect(vm.isCreating == false)
    }
}

// MARK: - Test Double

private final class FailingGroupChallengeRepo: GroupChallengeRepository, @unchecked Sendable {
    func fetchActiveChallenges() async throws -> [GroupChallenge] { [] }
    func fetchCompletedChallenges() async throws -> [GroupChallenge] { [] }
    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge {
        throw DomainError.networkUnavailable
    }
    func joinChallenge(_ challengeId: UUID) async throws {}
    func leaveChallenge(_ challengeId: UUID) async throws {}
    func updateProgress(challengeId: UUID, value: Double) async throws {}
}
