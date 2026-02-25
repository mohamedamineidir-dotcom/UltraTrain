import Foundation

enum TrainingPhase: String, CaseIterable, Sendable, Codable {
    case base
    case build
    case peak
    case taper
    case recovery
    case race
}
