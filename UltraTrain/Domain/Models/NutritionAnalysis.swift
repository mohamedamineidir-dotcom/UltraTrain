import Foundation

struct NutritionAnalysis: Equatable, Sendable {
    var timelineEvents: [NutritionTimelineEvent]
    var performanceImpact: NutritionPerformanceImpact?
    var adherencePercent: Double
    var totalCaloriesConsumed: Double
}

struct NutritionTimelineEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    var elapsedTimeSeconds: TimeInterval
    var type: NutritionReminderType
    var status: NutritionIntakeStatus
    var paceAtTime: Double?
}

struct NutritionPerformanceImpact: Equatable, Sendable {
    var averagePaceBeforeFirstIntake: Double
    var averagePaceAfterLastIntake: Double
    var paceChangePercent: Double
}
