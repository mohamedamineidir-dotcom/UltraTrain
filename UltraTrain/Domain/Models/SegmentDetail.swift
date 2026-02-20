import Foundation

struct SegmentDetail: Identifiable, Equatable, Sendable {
    let id: Int
    var kilometerNumber: Int
    var paceSecondsPerKm: Double
    var elevationChangeM: Double
    var averageHeartRate: Int?
    var zone: Int?
    var coordinate: (Double, Double)

    static func == (lhs: SegmentDetail, rhs: SegmentDetail) -> Bool {
        lhs.id == rhs.id
    }
}
