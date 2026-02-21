import Foundation
import SwiftData

@Model
final class ActivityFeedItemSwiftDataModel {
    var id: UUID = UUID()
    var athleteProfileId: String = ""
    var athleteDisplayName: String = ""
    @Attribute(.externalStorage) var athletePhotoData: Data?
    var activityTypeRaw: String = "completedRun"
    var title: String = ""
    var subtitle: String?
    var statsDistanceKm: Double?
    var statsElevationGainM: Double?
    var statsDuration: Double?
    var statsAveragePace: Double?
    var timestamp: Date = Date()
    var likeCount: Int = 0
    var isLikedByMe: Bool = false

    init(
        id: UUID = UUID(),
        athleteProfileId: String = "",
        athleteDisplayName: String = "",
        athletePhotoData: Data? = nil,
        activityTypeRaw: String = "completedRun",
        title: String = "",
        subtitle: String? = nil,
        statsDistanceKm: Double? = nil,
        statsElevationGainM: Double? = nil,
        statsDuration: Double? = nil,
        statsAveragePace: Double? = nil,
        timestamp: Date = Date(),
        likeCount: Int = 0,
        isLikedByMe: Bool = false
    ) {
        self.id = id
        self.athleteProfileId = athleteProfileId
        self.athleteDisplayName = athleteDisplayName
        self.athletePhotoData = athletePhotoData
        self.activityTypeRaw = activityTypeRaw
        self.title = title
        self.subtitle = subtitle
        self.statsDistanceKm = statsDistanceKm
        self.statsElevationGainM = statsElevationGainM
        self.statsDuration = statsDuration
        self.statsAveragePace = statsAveragePace
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.isLikedByMe = isLikedByMe
    }
}
