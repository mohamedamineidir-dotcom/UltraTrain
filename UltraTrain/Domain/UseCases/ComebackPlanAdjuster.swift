import Foundation

/// Applies the comeback "volume before intensity" window to a freshly
/// generated plan: for the first N upcoming weeks, hard quality sessions
/// (intervals / tempo) are softened to easy aerobic runs of the SAME
/// duration, so a returning athlete rebuilds an aerobic base before
/// intensity resumes. Volume is preserved; only the intensity is pulled
/// back. Past / completed sessions are left untouched.
///
/// Runs as a post-pass after generation (the generator already dampens
/// VOLUME via `RecentFitnessChange`), so the core generation logic stays
/// unchanged.
enum ComebackPlanAdjuster {

    static func softenEarlyQuality(in plan: inout TrainingPlan, easyOnlyWeeks: Int) {
        guard easyOnlyWeeks > 0 else { return }
        let start = max(plan.currentWeekIndex ?? 0, 0)
        let end = min(start + easyOnlyWeeks, plan.weeks.count)
        guard start < end else { return }

        for wi in start..<end {
            // Ramp the long run back in gradually: the longer the easy-only
            // block, the more the FIRST long runs are trimmed (most injuries
            // on return come from jumping straight back into a big long run).
            // Earliest week is cut most, easing back to full by the end.
            let weekOffset = wi - start
            let longRunFactor = longRunRampFactor(weekOffset: weekOffset, totalEasyWeeks: easyOnlyWeeks)

            for si in plan.weeks[wi].sessions.indices {
                let session = plan.weeks[wi].sessions[si]
                guard !session.isCompleted, !session.isSkipped else { continue }

                switch session.type {
                case .intervals, .tempo:
                    var soft = session
                    soft.type = .recovery
                    soft.intensity = .easy
                    soft.intervalWorkoutId = nil
                    soft.intervalFocus = nil
                    soft.targetHeartRateZone = 2
                    // Keep planned duration / distance, volume is retained,
                    // only the intensity is dialled back.
                    soft.description = "Easy aerobic run. Rebuilding your base before quality returns."
                    soft.coachAdvice = "Back from a break, base before intensity. Keep this fully easy and conversational; the hard sessions come back once you've strung together a few consistent weeks."
                    plan.weeks[wi].sessions[si] = soft

                case .longRun, .backToBack:
                    guard longRunFactor < 1.0 else { continue }
                    var capped = session
                    capped.plannedDuration *= longRunFactor
                    capped.plannedDistanceKm *= longRunFactor
                    capped.plannedElevationGainM *= longRunFactor
                    capped.coachAdvice = "Easing the long run back in after your break, build it up gradually. Keep the effort easy; run/walk if you need to."
                    plan.weeks[wi].sessions[si] = capped

                default:
                    continue
                }
            }
        }
    }

    /// How much of the planned long run to keep in a given easy-only week.
    /// First week back is trimmed most; ramps linearly to full by the last
    /// easy-only week, so the long run rebuilds rather than spiking.
    private static func longRunRampFactor(weekOffset: Int, totalEasyWeeks: Int) -> Double {
        guard totalEasyWeeks > 1 else { return 0.7 }
        // 0.6 on the first week → 1.0 on the last easy-only week.
        let t = Double(weekOffset) / Double(totalEasyWeeks - 1)
        return min(1.0, 0.6 + 0.4 * t)
    }
}
