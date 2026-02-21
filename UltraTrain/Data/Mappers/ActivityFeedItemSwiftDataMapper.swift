import Foundation

enum ActivityFeedItemSwiftDataMapper {

    // MARK: - SwiftData -> Domain

    static func toDomain(_ model: ActivityFeedItemSwiftDataModel) -> ActivityFeedItem? {
        guard let activityType = ActivityType(rawValue: model.activityTypeRaw) else {
            return nil
        }
        let stats = mapStats(
            distanceKm: model.statsDistanceKm,
            elevationGainM: model.statsElevationGainM,
            duration: model.statsDuration,
            averagePace: model.statsAveragePace
        )
        return ActivityFeedItem(
            id: model.id,
            athleteProfileId: model.athleteProfileId,
            athleteDisplayName: model.athleteDisplayName,
            athletePhotoData: model.athletePhotoData,
            activityType: activityType,
            title: model.title,
            subtitle: model.subtitle,
            stats: stats,
            timestamp: model.timestamp,
            likeCount: model.likeCount,
            isLikedByMe: model.isLikedByMe
        )
    }

    // MARK: - Domain -> SwiftData

    static func toSwiftData(_ item: ActivityFeedItem) -> ActivityFeedItemSwiftDataModel {
        ActivityFeedItemSwiftDataModel(
            id: item.id,
            athleteProfileId: item.athleteProfileId,
            athleteDisplayName: item.athleteDisplayName,
            athletePhotoData: item.athletePhotoData,
            activityTypeRaw: item.activityType.rawValue,
            title: item.title,
            subtitle: item.subtitle,
            statsDistanceKm: item.stats?.distanceKm,
            statsElevationGainM: item.stats?.elevationGainM,
            statsDuration: item.stats?.duration,
            statsAveragePace: item.stats?.averagePace,
            timestamp: item.timestamp,
            likeCount: item.likeCount,
            isLikedByMe: item.isLikedByMe
        )
    }

    // MARK: - Stats Mapping

    private static func mapStats(
        distanceKm: Double?,
        elevationGainM: Double?,
        duration: Double?,
        averagePace: Double?
    ) -> ActivityStats? {
        if distanceKm == nil, elevationGainM == nil, duration == nil, averagePace == nil {
            return nil
        }
        return ActivityStats(
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            duration: duration,
            averagePace: averagePace
        )
    }
}
