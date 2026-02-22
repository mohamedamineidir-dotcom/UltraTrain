import Foundation

struct IntervalSplit: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var phaseIndex: Int
    var phaseType: IntervalPhaseType
    var startTime: TimeInterval
    var endTime: TimeInterval
    var distanceKm: Double
    var averagePaceSecondsPerKm: Double
    var averageHeartRate: Int?
    var maxHeartRate: Int?

    var duration: TimeInterval { endTime - startTime }
}
