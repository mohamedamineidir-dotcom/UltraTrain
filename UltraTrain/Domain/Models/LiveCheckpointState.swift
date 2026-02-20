import Foundation

struct LiveCheckpointState: Identifiable, Equatable, Sendable {
    let id: UUID
    let checkpointName: String
    let distanceFromStartKm: Double
    let hasAidStation: Bool
    var predictedTime: TimeInterval
    var actualTime: TimeInterval?

    var delta: TimeInterval? {
        guard let actualTime else { return nil }
        return actualTime - predictedTime
    }

    var isCrossed: Bool {
        actualTime != nil
    }
}
