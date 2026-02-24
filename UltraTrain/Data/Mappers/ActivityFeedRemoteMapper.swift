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

        let validatedStats: ActivityStats? = {
            guard let s = stats else { return nil }
            let dist = s.distanceKm.flatMap { InputValidator.isValidDistance($0) ? $0 : nil }
            let elev = s.elevationGainM.flatMap { InputValidator.isValidElevation($0) ? $0 : nil }
            let dur = s.duration.flatMap { InputValidator.isValidDuration($0) ? $0 : nil }
            let pace = s.averagePace.flatMap { InputValidator.isValidPace($0) ? $0 : nil }
            if dist == nil && elev == nil && dur == nil && pace == nil { return nil }
            return ActivityStats(distanceKm: dist, elevationGainM: elev, duration: dur, averagePace: pace)
        }()

        return ActivityFeedItem(
            id: id,
            athleteProfileId: dto.athleteProfileId,
            athleteDisplayName: InputValidator.sanitizeName(dto.athleteDisplayName),
            athletePhotoData: nil,
            activityType: activityType,
            title: InputValidator.sanitizeText(dto.title, maxLength: 200),
            subtitle: InputValidator.sanitizeOptionalText(dto.subtitle, maxLength: 500),
            stats: validatedStats,
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
