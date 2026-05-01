import Foundation

/// Reason why the athlete skipped a training session.
///
/// Research basis (Koop, Magness, Roche, Canova):
/// - Each reason carries different training implications.
/// - Pattern detection across multiple skips is more meaningful than isolated skips.
/// - Fatigue/soreness/illness reasons signal physiological stress and require load reduction.
/// - Time/weather/other reasons are logistical and don't indicate fitness issues.
enum SkipReason: String, CaseIterable, Sendable, Codable {
    /// External scheduling conflict — not a fitness signal.
    case noTime

    /// Physical tiredness or fatigue — potential overtraining signal.
    case fatigue

    /// Mental resistance to training — may indicate monotony or overreaching.
    case noMotivation

    /// Muscle soreness, joint discomfort, or minor pain — early injury warning.
    case soreness

    /// Feeling unwell, cold, flu, or other illness — immune stress, needs aggressive rest.
    case illness

    /// Bad weather or unsafe conditions — purely external, no fitness implication.
    case weather

    /// Acute injury — strain, sprain, sharp pain. Needs aggressive rest protocol.
    case injury

    /// Catch-all for reasons not listed above.
    case other

    /// Menstruation-related skip. Always paired with a
    /// `MenstrualSymptomCluster` on the session to drive the right
    /// adaptation. Rationale and full evidence base in
    /// `MenstrualAdaptationCalculator` — short version: research
    /// (McNulty 2020 meta-analysis, IOC 2023, UEFA 2025) supports
    /// symptom-driven response, not phase-based prescription.
    case menstrualCycle
}
