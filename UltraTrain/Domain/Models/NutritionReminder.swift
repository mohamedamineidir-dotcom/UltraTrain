import Foundation

enum NutritionReminderType: String, CaseIterable, Sendable {
    case hydration
    case fuel
    case electrolyte
}

struct NutritionReminder: Identifiable, Equatable, Sendable {
    let id: UUID
    var triggerTimeSeconds: TimeInterval
    var message: String
    var type: NutritionReminderType
    var isDismissed: Bool

    init(
        id: UUID = UUID(),
        triggerTimeSeconds: TimeInterval,
        message: String,
        type: NutritionReminderType,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.triggerTimeSeconds = triggerTimeSeconds
        self.message = message
        self.type = type
        self.isDismissed = isDismissed
    }
}
