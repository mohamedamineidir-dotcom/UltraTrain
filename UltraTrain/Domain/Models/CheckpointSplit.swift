import Foundation

struct CheckpointSplit: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var checkpointId: UUID
    var checkpointName: String
    var distanceFromStartKm: Double
    var segmentDistanceKm: Double
    var segmentElevationGainM: Double
    var segmentElevationLossM: Double = 0
    var hasAidStation: Bool
    var optimisticTime: TimeInterval
    var expectedTime: TimeInterval
    var conservativeTime: TimeInterval
}
