import Foundation

struct SafetyConfig: Equatable, Sendable, Codable {
    var sosEnabled: Bool = true
    var fallDetectionEnabled: Bool = true
    var noMovementAlertEnabled: Bool = true
    var noMovementThresholdMinutes: Int = 5
    var safetyTimerEnabled: Bool = false
    var safetyTimerDurationMinutes: Int = 120
    var countdownBeforeSendingSeconds: Int = 30
    var includeLocationInMessage: Bool = true
}
