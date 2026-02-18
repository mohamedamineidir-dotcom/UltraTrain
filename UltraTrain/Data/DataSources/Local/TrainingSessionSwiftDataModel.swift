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
    var week: TrainingWeekSwiftDataModel?
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
        self.updatedAt = updatedAt
    }
}
