import Foundation

struct HeartRateSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var coordinates: [(Double, Double)]
    var averageHeartRate: Int
    var zone: Int
    var kilometerNumber: Int

    static func == (lhs: HeartRateSegment, rhs: HeartRateSegment) -> Bool {
        lhs.id == rhs.id
    }
}
