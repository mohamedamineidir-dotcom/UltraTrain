import Foundation

struct RaceReflection: Identifiable, Equatable, Sendable {
    let id: UUID
    var raceId: UUID
    var completedRunId: UUID?
    var actualFinishTime: TimeInterval
    var actualPosition: Int?
    var pacingAssessment: PacingAssessment
    var pacingNotes: String?
    var nutritionAssessment: NutritionAssessment
    var nutritionNotes: String?
    var hadStomachIssues: Bool
    var weatherImpact: WeatherImpactLevel
    var weatherNotes: String?
    var overallSatisfaction: Int
    var keyTakeaways: String
    var createdAt: Date
}
