import Foundation

struct RouteSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    var coordinates: [(Double, Double)]
    var paceSecondsPerKm: Double
    var kilometerNumber: Int

    static func == (lhs: RouteSegment, rhs: RouteSegment) -> Bool {
        lhs.id == rhs.id
    }
}
