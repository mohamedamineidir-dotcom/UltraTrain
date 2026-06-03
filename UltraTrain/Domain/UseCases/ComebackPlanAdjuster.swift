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
            for si in plan.weeks[wi].sessions.indices {
                let session = plan.weeks[wi].sessions[si]
                guard session.type == .intervals || session.type == .tempo,
                      !session.isCompleted, !session.isSkipped else { continue }

                var soft = session
                soft.type = .recovery
                soft.intensity = .easy
                soft.intervalWorkoutId = nil
                soft.intervalFocus = nil
                soft.targetHeartRateZone = 2
                // Keep planned duration / distance, volume is retained, only
                // the intensity is dialled back.
                soft.description = "Easy aerobic run. Rebuilding your base before quality returns."
                soft.coachAdvice = "Back from a break, base before intensity. Keep this fully easy and conversational; the hard sessions come back once you've strung together a few consistent weeks."
                plan.weeks[wi].sessions[si] = soft
            }
        }
    }
}
