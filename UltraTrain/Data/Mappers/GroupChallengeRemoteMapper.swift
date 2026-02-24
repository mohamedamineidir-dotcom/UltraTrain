import Foundation

enum GroupChallengeRemoteMapper {
    static func toDomain(_ dto: GroupChallengeResponseDTO) -> GroupChallenge? {
        guard let id = UUID(uuidString: dto.id),
              let type = ChallengeType(rawValue: dto.type),
              let status = GroupChallengeStatus(rawValue: dto.status) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: dto.startDate),
              let endDate = formatter.date(from: dto.endDate) else {
            return nil
        }

        let participants = dto.participants.compactMap { participantDTO -> GroupChallengeParticipant? in
            guard let joinedDate = formatter.date(from: participantDTO.joinedDate) else {
                return nil
            }
            return GroupChallengeParticipant(
                id: participantDTO.id,
                displayName: participantDTO.displayName,
                photoData: nil,
                currentValue: participantDTO.currentValue,
                joinedDate: joinedDate
            )
        }

        return GroupChallenge(
            id: id,
            creatorProfileId: dto.creatorProfileId,
            creatorDisplayName: dto.creatorDisplayName,
            name: dto.name,
            descriptionText: dto.descriptionText,
            type: type,
            targetValue: dto.targetValue,
            startDate: startDate,
            endDate: endDate,
            status: status,
            participants: participants
        )
    }

    static func toCreateDTO(_ challenge: GroupChallenge) -> CreateChallengeRequestDTO {
        let formatter = ISO8601DateFormatter()
        return CreateChallengeRequestDTO(
            name: challenge.name,
            descriptionText: challenge.descriptionText,
            type: challenge.type.rawValue,
            targetValue: challenge.targetValue,
            startDate: formatter.string(from: challenge.startDate),
            endDate: formatter.string(from: challenge.endDate),
            idempotencyKey: UUID().uuidString
        )
    }
}
