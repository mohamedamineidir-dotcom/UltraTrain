import Foundation

enum PacingAssessment: String, CaseIterable, Sendable {
    case tooFast
    case tooSlow
    case wellPaced
    case mixedPacing
}

enum NutritionAssessment: String, CaseIterable, Sendable {
    case perfect
    case goodEnough
    case someIssues
    case majorProblems
}

enum WeatherImpactLevel: String, CaseIterable, Sendable {
    case noImpact
    case minor
    case significant
    case severe
}
