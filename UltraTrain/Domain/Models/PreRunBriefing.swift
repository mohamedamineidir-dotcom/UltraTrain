import Foundation

struct PreRunBriefing: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var readinessStatus: RecoveryStatus?
    var readinessScore: Int?
    var weather: WeatherSnapshot?
    var adaptiveAdjustment: AdaptiveSessionAdjustment?
    var pacingRecommendation: String?
    var nutritionReminder: String?
    var focusPoint: String
    var recentPerformanceSummary: String?
    var fatigueAlerts: [FatiguePattern]
}
