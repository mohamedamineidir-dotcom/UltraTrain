import Foundation

struct RacePacingGuidance: Equatable, Sendable {
    let currentSegmentIndex: Int
    let currentSegmentName: String
    let targetPaceSecondsPerKm: Double
    let currentPaceSecondsPerKm: Double
    let pacingZone: RacePacingCalculator.PacingZone
    let segmentTimeBudgetRemaining: TimeInterval
    let segmentDistanceRemainingKm: Double
    let projectedFinishTime: TimeInterval
    let projectedFinishScenario: FinishScenario
}
