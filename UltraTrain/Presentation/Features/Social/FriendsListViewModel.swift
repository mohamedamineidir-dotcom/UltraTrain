import Foundation
import os

@Observable
@MainActor
final class FriendsListViewModel {

    // MARK: - Dependencies

    private let friendRepository: any FriendRepository
    private let profileRepository: any SocialProfileRepository

    // MARK: - State

    var friends: [FriendConnection] = []
    var pendingRequests: [FriendConnection] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        self.friendRepository = friendRepository
        self.profileRepository = profileRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil
        do {
            async let fetchedFriends = friendRepository.fetchFriends()
            async let fetchedPending = friendRepository.fetchPendingRequests()
            friends = try await fetchedFriends
            pendingRequests = try await fetchedPending
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load friends: \(error)")
        }
        isLoading = false
    }

    // MARK: - Actions

    func acceptRequest(_ connectionId: UUID) async {
        error = nil
        do {
            try await friendRepository.acceptFriendRequest(connectionId)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to accept friend request: \(error)")
        }
    }

    func declineRequest(_ connectionId: UUID) async {
        error = nil
        do {
            try await friendRepository.declineFriendRequest(connectionId)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to decline friend request: \(error)")
        }
    }

    func removeFriend(_ connectionId: UUID) async {
        error = nil
        do {
            try await friendRepository.removeFriend(connectionId)
            friends.removeAll { $0.id == connectionId }
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to remove friend: \(error)")
        }
    }
}
