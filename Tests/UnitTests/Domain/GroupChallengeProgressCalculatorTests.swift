import Foundation
import Testing
@testable import UltraTrain

@Suite("GroupChallengeProgressCalculator Tests")
struct GroupChallengeProgressCalculatorTests {

    // MARK: - Helpers

    private func makeParticipant(
        id: String = UUID().uuidString,
        name: String = "Runner",
        value: Double = 0
    ) -> GroupChallengeParticipant {
        GroupChallengeParticipant(
            id: id,
            displayName: name,
            photoData: nil,
            currentValue: value,
            joinedDate: Date()
        )
    }

    private func makeChallenge(
        target: Double = 100,
        participants: [GroupChallengeParticipant] = []
    ) -> GroupChallenge {
        GroupChallenge(
            id: UUID(),
            creatorProfileId: "creator",
            creatorDisplayName: "Creator",
            name: "Test Challenge",
            descriptionText: "Run far",
            type: .distance,
            targetValue: target,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30),
            status: .active,
            participants: participants
        )
    }

    // MARK: - Leaderboard

    @Test("leaderboard ranks participants by descending value")
    func leaderboardRanksByValue() {
        let challenge = makeChallenge(target: 100, participants: [
            makeParticipant(name: "Alice", value: 30),
            makeParticipant(name: "Bob", value: 80),
            makeParticipant(name: "Charlie", value: 50)
        ])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board.count == 3)
        #expect(board[0].participant.displayName == "Bob")
        #expect(board[1].participant.displayName == "Charlie")
        #expect(board[2].participant.displayName == "Alice")
    }

    @Test("leaderboard assigns sequential ranks starting at 1")
    func leaderboardAssignsRanks() {
        let challenge = makeChallenge(target: 100, participants: [
            makeParticipant(value: 10),
            makeParticipant(value: 50),
            makeParticipant(value: 30)
        ])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board[0].rank == 1)
        #expect(board[1].rank == 2)
        #expect(board[2].rank == 3)
    }

    @Test("leaderboard calculates progress percent correctly")
    func leaderboardCalculatesProgress() {
        let challenge = makeChallenge(target: 200, participants: [
            makeParticipant(value: 100),
            makeParticipant(value: 50)
        ])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board[0].progressPercent == 0.5)
        #expect(board[1].progressPercent == 0.25)
    }

    @Test("leaderboard caps progress at 1.0")
    func leaderboardCapsProgressAtOne() {
        let challenge = makeChallenge(target: 50, participants: [
            makeParticipant(value: 100)
        ])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board[0].progressPercent == 1.0)
    }

    @Test("leaderboard handles empty participants")
    func leaderboardHandlesEmpty() {
        let challenge = makeChallenge(target: 100, participants: [])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board.isEmpty)
    }

    @Test("leaderboard handles zero target by using 1 as minimum")
    func leaderboardHandlesZeroTarget() {
        let challenge = makeChallenge(target: 0, participants: [
            makeParticipant(value: 5)
        ])

        let board = GroupChallengeProgressCalculator.leaderboard(for: challenge)

        #expect(board[0].progressPercent == 1.0)
    }

    // MARK: - Leader Progress

    @Test("leaderProgress returns leader's progress")
    func leaderProgressReturnsCorrectValue() {
        let challenge = makeChallenge(target: 100, participants: [
            makeParticipant(value: 30),
            makeParticipant(value: 75),
            makeParticipant(value: 50)
        ])

        let progress = GroupChallengeProgressCalculator.leaderProgress(for: challenge)

        #expect(progress == 0.75)
    }

    @Test("leaderProgress caps at 1.0")
    func leaderProgressCapsAtOne() {
        let challenge = makeChallenge(target: 50, participants: [
            makeParticipant(value: 200)
        ])

        let progress = GroupChallengeProgressCalculator.leaderProgress(for: challenge)

        #expect(progress == 1.0)
    }

    @Test("leaderProgress returns 0 for empty participants")
    func leaderProgressReturnsZeroForEmpty() {
        let challenge = makeChallenge(target: 100, participants: [])

        let progress = GroupChallengeProgressCalculator.leaderProgress(for: challenge)

        #expect(progress == 0)
    }

    @Test("leaderProgress handles single participant")
    func leaderProgressHandlesSingle() {
        let challenge = makeChallenge(target: 100, participants: [
            makeParticipant(value: 40)
        ])

        let progress = GroupChallengeProgressCalculator.leaderProgress(for: challenge)

        #expect(progress == 0.4)
    }
}
