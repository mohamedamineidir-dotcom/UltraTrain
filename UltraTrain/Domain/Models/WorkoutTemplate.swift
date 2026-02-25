import Foundation

struct WorkoutTemplate: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var sessionType: SessionType
    var targetDistanceKm: Double
    var targetElevationGainM: Double
    var estimatedDuration: TimeInterval
    var intensity: Intensity
    var category: WorkoutCategory
    var descriptionText: String
    var isUserCreated: Bool
}
