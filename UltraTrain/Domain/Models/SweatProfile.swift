import Foundation

/// Athlete-specific sweat characteristics. Drives personalized hydration +
/// sodium targets.
///
/// Research basis (Precision Fuel & Hydration, GSSI): sweat rate varies
/// 400-2000 ml/hr across athletes; sweat sodium 200-2000 mg/L. Without a
/// lab test, visual indicators (white crystal on skin, stinging eyes from
/// sweat, salt stains on dark clothing) reliably classify heavy salty
/// sweaters. When no data is available, generator falls back to temperature
/// + humidity + body weight heuristics.
struct SweatProfile: Equatable, Sendable, Codable {
    /// Measured sweat rate from a sweat-rate test (weigh before/after 1h run).
    var sweatRateMlPerHour: Int?
    /// Measured sweat sodium concentration (ml/L).
    var sweatSodiumMgPerL: Int?
    /// Heuristic flag when no lab test exists — white salt marks, stinging eyes.
    var heavySaltySweater: Bool

    static let unknown = SweatProfile(
        sweatRateMlPerHour: nil,
        sweatSodiumMgPerL: nil,
        heavySaltySweater: false
    )
}
