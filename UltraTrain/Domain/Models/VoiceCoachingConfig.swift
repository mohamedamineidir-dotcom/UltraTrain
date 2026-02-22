import Foundation

struct VoiceCoachingConfig: Equatable, Sendable, Codable {
    var enabled: Bool = false
    var announceDistanceSplits: Bool = true
    var announceTimeSplits: Bool = false
    var timeSplitIntervalMinutes: Int = 5
    var announceHRZoneChanges: Bool = true
    var announceNutritionReminders: Bool = true
    var announceCheckpoints: Bool = true
    var announcePacingAlerts: Bool = true
    var announceZoneDriftAlerts: Bool = true
    var announceIntervalTransitions: Bool = true
    var speechRate: Float = 0.5
}
