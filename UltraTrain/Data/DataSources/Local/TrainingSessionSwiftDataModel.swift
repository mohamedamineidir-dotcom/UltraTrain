import Foundation
import SwiftData

@Model
final class TrainingSessionSwiftDataModel {
    var id: UUID = UUID()
    var date: Date = Date()
    var typeRaw: String = "easy"
    var plannedDistanceKm: Double = 0
    var plannedElevationGainM: Double = 0
    var plannedDuration: Double = 0
    var intensityRaw: String = "low"
    var sessionDescription: String = ""
    var nutritionNotes: String?
    var isCompleted: Bool = false
    var isSkipped: Bool = false
    var linkedRunId: UUID?
    var targetHeartRateZone: Int?
    var intervalWorkoutId: UUID?
    /// RR-24: physiological focus label for road intervals/tempo
    /// (e.g. "Speed", "VO2max", "Threshold", "Race pace"). Nil for
    /// legacy records — the mapper treats that as "no focus".
    var intervalFocus: String?
    var week: TrainingWeekSwiftDataModel?
    var isKeySession: Bool = false
    var coachAdvice: String?
    var actualDistanceKm: Double?
    var actualDurationSeconds: Double?
    var actualElevationGainM: Double?
    var perceivedFeelingRaw: String?
    var perceivedExertion: Int?
    var skipReasonRaw: String?
    /// Sub-classification when skipReasonRaw == "menstrualCycle".
    /// Lightweight migration — defaults to nil for legacy sessions.
    var menstrualSymptomClusterRaw: String?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        typeRaw: String = "easy",
        plannedDistanceKm: Double = 0,
        plannedElevationGainM: Double = 0,
        plannedDuration: Double = 0,
        intensityRaw: String = "low",
        sessionDescription: String = "",
        nutritionNotes: String? = nil,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        linkedRunId: UUID? = nil,
        targetHeartRateZone: Int? = nil,
        intervalWorkoutId: UUID? = nil,
        intervalFocus: String? = nil,
        isKeySession: Bool = false,
        coachAdvice: String? = nil,
        actualDistanceKm: Double? = nil,
        actualDurationSeconds: Double? = nil,
        actualElevationGainM: Double? = nil,
        perceivedFeelingRaw: String? = nil,
        perceivedExertion: Int? = nil,
        skipReasonRaw: String? = nil,
        menstrualSymptomClusterRaw: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.typeRaw = typeRaw
        self.plannedDistanceKm = plannedDistanceKm
        self.plannedElevationGainM = plannedElevationGainM
        self.plannedDuration = plannedDuration
        self.intensityRaw = intensityRaw
        self.sessionDescription = sessionDescription
        self.nutritionNotes = nutritionNotes
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.linkedRunId = linkedRunId
        self.targetHeartRateZone = targetHeartRateZone
        self.intervalWorkoutId = intervalWorkoutId
        self.intervalFocus = intervalFocus
        self.isKeySession = isKeySession
        self.coachAdvice = coachAdvice
        self.actualDistanceKm = actualDistanceKm
        self.actualDurationSeconds = actualDurationSeconds
        self.actualElevationGainM = actualElevationGainM
        self.perceivedFeelingRaw = perceivedFeelingRaw
        self.perceivedExertion = perceivedExertion
        self.skipReasonRaw = skipReasonRaw
        self.menstrualSymptomClusterRaw = menstrualSymptomClusterRaw
        self.updatedAt = updatedAt
    }
}
