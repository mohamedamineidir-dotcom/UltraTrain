import Foundation

/// Research-backed sex-specific coaching notes, appended to per-session
/// coach advice. Phase 1: surface via advice only — the plan structure
/// itself (periodisation, volume) stays sex-blind. Deeper integration
/// (menstrual-cycle-aware carb timing, etc.) is out of scope until we
/// capture cycle data.
///
/// Research basis:
///   • Sims 2016 — "Roar". Female endurance athletes benefit from
///     higher carb intake (especially luteal phase), higher iron
///     surveillance, and individualised approach to hydration/sodium.
///   • Stachenfeld — women are at higher risk of ACL injury,
///     especially on descents; hip-knee biomechanics (Q-angle) +
///     hormonal modulation of ligament laxity.
///   • Mountjoy 2014 (RED-S, IOC position stand) — low energy
///     availability risks bone health, hormones, and performance in
///     both sexes but presents earlier / more frequently in female
///     athletes during heavy training.
///
/// The helper returns nil when no sex-specific note applies to the
/// given context. Callers simply append the result (prefixed with a
/// space) to their existing advice when non-nil.
enum SexSpecificAdviceHelper {

    /// Returns a sex-specific note appended to the per-session coach
    /// advice, or nil when none applies. Keeps the volume of notes
    /// low — surfaces one per session max, no spam.
    static func note(
        biologicalSex: BiologicalSex,
        sessionType: SessionType,
        phase: TrainingPhase,
        isRecoveryWeek: Bool,
        isRaceWeek: Bool = false
    ) -> String? {
        // Phase 1: only female-athlete notes. Male-athlete programming
        // deltas are smaller and we don't have enough high-confidence
        // research to justify adding copy that might read as tokenism.
        guard biologicalSex == .female else { return nil }

        // Recovery weeks: no extra noise — the advice already reminds
        // the athlete to ease off.
        if isRecoveryWeek { return nil }

        // Race-week prompts override everything — bone health / RED-S
        // reminder lands once, where it matters most.
        if isRaceWeek {
            return redSNote
        }

        switch sessionType {
        case .longRun, .backToBack:
            // Long efforts are the primary place CHO/fueling advice
            // lands. Sims' luteal-phase carb recommendations apply
            // universally to long efforts even without cycle tracking.
            return fuellingNote
        case .intervals, .tempo:
            // Quality sessions in peak/build = high metabolic stress.
            // Iron surveillance matters most here.
            if phase == .peak || phase == .build {
                return ironNote
            }
            return nil
        case .verticalGain:
            // Stachenfeld's descent-injury research: Q-angle + ACL
            // biomechanics elevate risk especially on downhills.
            return descentInjuryNote
        default:
            return nil
        }
    }

    // MARK: - Copy (short, coach-voice, no em-dashes)

    private static let fuellingNote =
        "Note for female athletes: research (Sims 2016) suggests higher carb demand on long efforts, especially through the luteal phase. Fuel generously — 30-60 g carbs per hour, starting before you feel you need it."

    private static let ironNote =
        "Note for female athletes: high-intensity blocks raise iron turnover. If you're trending tired beyond what training explains, a ferritin check is worth it. Target 15-18 mg/day through diet or supplementation (Sims 2016)."

    private static let redSNote =
        "Note for female athletes: through heavy training weeks, watch energy availability. Under-fuelling risks bone health and hormonal balance (RED-S, Mountjoy 2014). Eat to support the load, not to control weight."

    private static let descentInjuryNote =
        "Note for female athletes: descent-running carries higher ACL/knee load for women due to Q-angle and quad-hamstring ratio (Stachenfeld). Keep descents controlled, strong cadence, soft landings."
}
