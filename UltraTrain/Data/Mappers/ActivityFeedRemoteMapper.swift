import Foundation

enum ActivityFeedRemoteMapper {
    static func toDomain(_ dto: ActivityFeedItemResponseDTO) -> ActivityFeedItem? {
        guard let id = UUID(uuidString: dto.id),
              let activityType = FeedActivityType(rawValue: dto.activityType) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        guard let timestamp = formatter.date(from: dto.timestamp) else {
            return nil
        }

        let stats: ActivityStats? = {
            if dto.distanceKm != nil || dto.elevationGainM != nil
                || dto.duration != nil || dto.averagePace != nil {
                return ActivityStats(
                    distanceKm: dto.distanceKm,
                    elevationGainM: dto.elevationGainM,
                    duration: dto.duration,
                    averagePace: dto.averagePace
                )
            }
            return nil
        }()

        return ActivityFeedItem(
            id: id,
            athleteProfileId: dto.athleteProfileId,
            athleteDisplayName: dto.athleteDisplayName,
            athletePhotoData: nil,
            activityType: activityType,
            title: dto.title,
            subtitle: dto.subtitle,
            stats: stats,
            timestamp: timestamp,
            likeCount: dto.likeCount,
            isLikedByMe: dto.isLikedByMe
        )
    }

    static func toDTO(_ item: ActivityFeedItem) -> PublishActivityRequestDTO {
        let formatter = ISO8601DateFormatter()
        return PublishActivityRequestDTO(
            activityType: item.activityType.rawValue,
            title: item.title,
            subtitle: item.subtitle,
            distanceKm: item.stats?.distanceKm,
            elevationGainM: item.stats?.elevationGainM,
            duration: item.stats?.duration,
            averagePace: item.stats?.averagePace,
            timestamp: formatter.string(from: item.timestamp),
            idempotencyKey: UUID().uuidString
        )
    }
}
