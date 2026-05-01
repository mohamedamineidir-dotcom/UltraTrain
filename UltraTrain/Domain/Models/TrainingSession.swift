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
    var strengthWorkoutId: UUID? = nil
    /// Human-readable label for the interval session's physiological
    /// focus, e.g. "Speed", "VO2max", "Threshold", "Race pace". Populated
    /// by the road plan pipeline at generation time from
    /// `RoadIntervalLibrary.Category`. Nil for trail sessions, easy days,
    /// and sessions without a structured workout attached. Purely
    /// informational — lets the session row/detail distinguish between
    /// "Speed intervals" and "Race-pace intervals" at a glance.
    var intervalFocus: String? = nil
    var isKeySession: Bool = false
    var coachAdvice: String? = nil
    var actualDistanceKm: Double? = nil
    var actualDurationSeconds: TimeInterval? = nil
    var actualElevationGainM: Double? = nil
    var perceivedFeeling: PerceivedFeeling? = nil
    var perceivedExertion: Int? = nil
    var skipReason: SkipReason? = nil
    /// When `skipReason == .menstrualCycle`, sub-classifies the symptom
    /// cluster so `MenstrualAdaptationCalculator` can offer the right
    /// adjustment. Nil for all other skip reasons.
    var menstrualSymptomCluster: MenstrualSymptomCluster? = nil

    var isGutTrainingRecommended: Bool {
        (type == .longRun || type == .backToBack || type == .race) && plannedDuration >= 7200
    }
}
