import Foundation

struct FinishEstimate: Identifiable, Equatable, Sendable {
    let id: UUID
    var raceId: UUID
    var athleteId: UUID
    var calculatedAt: Date
    var optimisticTime: TimeInterval
    var expectedTime: TimeInterval
    var conservativeTime: TimeInterval
    var checkpointSplits: [CheckpointSplit]
    var confidencePercent: Double
    var raceResultsUsed: Int
    var calibrationFactor: Double = 1.0
    var weatherMultiplier: Double? = nil
    var weatherImpactSummary: String? = nil

    var expectedTimeFormatted: String {
        Self.formatDuration(expectedTime)
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh%02d", hours, minutes)
    }
}

struct CheckpointSplit: Identifiable, Equatable, Sendable {
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
