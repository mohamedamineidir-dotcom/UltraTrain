import Foundation
import SwiftData

@Model
final class CompletedRunSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var athleteId: UUID
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var duration: Double
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var averagePaceSecondsPerKm: Double
    var gpsTrackData: Data
    @Relationship(deleteRule: .cascade) var splits: [SplitSwiftDataModel]
    var linkedSessionId: UUID?
    var notes: String?
    var pausedDuration: Double

    init(
        id: UUID,
        athleteId: UUID,
        date: Date,
        distanceKm: Double,
        elevationGainM: Double,
        elevationLossM: Double,
        duration: Double,
        averageHeartRate: Int?,
        maxHeartRate: Int?,
        averagePaceSecondsPerKm: Double,
        gpsTrackData: Data,
        splits: [SplitSwiftDataModel],
        linkedSessionId: UUID?,
        notes: String?,
        pausedDuration: Double
    ) {
        self.id = id
        self.athleteId = athleteId
        self.date = date
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.gpsTrackData = gpsTrackData
        self.splits = splits
        self.linkedSessionId = linkedSessionId
        self.notes = notes
        self.pausedDuration = pausedDuration
    }
}
