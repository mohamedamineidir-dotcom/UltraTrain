import Foundation

struct AdvancedRunMetrics: Equatable, Sendable {
    var paceVariabilityIndex: Double
    var climbingEfficiency: Double?
    var estimatedCalories: Double
    var trainingEffectScore: Double
    var averageGradientAdjustedPace: Double
}
