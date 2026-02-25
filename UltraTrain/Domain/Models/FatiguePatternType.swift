import Foundation

enum FatiguePatternType: String, Sendable, CaseIterable {
    case paceDecline
    case heartRateDrift
    case sleepQualityDecline
    case rpeTrend
    case compoundFatigue
}
