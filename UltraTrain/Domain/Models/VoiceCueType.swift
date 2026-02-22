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

struct VoiceCue: Equatable, Sendable {
    let type: VoiceCueType
    let message: String
    let priority: VoiceCuePriority
}

enum VoiceCuePriority: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: VoiceCuePriority, rhs: VoiceCuePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
