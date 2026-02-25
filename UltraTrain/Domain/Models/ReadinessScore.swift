import Foundation

struct ReadinessScore: Equatable, Sendable, Codable {
    let overallScore: Int
    let recoveryComponent: Int
    let hrvComponent: Int
    let trainingLoadComponent: Int
    let status: ReadinessStatus
    let sessionRecommendation: SessionIntensityRecommendation
}
