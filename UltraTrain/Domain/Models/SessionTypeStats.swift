import Foundation

struct SessionTypeStats: Identifiable, Equatable, Sendable {
    let id: UUID
    var sessionType: SessionType
    var count: Int
    var totalDistanceKm: Double
    var totalDuration: TimeInterval
    var percentage: Double
}
