import Foundation
import SwiftData

@Model
final class AppSettingsSwiftDataModel {
    var id: UUID = UUID()
    var trainingRemindersEnabled: Bool = true
    var nutritionRemindersEnabled: Bool = true
    var autoPauseEnabled: Bool = true
    var nutritionAlertSoundEnabled: Bool = true
    var stravaAutoUploadEnabled: Bool = false
    var stravaConnected: Bool = false
    var raceCountdownEnabled: Bool = true
    var biometricLockEnabled: Bool = false
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        trainingRemindersEnabled: Bool = true,
        nutritionRemindersEnabled: Bool = true,
        autoPauseEnabled: Bool = true,
        nutritionAlertSoundEnabled: Bool = true,
        stravaAutoUploadEnabled: Bool = false,
        stravaConnected: Bool = false,
        raceCountdownEnabled: Bool = true,
        biometricLockEnabled: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.trainingRemindersEnabled = trainingRemindersEnabled
        self.nutritionRemindersEnabled = nutritionRemindersEnabled
        self.autoPauseEnabled = autoPauseEnabled
        self.nutritionAlertSoundEnabled = nutritionAlertSoundEnabled
        self.stravaAutoUploadEnabled = stravaAutoUploadEnabled
        self.stravaConnected = stravaConnected
        self.raceCountdownEnabled = raceCountdownEnabled
        self.biometricLockEnabled = biometricLockEnabled
        self.updatedAt = updatedAt
    }
}
