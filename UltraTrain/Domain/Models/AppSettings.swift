import Foundation

struct AppSettings: Identifiable, Equatable, Sendable {
    let id: UUID
    var trainingRemindersEnabled: Bool
    var nutritionRemindersEnabled: Bool
    var autoPauseEnabled: Bool
    var nutritionAlertSoundEnabled: Bool
}
