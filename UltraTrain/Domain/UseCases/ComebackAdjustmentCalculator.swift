import Foundation

/// How much the athlete trained during a break from the app (the comeback
/// questionnaire). Maps to how much fitness was likely retained.
enum GapTrainingLevel: String, Sendable, Codable, CaseIterable, Identifiable {
    /// Kept preparing for the race. Reduced training maintains ~90% of
    /// aerobic fitness for weeks, so treat as essentially no loss.
    case keptTraining
    /// Some easy running, no structure.
    case someEasy
    /// A little, here and there.
    case occasional
    /// Almost nothing / completely stopped.
    case stopped

    var id: String { rawValue }
}

/// The plan adjustment a comeback warrants: how much to dampen volume and
/// for how many weeks to hold off hard quality (volume before intensity).
struct ComebackAdjustment: Sendable, Equatable {
    let fitnessChange: RecentFitnessChange
    let easyOnlyWeeks: Int

    static let none = ComebackAdjustment(fitnessChange: .none, easyOnlyWeeks: 0)
}

/// Derives a comeback plan adjustment from the questionnaire answer plus the
/// length of the break, the athlete's experience, and the race demands.
///
/// Grounded in detraining science: little/no training loses ~6% VO2max at 2
/// weeks, 8-20% by 4-9 weeks; beginners' base is fragile; returning athletes
/// should rebuild VOLUME before reintroducing INTENSITY. Maintaining even
/// reduced training preserves most fitness, so "kept training" needs ~no
/// adjustment.
enum ComebackAdjustmentCalculator {

    static func compute(
        gapLevel: GapTrainingLevel,
        weeksAway: Int,
        experience: ExperienceLevel,
        raceDistanceKm: Double,
        weeksUntilRace: Int
    ) -> ComebackAdjustment {
        // Kept training → fitness maintained, no dampening.
        guard gapLevel != .keptTraining else { return .none }

        // Base detraining severity (1 = minor … 3 = significant).
        var severity: Int
        switch gapLevel {
        case .keptTraining: severity = 0
        case .someEasy:     severity = 1
        case .occasional:   severity = 2
        case .stopped:      severity = 3
        }

        // Escalate / soften by how long the break was.
        switch weeksAway {
        case ..<2:   severity -= 1   // very short break, minimal loss
        case 2...4:  break
        case 5...8:  severity += 1
        default:     severity += 1   // 8+ weeks, deepest loss
        }
        severity = min(3, max(1, severity))

        let fitnessChange: RecentFitnessChange
        var easyOnlyWeeks: Int
        switch severity {
        case 1:  fitnessChange = .minor;       easyOnlyWeeks = 1
        case 2:  fitnessChange = .moderate;    easyOnlyWeeks = 2
        default: fitnessChange = .significant; easyOnlyWeeks = 3
        }

        // Beginners need a gentler, injury-safe ramp; elites regain fastest.
        switch experience {
        case .beginner:           easyOnlyWeeks += 1
        case .elite:              easyOnlyWeeks -= 1
        case .intermediate, .advanced: break
        }

        // Ultra distances live and die on the aerobic base, give it one more
        // easy week to rebuild before quality; short races (≤10K) sharpen
        // faster, so don't over-extend the easy block.
        if raceDistanceKm >= 60 {
            easyOnlyWeeks += 1
        } else if raceDistanceKm <= 10 {
            easyOnlyWeeks -= 1
        }

        // Never spend more than ~a third of the remaining prep easy-only, the
        // athlete still needs race-specific work before the start line.
        let cap = max(0, weeksUntilRace / 3)
        easyOnlyWeeks = min(max(0, easyOnlyWeeks), cap)

        return ComebackAdjustment(fitnessChange: fitnessChange, easyOnlyWeeks: easyOnlyWeeks)
    }
}
