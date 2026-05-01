import Foundation

/// Body structures that an athlete reports as recurring injury sites.
/// Captured at onboarding (multi-select). Currently surfaced to coach
/// advice and used to dampen volume caps. Future use: bias session
/// selection (e.g. avoid stacking VG immediately after intervals for
/// ITB-prone athletes).
enum InjuryStructure: String, CaseIterable, Sendable, Codable {
    case knees
    case achilles
    case hips
    case itBand = "ITB"
    case calf
    case footAnkle
    case lowerBack
}
