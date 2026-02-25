import Foundation

struct Split: Identifiable, Equatable, Sendable {
    let id: UUID
    var kilometerNumber: Int
    var duration: TimeInterval
    var elevationChangeM: Double
    var averageHeartRate: Int?
}
