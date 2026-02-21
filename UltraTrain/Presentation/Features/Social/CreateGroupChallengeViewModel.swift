import Foundation
import os

@Observable
@MainActor
final class CreateGroupChallengeViewModel {

    // MARK: - Dependencies

    private let challengeRepository: any GroupChallengeRepository
    private let profileRepository: any SocialProfileRepository
    private let friendRepository: any FriendRepository

    // MARK: - State

    var name = ""
    var descriptionText = ""
    var challengeType: ChallengeType = .distance
    var targetValue: String = ""
    var startDate = Date.now
    var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date.now) ?? Date.now
    var friends: [FriendConnection] = []
    var selectedFriendIds: Set<String> = []
    var isCreating = false
    var error: String?
    var didCreate = false

    // MARK: - Init

    init(
        challengeRepository: any GroupChallengeRepository,
        profileRepository: any SocialProfileRepository,
        friendRepository: any FriendRepository
    ) {
        self.challengeRepository = challengeRepository
        self.profileRepository = profileRepository
        self.friendRepository = friendRepository
    }

    // MARK: - Computed

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(targetValue) ?? 0) > 0
            && endDate > startDate
    }

    // MARK: - Load Friends

    func loadFriends() async {
        do {
            let allFriends = try await friendRepository.fetchFriends()
            friends = allFriends.filter { $0.status == .accepted }
        } catch {
            Logger.social.error("Failed to load friends for challenge creation: \(error)")
        }
    }

    // MARK: - Toggle Friend Selection

    func toggleFriend(_ friendId: String) {
        if selectedFriendIds.contains(friendId) {
            selectedFriendIds.remove(friendId)
        } else {
            selectedFriendIds.insert(friendId)
        }
    }

    // MARK: - Create Challenge

    func createChallenge() async {
        guard isValid else { return }
        isCreating = true
        error = nil
        do {
            let profile = try await profileRepository.fetchMyProfile()
            let challenge = GroupChallenge(
                id: UUID(),
                creatorProfileId: profile?.id ?? "",
                creatorDisplayName: profile?.displayName ?? "Unknown",
                name: name.trimmingCharacters(in: .whitespaces),
                descriptionText: descriptionText.trimmingCharacters(in: .whitespaces),
                type: challengeType,
                targetValue: Double(targetValue) ?? 0,
                startDate: startDate,
                endDate: endDate,
                status: .active,
                participants: []
            )
            _ = try await challengeRepository.createChallenge(challenge)
            didCreate = true
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to create group challenge: \(error)")
        }
        isCreating = false
    }
}
