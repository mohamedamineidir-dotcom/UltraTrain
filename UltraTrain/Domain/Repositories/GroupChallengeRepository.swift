import Foundation

protocol GroupChallengeRepository: Sendable {
    func fetchActiveChallenges() async throws -> [GroupChallenge]
    func fetchCompletedChallenges() async throws -> [GroupChallenge]
    func createChallenge(_ challenge: GroupChallenge) async throws -> GroupChallenge
    func joinChallenge(_ challengeId: UUID) async throws
    func leaveChallenge(_ challengeId: UUID) async throws
    func updateProgress(challengeId: UUID, value: Double) async throws
}
