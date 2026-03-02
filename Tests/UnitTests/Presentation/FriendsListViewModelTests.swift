import Foundation
import Testing
@testable import UltraTrain

@Suite("FriendsListViewModel Tests")
struct FriendsListViewModelTests {

    // MARK: - Helpers

    private func makeFriend(
        id: UUID = UUID(),
        status: FriendStatus = .accepted,
        displayName: String = "Friend"
    ) -> FriendConnection {
        FriendConnection(
            id: id,
            friendProfileId: "profile-\(id.uuidString.prefix(4))",
            friendDisplayName: displayName,
            friendPhotoData: nil,
            status: status,
            createdDate: Date.now,
            acceptedDate: status == .accepted ? Date.now : nil
        )
    }

    @MainActor
    private func makeSUT(
        friendRepo: MockFriendRepository = MockFriendRepository(),
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository()
    ) -> (FriendsListViewModel, MockFriendRepository) {
        let vm = FriendsListViewModel(
            friendRepository: friendRepo,
            profileRepository: profileRepo
        )
        return (vm, friendRepo)
    }

    // MARK: - Tests

    @Test("Load populates friends and pending requests")
    @MainActor
    func loadPopulatesBothLists() async {
        let friendRepo = MockFriendRepository()
        friendRepo.friends = [makeFriend(displayName: "Alice"), makeFriend(displayName: "Bob")]
        friendRepo.pendingRequests = [makeFriend(status: .pending, displayName: "Charlie")]
        let (vm, _) = makeSUT(friendRepo: friendRepo)

        await vm.load()

        #expect(vm.friends.count == 2)
        #expect(vm.pendingRequests.count == 1)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load sets error when repository throws")
    @MainActor
    func loadSetsError() async {
        let friendRepo = FailingFriendRepository()
        let vm = FriendsListViewModel(
            friendRepository: friendRepo,
            profileRepository: MockSocialProfileRepository()
        )

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("acceptRequest calls repository and reloads")
    @MainActor
    func acceptRequestCallsRepo() async {
        let friendRepo = MockFriendRepository()
        let connectionId = UUID()
        friendRepo.pendingRequests = [makeFriend(id: connectionId, status: .pending)]
        let (vm, repo) = makeSUT(friendRepo: friendRepo)

        await vm.acceptRequest(connectionId)

        #expect(repo.acceptedId == connectionId)
    }

    @Test("declineRequest calls repository and reloads")
    @MainActor
    func declineRequestCallsRepo() async {
        let friendRepo = MockFriendRepository()
        let connectionId = UUID()
        friendRepo.pendingRequests = [makeFriend(id: connectionId, status: .pending)]
        let (vm, repo) = makeSUT(friendRepo: friendRepo)

        await vm.declineRequest(connectionId)

        #expect(repo.declinedId == connectionId)
    }

    @Test("removeFriend removes from local list on success")
    @MainActor
    func removeFriendRemovesLocally() async {
        let friendRepo = MockFriendRepository()
        let friendId = UUID()
        friendRepo.friends = [makeFriend(id: friendId)]
        let (vm, repo) = makeSUT(friendRepo: friendRepo)
        await vm.load()

        #expect(vm.friends.count == 1)

        await vm.removeFriend(friendId)

        #expect(vm.friends.isEmpty)
        #expect(repo.removedId == friendId)
        #expect(vm.error == nil)
    }

    @Test("removeFriend sets error on failure")
    @MainActor
    func removeFriendSetsError() async {
        let friendRepo = FailingFriendRepository()
        let vm = FriendsListViewModel(
            friendRepository: friendRepo,
            profileRepository: MockSocialProfileRepository()
        )
        vm.friends = [makeFriend()]

        await vm.removeFriend(UUID())

        #expect(vm.error != nil)
    }
}

// MARK: - Test Double

private final class FailingFriendRepository: FriendRepository, @unchecked Sendable {
    func fetchFriends() async throws -> [FriendConnection] { throw DomainError.networkUnavailable }
    func fetchPendingRequests() async throws -> [FriendConnection] { throw DomainError.networkUnavailable }
    func sendFriendRequest(toProfileId: String, displayName: String) async throws -> FriendConnection {
        throw DomainError.networkUnavailable
    }
    func acceptFriendRequest(_ connectionId: UUID) async throws { throw DomainError.networkUnavailable }
    func declineFriendRequest(_ connectionId: UUID) async throws { throw DomainError.networkUnavailable }
    func removeFriend(_ connectionId: UUID) async throws { throw DomainError.networkUnavailable }
}
