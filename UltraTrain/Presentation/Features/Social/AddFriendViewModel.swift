import Foundation
import os

@Observable
@MainActor
final class AddFriendViewModel {

    // MARK: - Dependencies

    private let friendRepository: any FriendRepository
    private let profileRepository: any SocialProfileRepository

    // MARK: - State

    var searchText = ""
    var foundProfile: SocialProfile?
    var isSearching = false
    var isSending = false
    var didSend = false
    var error: String?

    // MARK: - Init

    init(
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        self.friendRepository = friendRepository
        self.profileRepository = profileRepository
    }

    // MARK: - Search

    func searchProfile() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        error = nil
        foundProfile = nil
        do {
            foundProfile = try await profileRepository.fetchProfile(byId: trimmed)
            if foundProfile == nil {
                error = "No profile found for \"\(trimmed)\"."
            }
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to search profile: \(error)")
        }
        isSearching = false
    }

    // MARK: - Send Request

    func sendRequest() async {
        guard let profile = foundProfile else { return }
        isSending = true
        error = nil
        do {
            _ = try await friendRepository.sendFriendRequest(
                toProfileId: profile.id,
                displayName: profile.displayName
            )
            didSend = true
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to send friend request: \(error)")
        }
        isSending = false
    }
}
