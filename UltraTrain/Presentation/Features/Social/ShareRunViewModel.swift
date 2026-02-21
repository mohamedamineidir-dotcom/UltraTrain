import Foundation
import os

@Observable
@MainActor
final class ShareRunViewModel {

    // MARK: - Dependencies

    private let sharedRunRepository: any SharedRunRepository
    private let friendRepository: any FriendRepository
    private let profileRepository: any SocialProfileRepository

    // MARK: - State

    let completedRun: CompletedRun
    var friends: [FriendConnection] = []
    var selectedFriendIds: Set<String> = []
    var isLoading = false
    var isSharing = false
    var error: String?
    var didShare = false

    // MARK: - Init

    init(
        completedRun: CompletedRun,
        sharedRunRepository: any SharedRunRepository,
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        self.completedRun = completedRun
        self.sharedRunRepository = sharedRunRepository
        self.friendRepository = friendRepository
        self.profileRepository = profileRepository
    }

    // MARK: - Load

    func loadFriends() async {
        isLoading = true
        error = nil
        do {
            let allFriends = try await friendRepository.fetchFriends()
            friends = allFriends.filter { $0.status == .accepted }
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load friends for sharing: \(error)")
        }
        isLoading = false
    }

    // MARK: - Toggle Selection

    func toggleFriend(_ friendId: String) {
        if selectedFriendIds.contains(friendId) {
            selectedFriendIds.remove(friendId)
        } else {
            selectedFriendIds.insert(friendId)
        }
    }

    // MARK: - Share

    func share() async {
        guard !selectedFriendIds.isEmpty else { return }
        isSharing = true
        error = nil
        do {
            let profile = try await profileRepository.fetchMyProfile()
            let sharedRun = SharedRun(
                id: UUID(),
                sharedByProfileId: profile?.id ?? "",
                sharedByDisplayName: profile?.displayName ?? "Unknown",
                date: completedRun.date,
                distanceKm: completedRun.distanceKm,
                elevationGainM: completedRun.elevationGainM,
                elevationLossM: completedRun.elevationLossM,
                duration: completedRun.duration,
                averagePaceSecondsPerKm: completedRun.averagePaceSecondsPerKm,
                gpsTrack: completedRun.gpsTrack,
                splits: completedRun.splits,
                notes: completedRun.notes,
                sharedAt: Date.now,
                likeCount: 0,
                commentCount: 0
            )
            try await sharedRunRepository.shareRun(
                sharedRun,
                withFriendIds: Array(selectedFriendIds)
            )
            didShare = true
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to share run: \(error)")
        }
        isSharing = false
    }
}
