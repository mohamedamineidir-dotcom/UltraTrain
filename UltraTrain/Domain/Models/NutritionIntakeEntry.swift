import Foundation

enum NutritionIntakeStatus: String, CaseIterable, Sendable {
    case taken
    case skipped
    case pending
}

struct NutritionIntakeEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var reminderType: NutritionReminderType
    var status: NutritionIntakeStatus
    var elapsedTimeSeconds: TimeInterval
    var message: String

    init(
        id: UUID = UUID(),
        reminderType: NutritionReminderType,
        status: NutritionIntakeStatus,
        elapsedTimeSeconds: TimeInterval,
        message: String
    ) {
        self.id = id
        self.reminderType = reminderType
        self.status = status
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.message = message
    }
}
