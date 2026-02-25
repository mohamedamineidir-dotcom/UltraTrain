import Foundation

struct NutritionAnalysis: Equatable, Sendable {
    var timelineEvents: [NutritionTimelineEvent]
    var performanceImpact: NutritionPerformanceImpact?
    var adherencePercent: Double
    var totalCaloriesConsumed: Double
}
