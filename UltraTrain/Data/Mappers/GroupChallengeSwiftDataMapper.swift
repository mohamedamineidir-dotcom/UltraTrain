import Foundation

enum GroupChallengeSwiftDataMapper {

    // MARK: - Codable Adapter

    private struct CodableParticipant: Codable {
        let id: String
        let displayName: String
        let photoData: Data?
        let currentValue: Double
        let joinedDate: Date
    }

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: GroupChallengeSwiftDataModel) -> GroupChallenge? {
        guard let type = ChallengeType(rawValue: model.typeRaw),
              let status = GroupChallengeStatus(rawValue: model.statusRaw) else {
            return nil
        }
        return GroupChallenge(
            id: model.id,
            creatorProfileId: model.creatorProfileId,
            creatorDisplayName: model.creatorDisplayName,
            name: model.name,
            descriptionText: model.descriptionText,
            type: type,
            targetValue: model.targetValue,
            startDate: model.startDate,
            endDate: model.endDate,
            status: status,
            participants: decodeParticipants(model.participantsData)
        )
    }

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ challenge: GroupChallenge) -> GroupChallengeSwiftDataModel {
        GroupChallengeSwiftDataModel(
            id: challenge.id,
            creatorProfileId: challenge.creatorProfileId,
            creatorDisplayName: challenge.creatorDisplayName,
            name: challenge.name,
            descriptionText: challenge.descriptionText,
            typeRaw: challenge.type.rawValue,
            targetValue: challenge.targetValue,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            statusRaw: challenge.status.rawValue,
            participantsData: encodeParticipants(challenge.participants)
        )
    }

    // MARK: - Participant JSON

    private static func encodeParticipants(_ participants: [GroupChallengeParticipant]) -> Data {
        let codable = participants.map { participant in
            CodableParticipant(
                id: participant.id,
                displayName: participant.displayName,
                photoData: participant.photoData,
                currentValue: participant.currentValue,
                joinedDate: participant.joinedDate
            )
        }
        return (try? JSONEncoder().encode(codable)) ?? Data()
    }

    private static func decodeParticipants(_ data: Data) -> [GroupChallengeParticipant] {
        guard let codable = try? JSONDecoder().decode([CodableParticipant].self, from: data) else {
            return []
        }
        return codable.map { participant in
            GroupChallengeParticipant(
                id: participant.id,
                displayName: participant.displayName,
                photoData: participant.photoData,
                currentValue: participant.currentValue,
                joinedDate: participant.joinedDate
            )
        }
    }
}
