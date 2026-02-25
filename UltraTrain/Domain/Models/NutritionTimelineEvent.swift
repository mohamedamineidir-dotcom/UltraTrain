import Foundation

struct NutritionTimelineEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    var elapsedTimeSeconds: TimeInterval
    var type: NutritionReminderType
    var status: NutritionIntakeStatus
    var paceAtTime: Double?
}
