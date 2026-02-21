import Foundation
import os

@Observable
@MainActor
final class GroupChallengesViewModel {

    // MARK: - Dependencies

    private let challengeRepository: any GroupChallengeRepository
    private let profileRepository: any SocialProfileRepository

    // MARK: - State

    var activeChallenges: [GroupChallenge] = []
    var completedChallenges: [GroupChallenge] = []
    var isLoading = false
    var error: String?
    var showingCreateSheet = false

    // MARK: - Init

    init(
        challengeRepository: any GroupChallengeRepository,
        profileRepository: any SocialProfileRepository
    ) {
        self.challengeRepository = challengeRepository
        self.profileRepository = profileRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil
        do {
            async let active = challengeRepository.fetchActiveChallenges()
            async let completed = challengeRepository.fetchCompletedChallenges()
            activeChallenges = try await active
            completedChallenges = try await completed
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load group challenges: \(error)")
        }
        isLoading = false
    }

    // MARK: - Join

    func joinChallenge(id: UUID) async {
        error = nil
        do {
            try await challengeRepository.joinChallenge(id)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to join challenge: \(error)")
        }
    }

    // MARK: - Leave

    func leaveChallenge(id: UUID) async {
        error = nil
        do {
            try await challengeRepository.leaveChallenge(id)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to leave challenge: \(error)")
        }
    }
}
