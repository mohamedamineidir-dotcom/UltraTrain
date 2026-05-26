import Foundation

/// Surfaces structural mismatches between an athlete's A-race and the
/// B/A intermediate races scheduled before it. Pure analysis, never
/// mutates the plan, never auto-changes priorities. The athlete keeps
/// the choices they declared; this just names problems they may not
/// have spotted.
///
/// The headline case: a real-world athlete enters a 100K mountain
/// ultra (effective km ~160) as a B-race 5 weeks before their goal
/// road marathon (effective km ~42, target time 2h40). Recovery from
/// the ultra realistically takes 4-6 weeks, so the marathon goal is
/// structurally compromised before training even starts. The current
/// plan generator silently accepts this and produces a plan tuned for
/// the marathon, leaving the athlete to discover the problem in the
/// final taper or, worse, on race day.
enum PlanRaceCoherenceAnalyzer {

    /// Detects intermediate races that are more demanding than the
    /// target race AND fall within ~7 weeks of it (recovery-window
    /// problem). Each match emits a single recommendation.
    ///
    /// Both effective-km ratio and time-gap thresholds must trip for
    /// a recommendation to fire, a B-race that's harder but happens
    /// 12 weeks out is fine; a B-race the same size as A-race 4
    /// weeks out is fine. Only the combination is the problem.
    ///
    /// C-races are skipped (training races are meant to be hard
    /// efforts and the athlete already accepted the trade-off).
    /// Past races are skipped (advisory is forward-looking).
    static func detectIntermediateRaceMismatch(
        targetRace: Race,
        intermediateRaces: [Race],
        now: Date = .now
    ) -> [PlanAdjustmentRecommendation] {
        let targetEffective = targetRace.effectiveDistanceKm
        guard targetEffective > 0 else { return [] }

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        var recs: [PlanAdjustmentRecommendation] = []
        for bRace in intermediateRaces {
            // Only flag B-races + intermediate A-races. C-races are
            // training races by definition; the athlete picked them
            // as hard efforts and isn't expecting full recovery.
            switch bRace.priority {
            case .bRace, .aRace: break
            case .cRace: continue
            }

            // Forward-looking only: skip past races, skip races at or
            // after the target.
            guard bRace.date > now else { continue }
            guard bRace.date < targetRace.date else { continue }

            let bRaceEffective = bRace.effectiveDistanceKm
            let ratio = bRaceEffective / targetEffective
            let daysBetween = calendar.dateComponents(
                [.day], from: bRace.date, to: targetRace.date
            ).day ?? 0

            // Mismatch criteria:
            // - B-race ≥ 1.5× the effective km of A-race (meaningfully
            //   more demanding, same-size races don't trip this)
            // - AND falls within 50 days (~7 weeks) of A-race
            //   (recovery from a 1.5×-harder effort takes 4-6 weeks
            //   minimum; less than 7 weeks is the problem zone)
            guard ratio >= 1.5, daysBetween <= 50, daysBetween > 0 else { continue }

            let weeksBefore = max(daysBetween / 7, 1)
            let bDate = dateFormatter.string(from: bRace.date)
            let bEffStr = String(Int(bRaceEffective.rounded()))
            let tEffStr = String(Int(targetEffective.rounded()))

            recs.append(PlanAdjustmentRecommendation(
                id: UUID(),
                type: .bRaceMismatch,
                severity: .recommended,
                title: "B-race may compromise A-race goal",
                message: "Your B-race \(bRace.name) (\(bDate), ~\(bEffStr) effective km) is more demanding than your A-race \(targetRace.name) (~\(tEffStr) effective km), and falls only ~\(weeksBefore) weeks before. Recovery from an effort that size realistically takes 4-6 weeks, your A-race goal will likely be affected. Consider whether to swap A/B priority, set a more conservative A-race goal, or push the A-race further out.",
                actionLabel: "Got it",
                affectedSessionIds: []
            ))
        }
        return recs
    }
}
