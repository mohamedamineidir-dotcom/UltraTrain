import SwiftUI

extension RacePacingCalculator.PacingZone {

    var label: String {
        switch self {
        case .easy: "Easy"
        case .moderate: "Moderate"
        case .hard: "Hard"
        }
    }

    var color: Color {
        switch self {
        case .easy: Theme.Colors.success
        case .moderate: Theme.Colors.primary
        case .hard: Theme.Colors.warning
        }
    }
}
