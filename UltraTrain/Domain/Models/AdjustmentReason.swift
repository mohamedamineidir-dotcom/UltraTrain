import Foundation

enum AdjustmentReason: String, Sendable, CaseIterable {
    case readinessTooLow
    case readinessHighUpgrade
    case poorSleep
    case highFatigue
    case weatherConditions
    case compoundFatigue
}
