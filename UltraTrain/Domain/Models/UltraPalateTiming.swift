import Foundation

/// When the athlete typically hits flavour fatigue on long efforts
/// the point where sweet gels become unpalatable and savoury/real
/// food works better. Research (Costa 2017 on GI issues in ultra
/// endurance) shows this varies widely per athlete.
///
/// Only asked for races ≥ 60 km. Shorter races rarely push an athlete
/// past the sweet-only window so the question isn't useful.
enum UltraPalateTiming: String, CaseIterable, Codable, Sendable {
    /// Savoury craving within the first 2 hours. Unusual but real
    /// these athletes should have real food planned from early aid
    /// stations rather than gel-first.
    case early
    /// Mid-race (2-4h) shift. Most common pattern. Plan gels for the
    /// first half, real food + salty options thereafter.
    case mid
    /// Late shift (4h+). Athlete can stay on gels through most of a
    /// 50K-ish race but needs real food backup for the final third of
    /// a 100K+.
    case late
    /// Never, the athlete handles sweet fuelling through any
    /// duration without palate fatigue. Plan can stay gel-centric.
    case never

    var displayName: String {
        switch self {
        case .early:  return String(localized: "upt.early.title", defaultValue: "Early (under 2 hours)")
        case .mid:    return String(localized: "upt.mid.title", defaultValue: "Mid-race (2-4 hours in)")
        case .late:   return String(localized: "upt.late.title", defaultValue: "Late (past 4 hours)")
        case .never:  return String(localized: "upt.never.title", defaultValue: "Never, I'm fine with sweet all race")
        }
    }

    var subtitle: String {
        switch self {
        case .early:
            return String(localized: "upt.early.desc", defaultValue: "Plan real food from the first aid stations")
        case .mid:
            return String(localized: "upt.mid.desc", defaultValue: "Gels early, switch to real food mid-race")
        case .late:
            return String(localized: "upt.late.desc", defaultValue: "Gels through most of the race, real food late")
        case .never:
            return String(localized: "upt.never.desc", defaultValue: "Stay gel-centric throughout")
        }
    }
}
