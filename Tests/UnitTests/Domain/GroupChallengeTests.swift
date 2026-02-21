import Foundation
import Testing
@testable import UltraTrain

@Suite("GroupChallenge Model Tests")
struct GroupChallengeTests {

    private func makeChallenge(
        type: ChallengeType = .distance,
        targetValue: Double = 100,
        endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date.now)!,
        status: GroupChallengeStatus = .active
    ) -> GroupChallenge {
        GroupChallenge(
            id: UUID(),
            creatorProfileId: "creator-1",
            creatorDisplayName: "Challenge Creator",
            name: "Weekly Distance Challenge",
            descriptionText: "Run 100km this week",
            type: type,
            targetValue: targetValue,
            startDate: Date.now,
            endDate: endDate,
            status: status,
            participants: []
        )
    }

    // MARK: - Creation

    @Test("GroupChallenge creation with all fields")
    func creationWithAllFields() {
        let challenge = makeChallenge()

        #expect(challenge.creatorProfileId == "creator-1")
        #expect(challenge.creatorDisplayName == "Challenge Creator")
        #expect(challenge.name == "Weekly Distance Challenge")
        #expect(challenge.descriptionText == "Run 100km this week")
        #expect(challenge.type == .distance)
        #expect(challenge.targetValue == 100)
        #expect(challenge.status == .active)
        #expect(challenge.participants.isEmpty)
    }

    // MARK: - Days Remaining

    @Test("daysRemaining returns positive value for future end date")
    func daysRemainingFuture() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date.now)!
        let challenge = makeChallenge(endDate: futureDate)

        #expect(challenge.daysRemaining >= 9)
        #expect(challenge.daysRemaining <= 10)
    }

    @Test("daysRemaining returns 0 for past end date")
    func daysRemainingPast() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now)!
        let challenge = makeChallenge(endDate: pastDate)

        #expect(challenge.daysRemaining == 0)
    }

    // MARK: - Unit Label

    @Test("unitLabel for distance type is km")
    func unitLabelDistance() {
        let challenge = makeChallenge(type: .distance)
        #expect(challenge.unitLabel == "km")
    }

    @Test("unitLabel for elevation type is m D+")
    func unitLabelElevation() {
        let challenge = makeChallenge(type: .elevation)
        #expect(challenge.unitLabel == "m D+")
    }

    @Test("unitLabel for consistency type is runs")
    func unitLabelConsistency() {
        let challenge = makeChallenge(type: .consistency)
        #expect(challenge.unitLabel == "runs")
    }

    @Test("unitLabel for streak type is days")
    func unitLabelStreak() {
        let challenge = makeChallenge(type: .streak)
        #expect(challenge.unitLabel == "days")
    }

    // MARK: - Participant

    @Test("GroupChallengeParticipant creation")
    func participantCreation() {
        let participant = GroupChallengeParticipant(
            id: "participant-1",
            displayName: "Runner A",
            photoData: nil,
            currentValue: 42.5,
            joinedDate: Date.now
        )

        #expect(participant.id == "participant-1")
        #expect(participant.displayName == "Runner A")
        #expect(participant.photoData == nil)
        #expect(participant.currentValue == 42.5)
    }
}
