import Foundation
import SwiftData

@Model
final class RaceReflectionSwiftDataModel {
    var id: UUID = UUID()
    var raceId: UUID = UUID()
    var completedRunId: UUID?
    var actualFinishTime: Double = 0
    var actualPosition: Int?
    var pacingAssessmentRaw: String = ""
    var pacingNotes: String?
    var nutritionAssessmentRaw: String = ""
    var nutritionNotes: String?
    var hadStomachIssues: Bool = false
    var weatherImpactRaw: String = ""
    var weatherNotes: String?
    var overallSatisfaction: Int = 0
    var keyTakeaways: String = ""
    var createdAt: Date = Date.distantPast
    var updatedAt: Date = Date.distantPast

    init(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        completedRunId: UUID? = nil,
        actualFinishTime: Double = 0,
        actualPosition: Int? = nil,
        pacingAssessmentRaw: String = "",
        pacingNotes: String? = nil,
        nutritionAssessmentRaw: String = "",
        nutritionNotes: String? = nil,
        hadStomachIssues: Bool = false,
        weatherImpactRaw: String = "",
        weatherNotes: String? = nil,
        overallSatisfaction: Int = 0,
        keyTakeaways: String = "",
        createdAt: Date = Date.distantPast,
        updatedAt: Date = Date.distantPast
    ) {
        self.id = id
        self.raceId = raceId
        self.completedRunId = completedRunId
        self.actualFinishTime = actualFinishTime
        self.actualPosition = actualPosition
        self.pacingAssessmentRaw = pacingAssessmentRaw
        self.pacingNotes = pacingNotes
        self.nutritionAssessmentRaw = nutritionAssessmentRaw
        self.nutritionNotes = nutritionNotes
        self.hadStomachIssues = hadStomachIssues
        self.weatherImpactRaw = weatherImpactRaw
        self.weatherNotes = weatherNotes
        self.overallSatisfaction = overallSatisfaction
        self.keyTakeaways = keyTakeaways
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
