import Foundation

struct IntervalWorkoutState: Equatable, Sendable {
    var currentPhaseIndex: Int
    var currentPhaseType: IntervalPhaseType
    var currentRepeat: Int
    var totalRepeats: Int
    var phaseElapsedTime: TimeInterval
    var phaseElapsedDistance: Double
    var phaseRemainingTime: TimeInterval?
    var phaseRemainingDistance: Double?
    var isLastPhase: Bool
    var completedPhases: Int
    var totalPhases: Int
    var overallProgress: Double
    var targetIntensity: Intensity
}
