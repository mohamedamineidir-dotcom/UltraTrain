import SwiftUI

extension PacingAssessment {
    var displayLabel: String {
        switch self {
        case .tooFast: "Too Fast"
        case .tooSlow: "Too Slow"
        case .wellPaced: "Well Paced"
        case .mixedPacing: "Mixed"
        }
    }

    var displayColor: Color {
        switch self {
        case .tooFast: Theme.Colors.danger
        case .tooSlow: Theme.Colors.warning
        case .wellPaced: Theme.Colors.success
        case .mixedPacing: Theme.Colors.warning
        }
    }
}

extension NutritionAssessment {
    var displayLabel: String {
        switch self {
        case .perfect: "Perfect"
        case .goodEnough: "Good Enough"
        case .someIssues: "Some Issues"
        case .majorProblems: "Major Problems"
        }
    }

    var displayColor: Color {
        switch self {
        case .perfect: Theme.Colors.success
        case .goodEnough: Theme.Colors.primary
        case .someIssues: Theme.Colors.warning
        case .majorProblems: Theme.Colors.danger
        }
    }
}

extension WeatherImpactLevel {
    var displayLabel: String {
        switch self {
        case .noImpact: "No Impact"
        case .minor: "Minor"
        case .significant: "Significant"
        case .severe: "Severe"
        }
    }

    var displayColor: Color {
        switch self {
        case .noImpact: Theme.Colors.success
        case .minor: Theme.Colors.primary
        case .significant: Theme.Colors.warning
        case .severe: Theme.Colors.danger
        }
    }
}
