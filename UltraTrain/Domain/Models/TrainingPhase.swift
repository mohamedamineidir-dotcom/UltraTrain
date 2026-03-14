import Foundation

enum TrainingPhase: String, CaseIterable, Sendable, Codable {
    case base
    case build
    case peak
    case taper
    case recovery
    case race

    /// Default PhaseFocus mapping for convenience (tests, backward compat).
    var defaultFocus: PhaseFocus {
        switch self {
        case .base:     .threshold30
        case .build:    .vo2max
        case .peak:     .threshold60
        case .taper:    .sharpening
        case .recovery: .postRaceRecovery
        case .race:     .sharpening
        }
    }
}
