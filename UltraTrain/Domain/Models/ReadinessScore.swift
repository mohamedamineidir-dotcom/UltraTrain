import Foundation

struct ReadinessScore: Equatable, Sendable, Codable {
    let overallScore: Int
    let recoveryComponent: Int
    let hrvComponent: Int
    let trainingLoadComponent: Int
    let status: ReadinessStatus
    let sessionRecommendation: SessionIntensityRecommendation
}

enum ReadinessStatus: String, Codable, Sendable {
    case primed
    case ready
    case moderate
    case fatigued
    case needsRest
}

enum SessionIntensityRecommendation: String, Codable, Sendable {
    case highIntensity
    case moderateEffort
    case easyOnly
    case restDay
    case activeRecovery

    var displayText: String {
        switch self {
        case .highIntensity: "Great day for intervals or tempo"
        case .moderateEffort: "Good for a steady aerobic run"
        case .easyOnly: "Keep it easy today"
        case .restDay: "Consider a rest day"
        case .activeRecovery: "Light activity or cross-training"
        }
    }
}
