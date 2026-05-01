import Foundation

/// Sub-classification of a menstrual-cycle skip. Drives the menstrual
/// adaptation calculator: bleed-day vs pre-period symptoms have
/// different evidence-backed responses (Yang 2024, Schmalenberger 2019).
/// Asymptomatic logs are also tracked but trigger no plan adjustment —
/// the strongest research (McNulty 2020 meta-analysis) supports
/// individualised, symptom-driven responses, not phase-based defaults.
enum MenstrualSymptomCluster: String, CaseIterable, Sendable, Codable {
    /// Cramps, heavy flow, fatigue. Effect window 24-48 h.
    /// Light aerobic helps (Yang 2024 NMA), heavy intensity poorly tolerated.
    case bleedDay

    /// PMS, mood, GI, sleep, breast pain, bloating. Effect window
    /// 3-5 days. HRV evidence (Schmalenberger 2019) shows delayed
    /// recovery in symptomatic women in late luteal — heat-sensitive
    /// long tempo and high-cognitive intervals are the most affected.
    case prePeriod

    /// Just bleeding, no symptoms. Logged for the athlete's records;
    /// no plan adjustment is offered. McNulty 2020 explicitly: many
    /// athletes train and PR while bleeding asymptomatically.
    case asymptomatic

    /// Athlete declined to specify. Treated like a generic skip —
    /// fall through to existing fatigue-pattern logic.
    case unspecified
}
