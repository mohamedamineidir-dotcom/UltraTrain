import Foundation

struct ElevationSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var coordinates: [(Double, Double)]
    var averageGradient: Double
    var kilometerNumber: Int

    static func == (lhs: ElevationSegment, rhs: ElevationSegment) -> Bool {
        lhs.id == rhs.id
    }
}
