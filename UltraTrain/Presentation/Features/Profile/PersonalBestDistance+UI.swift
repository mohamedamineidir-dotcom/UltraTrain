import SwiftUI

/// Presentation-only identity for each PR distance, shared by the
/// Personal Records list and the Log-a-PR sheet so a given distance
/// always reads with the same colour + glyph. The accent ramps cool to
/// warm as the distance grows (5K cyan → Marathon coral), giving the
/// athlete an intuitive "effort/length increases" cue at a glance.
extension PersonalBestDistance {
    var accent: Color {
        switch self {
        case .fiveK:        Theme.Colors.info
        case .tenK:         Color.mint
        case .halfMarathon: Theme.Colors.amberAccent
        case .marathon:     Theme.Colors.warmCoral
        }
    }

    var icon: String {
        switch self {
        case .fiveK:        "bolt.fill"
        case .tenK:         "figure.run"
        case .halfMarathon: "flag.checkered"
        case .marathon:     "medal.fill"
        }
    }
}
