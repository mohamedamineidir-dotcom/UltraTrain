import Foundation

struct SavedRoute: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var trackPoints: [TrackPoint]
    var courseRoute: [TrackPoint]
    var checkpoints: [Checkpoint]
    var source: RouteSource
    var createdAt: Date
    var notes: String?
    var sourceRunId: UUID?

    var hasCourseRoute: Bool { !courseRoute.isEmpty }

    static func == (lhs: SavedRoute, rhs: SavedRoute) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.distanceKm == rhs.distanceKm
            && lhs.elevationGainM == rhs.elevationGainM
            && lhs.elevationLossM == rhs.elevationLossM
            && lhs.source == rhs.source
            && lhs.createdAt == rhs.createdAt
            && lhs.courseRoute.count == rhs.courseRoute.count
    }
}
