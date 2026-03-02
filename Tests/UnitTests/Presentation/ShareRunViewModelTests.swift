import Foundation
import Testing
@testable import UltraTrain

@Suite("ShareRunViewModel Tests")
struct ShareRunViewModelTests {

    // MARK: - Helpers

    private func makeCompletedRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now,
            distanceKm: 15.0,
            elevationGainM: 500,
            elevationLossM: 480,
            duration: 5400,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: "Great trail run",
            pausedDuration: 60
        )
    }

    private func makeFriend(
        id: UUID = UUID(),
        status: FriendStatus = .accepted
    ) -> FriendConnection {
        FriendConnection(
            id: id,
            friendProfileId: "profile-\(id.uuidString.prefix(4))",
            friendDisplayName: "Friend",
            friendPhotoData: nil,
            status: status,
            createdDate: Date.now,
            acceptedDate: status == .accepted ? Date.now : nil
        )
    }

    private func makeProfile() -> SocialProfile {
        SocialProfile(
            id: "my-profile-id",
            displayName: "Test Runner",
            bio: nil,
            profilePhotoData: nil,
            experienceLevel: .intermediate,
            totalDistanceKm: 1000,
            totalElevationGainM: 30000,
            totalRuns: 100,
            joinedDate: Date.now,
            isPublicProfile: true
        )
    }

    @MainActor
    private func makeSUT(
        sharedRunRepo: MockSharedRunRepository = MockSharedRunRepository(),
        friendRepo: MockFriendRepository = MockFriendRepository(),
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository()
    ) -> (ShareRunViewModel, MockSharedRunRepository, MockFriendRepository, MockSocialProfileRepository) {
        let run = makeCompletedRun()
        let vm = ShareRunViewModel(
            completedRun: run,
            sharedRunRepository: sharedRunRepo,
            friendRepository: friendRepo,
            profileRepository: profileRepo
        )
        return (vm, sharedRunRepo, friendRepo, profileRepo)
    }

    // MARK: - Tests

    @Test("loadFriends filters only accepted friends")
    @MainActor
    func loadFriendsFiltersAccepted() async {
        let friendRepo = MockFriendRepository()
        let accepted = makeFriend(status: .accepted)
        let pending = makeFriend(status: .pending)
        friendRepo.friends = [accepted, pending]
        let (vm, _, _, _) = makeSUT(friendRepo: friendRepo)

        await vm.loadFriends()

        #expect(vm.friends.count == 1)
        #expect(vm.friends.first?.status == .accepted)
        #expect(vm.isLoading == false)
    }

    @Test("toggleFriend adds and removes from selection")
    @MainActor
    func toggleFriendSelection() {
        let (vm, _, _, _) = makeSUT()
        let friendId = "friend-1"

        vm.toggleFriend(friendId)
        #expect(vm.selectedFriendIds.contains(friendId))

        vm.toggleFriend(friendId)
        #expect(!vm.selectedFriendIds.contains(friendId))
    }

    @Test("share does nothing when no friends selected")
    @MainActor
    func shareWithNoSelection() async {
        let (vm, sharedRepo, _, _) = makeSUT()

        await vm.share()

        #expect(sharedRepo.lastShared == nil)
        #expect(vm.didShare == false)
    }

    @Test("share creates shared run with selected friends")
    @MainActor
    func shareCreatesSharedRun() async {
        let sharedRepo = MockSharedRunRepository()
        let profileRepo = MockSocialProfileRepository()
        profileRepo.myProfile = makeProfile()
        let (vm, _, _, _) = makeSUT(sharedRunRepo: sharedRepo, profileRepo: profileRepo)

        vm.selectedFriendIds = ["friend-1", "friend-2"]
        await vm.share()

        #expect(vm.didShare == true)
        #expect(sharedRepo.lastShared != nil)
        #expect(sharedRepo.lastSharedFriendIds.count == 2)
        #expect(vm.isSharing == false)
        #expect(vm.error == nil)
    }

    @Test("share sets error on failure")
    @MainActor
    func shareSetsError() async {
        let failingProfileRepo = MockSocialProfileRepository()
        // Profile returns nil, but we still proceed; test actual failure by using failing shared repo
        let failingSharedRepo = FailingSharedRunRepository()
        let run = makeCompletedRun()
        let vm = ShareRunViewModel(
            completedRun: run,
            sharedRunRepository: failingSharedRepo,
            friendRepository: MockFriendRepository(),
            profileRepository: failingProfileRepo
        )
        vm.selectedFriendIds = ["friend-1"]

        await vm.share()

        #expect(vm.error != nil)
        #expect(vm.didShare == false)
        #expect(vm.isSharing == false)
    }

    @Test("loadFriends sets error when repository throws")
    @MainActor
    func loadFriendsError() async {
        let failingFriendRepo = FailingFriendRepoForShare()
        let run = makeCompletedRun()
        let vm = ShareRunViewModel(
            completedRun: run,
            sharedRunRepository: MockSharedRunRepository(),
            friendRepository: failingFriendRepo,
            profileRepository: MockSocialProfileRepository()
        )

        await vm.loadFriends()

        #expect(vm.error != nil)
        #expect(vm.friends.isEmpty)
        #expect(vm.isLoading == false)
    }
}

// MARK: - Test Doubles

private final class FailingSharedRunRepository: SharedRunRepository, @unchecked Sendable {
    func fetchSharedRuns() async throws -> [SharedRun] { [] }
    func shareRun(_ run: SharedRun, withFriendIds friendIds: [String]) async throws {
        throw DomainError.networkUnavailable
    }
    func revokeShare(_ runId: UUID) async throws {}
    func fetchRunsSharedByMe() async throws -> [SharedRun] { [] }
}

private final class FailingFriendRepoForShare: FriendRepository, @unchecked Sendable {
    func fetchFriends() async throws -> [FriendConnection] { throw DomainError.networkUnavailable }
    func fetchPendingRequests() async throws -> [FriendConnection] { throw DomainError.networkUnavailable }
    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        throw DomainError.networkUnavailable
    }
    func acceptFriendRequest(_ connectionId: UUID) async throws {}
    func declineFriendRequest(_ connectionId: UUID) async throws {}
    func removeFriend(_ connectionId: UUID) async throws {}
}
