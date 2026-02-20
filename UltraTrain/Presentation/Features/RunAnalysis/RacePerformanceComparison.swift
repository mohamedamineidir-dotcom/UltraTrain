import Foundation

struct RacePerformanceComparison: Sendable {
    let checkpointComparisons: [CheckpointComparison]
    let predictedFinishTime: TimeInterval
    let actualFinishTime: TimeInterval
    let finishDelta: TimeInterval
}

struct CheckpointComparison: Identifiable, Sendable {
    let id: UUID
    let checkpointName: String
    let distanceFromStartKm: Double
    let hasAidStation: Bool
    let predictedTime: TimeInterval
    let actualTime: TimeInterval
    let delta: TimeInterval
}
