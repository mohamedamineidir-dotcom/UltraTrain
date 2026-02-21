import Foundation
import SwiftData

@Model
final class SharedRunSwiftDataModel {
    var id: UUID = UUID()
    var sharedByProfileId: String = ""
    var sharedByDisplayName: String = ""
    var date: Date = Date()
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var duration: Double = 0
    var averagePaceSecondsPerKm: Double = 0
    @Attribute(.externalStorage) var gpsTrackData: Data = Data()
    @Attribute(.externalStorage) var splitsData: Data = Data()
    var notes: String?
    var sharedAt: Date = Date()
    var likeCount: Int = 0
    var commentCount: Int = 0

    init(
        id: UUID = UUID(),
        sharedByProfileId: String = "",
        sharedByDisplayName: String = "",
        date: Date = Date(),
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        elevationLossM: Double = 0,
        duration: Double = 0,
        averagePaceSecondsPerKm: Double = 0,
        gpsTrackData: Data = Data(),
        splitsData: Data = Data(),
        notes: String? = nil,
        sharedAt: Date = Date(),
        likeCount: Int = 0,
        commentCount: Int = 0
    ) {
        self.id = id
        self.sharedByProfileId = sharedByProfileId
        self.sharedByDisplayName = sharedByDisplayName
        self.date = date
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.duration = duration
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.gpsTrackData = gpsTrackData
        self.splitsData = splitsData
        self.notes = notes
        self.sharedAt = sharedAt
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}
