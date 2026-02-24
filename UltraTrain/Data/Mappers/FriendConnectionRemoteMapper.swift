import Foundation

enum FriendConnectionRemoteMapper {
    static func toDomain(_ dto: FriendConnectionResponseDTO) -> FriendConnection? {
        guard let id = UUID(uuidString: dto.id),
              let status = FriendStatus(rawValue: dto.status) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let createdDate = formatter.date(from: dto.createdDate) else {
            return nil
        }

        let acceptedDate = dto.acceptedDate.flatMap { formatter.date(from: $0) }

        return FriendConnection(
            id: id,
            friendProfileId: dto.friendProfileId,
            friendDisplayName: InputValidator.sanitizeName(dto.friendDisplayName),
            friendPhotoData: nil,
            status: status,
            createdDate: createdDate,
            acceptedDate: acceptedDate
        )
    }

    static func toRequestDTO(profileId: String) -> FriendRequestRequestDTO {
        FriendRequestRequestDTO(
            recipientProfileId: profileId,
            idempotencyKey: UUID().uuidString
        )
    }
}
