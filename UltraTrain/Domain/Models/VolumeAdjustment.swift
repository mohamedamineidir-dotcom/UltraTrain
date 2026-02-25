import Foundation

struct VolumeAdjustment: Equatable, Sendable {
    let sessionId: UUID
    let addedDistanceKm: Double
    let addedElevationGainM: Double
    let newType: SessionType?
}
