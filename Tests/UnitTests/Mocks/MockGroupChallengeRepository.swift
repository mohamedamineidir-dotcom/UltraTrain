import Foundation
@testable import UltraTrain

final class MockGroupChallengeRepository: GroupChallengeRepository, @unchecked Sendable {
    var activeChallenges: [GroupChallenge] = []
    var completedChallenges: [GroupChallenge] = []
    var createdChallenge: GroupChallenge?
    var joinedId: UUID?
    var leftId: UUID?
    var updatedProgressId: UUID?
    var updatedProgressValue: Double?

    func fetchActiveChallenges() async throws -> [GroupChallenge] { activeChallenges }
    func fetchCompletedChallenges() async throws -> [GroupChallenge] { completedChallenges }

    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge {
        createdChallenge = challenge
        return challenge
    }

    func joinChallenge(_ challengeId: UUID) async throws { joinedId = challengeId }
    func leaveChallenge(_ challengeId: UUID) async throws { leftId = challengeId }

    func updateProgress(challengeId: UUID, value: Double) async throws {
        updatedProgressId = challengeId
        updatedProgressValue = value
    }
}
