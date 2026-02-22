import Foundation

struct AppSettings: Identifiable, Equatable, Sendable {
    let id: UUID
    var trainingRemindersEnabled: Bool
    var nutritionRemindersEnabled: Bool
    var autoPauseEnabled: Bool
    var nutritionAlertSoundEnabled: Bool
    var stravaAutoUploadEnabled: Bool
    var stravaConnected: Bool
    var raceCountdownEnabled: Bool
    var biometricLockEnabled: Bool
    var hydrationIntervalSeconds: TimeInterval
    var fuelIntervalSeconds: TimeInterval
    var electrolyteIntervalSeconds: TimeInterval
    var smartRemindersEnabled: Bool
    var saveToHealthEnabled: Bool
    var healthKitAutoImportEnabled: Bool
    var pacingAlertsEnabled: Bool
    var recoveryRemindersEnabled: Bool
    var weeklySummaryEnabled: Bool
    var voiceCoachingConfig: VoiceCoachingConfig = VoiceCoachingConfig()
    var safetyConfig: SafetyConfig = SafetyConfig()
}
