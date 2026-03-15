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
    var isKeySession: Bool = false
    var coachAdvice: String? = nil
    var actualDistanceKm: Double? = nil
    var actualDurationSeconds: TimeInterval? = nil
    var actualElevationGainM: Double? = nil
    var perceivedFeeling: PerceivedFeeling? = nil
    var perceivedExertion: Int? = nil

    var isGutTrainingRecommended: Bool {
        (type == .longRun || type == .backToBack) && plannedDuration >= 7200
    }
}
