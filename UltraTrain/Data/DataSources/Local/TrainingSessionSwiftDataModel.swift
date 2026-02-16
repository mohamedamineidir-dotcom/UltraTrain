import Foundation
import SwiftData

@Model
final class TrainingSessionSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var typeRaw: String
    var plannedDistanceKm: Double
    var plannedElevationGainM: Double
    var plannedDuration: Double
    var intensityRaw: String
    var sessionDescription: String
    var nutritionNotes: String?
    var isCompleted: Bool
    var isSkipped: Bool = false
    var linkedRunId: UUID?

    init(
        id: UUID,
        date: Date,
        typeRaw: String,
        plannedDistanceKm: Double,
        plannedElevationGainM: Double,
        plannedDuration: Double,
        intensityRaw: String,
        sessionDescription: String,
        nutritionNotes: String?,
        isCompleted: Bool,
        isSkipped: Bool,
        linkedRunId: UUID?
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
    }
}
