import Foundation
import SwiftData

@Model
final class AppSettingsSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var trainingRemindersEnabled: Bool
    var nutritionRemindersEnabled: Bool
    var autoPauseEnabled: Bool
    var nutritionAlertSoundEnabled: Bool = true
    var stravaAutoUploadEnabled: Bool = false
    var stravaConnected: Bool = false

    init(
        id: UUID,
        trainingRemindersEnabled: Bool,
        nutritionRemindersEnabled: Bool,
        autoPauseEnabled: Bool,
        nutritionAlertSoundEnabled: Bool,
        stravaAutoUploadEnabled: Bool = false,
        stravaConnected: Bool = false
    ) {
        self.id = id
        self.trainingRemindersEnabled = trainingRemindersEnabled
        self.nutritionRemindersEnabled = nutritionRemindersEnabled
        self.autoPauseEnabled = autoPauseEnabled
        self.nutritionAlertSoundEnabled = nutritionAlertSoundEnabled
        self.stravaAutoUploadEnabled = stravaAutoUploadEnabled
        self.stravaConnected = stravaConnected
    }
}
