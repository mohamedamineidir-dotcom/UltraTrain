import Foundation

struct TrainingSession: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var date: Date
    var type: SessionType
    var plannedDistanceKm: Double
    var plannedElevationGainM: Double
    var plannedDuration: TimeInterval
    var intensity: Intensity
    var description: String
    var nutritionNotes: String?
    var isCompleted: Bool
    var isSkipped: Bool
    var linkedRunId: UUID?
    var targetHeartRateZone: Int? = nil
    var intervalWorkoutId: UUID? = nil

    var isGutTrainingRecommended: Bool {
        (type == .longRun || type == .backToBack) && plannedDuration >= 7200
    }
}
