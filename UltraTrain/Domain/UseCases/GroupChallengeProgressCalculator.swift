import Foundation

enum GroupChallengeProgressCalculator {

    struct RankedParticipant: Equatable, Sendable {
        let participant: GroupChallengeParticipant
        let progressPercent: Double
        let rank: Int
    }

    // MARK: - Leaderboard

    static func leaderboard(for challenge: GroupChallenge) -> [RankedParticipant] {
        let target = max(challenge.targetValue, 1)
        let sorted = challenge.participants.sorted { $0.currentValue > $1.currentValue }

        return sorted.enumerated().map { index, participant in
            let progress = min(1.0, participant.currentValue / target)
            return RankedParticipant(
                participant: participant,
                progressPercent: progress,
                rank: index + 1
            )
        }
    }

    // MARK: - Leader Progress

    static func leaderProgress(for challenge: GroupChallenge) -> Double {
        let target = max(challenge.targetValue, 1)
        guard let leader = challenge.participants.max(by: { $0.currentValue < $1.currentValue }) else {
            return 0
        }
        return min(1.0, leader.currentValue / target)
    }
}
