import Foundation

struct SharedRun: Identifiable, Equatable, Sendable {
    let id: UUID
    var sharedByProfileId: String
    var sharedByDisplayName: String
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var duration: TimeInterval
    var averagePaceSecondsPerKm: Double
    var gpsTrack: [TrackPoint]
    var splits: [Split]
    var notes: String?
    var sharedAt: Date
    var likeCount: Int
    var commentCount: Int
}
