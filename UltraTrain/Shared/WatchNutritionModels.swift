import Foundation

enum WatchNutritionReminderType: String, Codable, Sendable, CaseIterable {
    case hydration
    case fuel
    case electrolyte
}

struct WatchNutritionReminder: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    var triggerTimeSeconds: TimeInterval
    var message: String
    var type: WatchNutritionReminderType
    var isDismissed: Bool

    init(
        id: UUID = UUID(),
        triggerTimeSeconds: TimeInterval,
        message: String,
        type: WatchNutritionReminderType,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.triggerTimeSeconds = triggerTimeSeconds
        self.message = message
        self.type = type
        self.isDismissed = isDismissed
    }
}
