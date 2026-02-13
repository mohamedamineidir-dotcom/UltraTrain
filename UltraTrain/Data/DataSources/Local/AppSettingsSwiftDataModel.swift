import Foundation
import SwiftData

@Model
final class AppSettingsSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var trainingRemindersEnabled: Bool
    var nutritionRemindersEnabled: Bool
    var autoPauseEnabled: Bool

    init(
        id: UUID,
        trainingRemindersEnabled: Bool,
        nutritionRemindersEnabled: Bool,
        autoPauseEnabled: Bool
    ) {
        self.id = id
        self.trainingRemindersEnabled = trainingRemindersEnabled
        self.nutritionRemindersEnabled = nutritionRemindersEnabled
        self.autoPauseEnabled = autoPauseEnabled
    }
}
