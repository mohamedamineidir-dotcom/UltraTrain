import Foundation

struct HeartRateZoneDistribution: Identifiable, Equatable, Sendable {
    var id: Int { zone }
    var zone: Int
    var zoneName: String
    var durationSeconds: TimeInterval
    var percentage: Double
}
