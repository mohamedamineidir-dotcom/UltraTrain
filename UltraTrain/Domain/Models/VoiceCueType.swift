import Foundation

enum VoiceCueType: String, Codable, Sendable {
    case distanceSplit
    case timeSplit
    case heartRateZoneChange
    case nutritionReminder
    case checkpointCrossing
    case pacingAlert
    case zoneDriftAlert
    case runStarted
    case runPaused
    case runResumed
    case autoPaused
    case intervalPhaseStart
    case intervalPhaseEnd
    case intervalCountdown
    case intervalWorkoutComplete
    case sosActivated
    case fallDetected
    case noMovementWarning
    case safetyTimerWarning
    case checkpointArrival
    case offCourseWarning
}
