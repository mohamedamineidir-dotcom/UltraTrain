import Foundation

/// Generates the athlete's race-week fuelling protocol: per-day carb
/// targets, sodium loading, hydration, and the pre-race morning meal.
///
/// Research basis:
///   • Burke 2011 — "Competition fuelling for athletes". Classic
///     8-12 g/kg/day carb load in the 1-3 days before endurance
///     events ≥ 90 min. Short events (<90 min) don't benefit from
///     loading; baseline high-carb diet suffices.
///   • ACSM / AND / DC Joint Position Stand 2016 — 6-12 g/kg/day
///     across endurance training; upper end for race week.
///   • ISSN 2017 Jeukendrup — 1-4 g/kg of carb 1-4h pre-race; 60-90
///     g/hr during races ≥ 2h.
///   • Sodium: general recommendation +500-800 mg/day during
///     carb-loading phase to offset fluid-shifting from increased
///     glycogen storage (glycogen binds 3g water per gram).
///
/// The protocol adapts by race duration tier:
///   • < 90 min   → no multi-day loading; just pre-race meal
///   • 90-180 min → 1 day of focused loading at 8 g/kg
///   • 180-300 min → 2 days at 9 g/kg (marathon range)
///   • > 300 min  → 3 days at 10 g/kg (ultra range)
enum RaceFuellingProtocolGenerator {

    struct FuellingPlan: Equatable, Sendable {
        /// Individual phases of the loading run-up. Empty for
        /// short-race cases (< 90 min), in which only `morning`,
        /// `during`, and footer are shown.
        let loadingPhases: [Phase]
        let morning: Phase
        let during: String
        /// Short one-liner explaining why this protocol was chosen,
        /// surfaced in the card header so the athlete knows the
        /// reasoning.
        let rationale: String
    }

    struct Phase: Equatable, Sendable {
        let title: String
        let carbsGrams: Int
        /// Carbs per kg of body weight (shown in parentheses for
        /// athletes who think in g/kg).
        let carbsPerKg: Double
        /// Secondary detail line, e.g. "Reduce fibre; familiar foods
        /// only" or "+800 mg sodium".
        let detail: String
    }

    /// Builds a protocol from the athlete's weight and the race's
    /// estimated duration. Returns nil when the athlete has no
    /// recorded weight — the UI should gracefully hide the card in
    /// that case rather than show carb counts derived from fallback
    /// defaults.
    static func build(
        athleteWeightKg: Double,
        estimatedRaceDurationSeconds: TimeInterval,
        preRaceMealTiming: PreRaceMealTiming? = nil
    ) -> FuellingPlan? {
        guard athleteWeightKg > 0 else { return nil }
        let weight = athleteWeightKg
        let raceMinutes = estimatedRaceDurationSeconds / 60

        // Pre-race morning meal. Jeukendrup ISSN 2017 recommends
        // 1-4 g/kg of carb 1-4h before a race — the window is wide
        // because tight timing (1h) means less food, low fibre,
        // mostly liquid; long windows (4h) allow a full meal. When
        // the athlete has told us their preferred timing, we tune
        // both the carb dose and the phase copy to match. Default
        // (no timing captured) stays on the safe 3h / 3 g/kg anchor.
        let morning = morningPhase(
            timing: preRaceMealTiming,
            weightKg: weight
        )

        let during: String
        if raceMinutes >= 60 {
            let low = raceMinutes >= 120 ? 60 : 30
            let high = raceMinutes >= 120 ? 90 : 60
            during = "During: \(low)-\(high) g carbs/hr. 400-600 ml fluid/hr with 500-700 mg sodium/hr (warm weather upper end)."
        } else {
            during = "During: a few sips of water, no carbs needed for a race this short."
        }

        // Short races: no multi-day load. Just the pre-race meal and
        // baseline high-carb eating the night before.
        guard raceMinutes >= 90 else {
            return FuellingPlan(
                loadingPhases: [],
                morning: morning,
                during: during,
                rationale: "Race duration is under 90 min, so a multi-day carb load isn't needed — normal high-carb eating plus the pre-race meal is enough."
            )
        }

        // 90-180 min: 1 day of focused loading.
        if raceMinutes < 180 {
            let phases = [
                Phase(
                    title: "Day before",
                    carbsGrams: Int((weight * 8.0).rounded()),
                    carbsPerKg: 8.0,
                    detail: "Carb-focused meals, low fibre, familiar foods. Light pasta/rice dinner. Extra 500 mg sodium across the day."
                )
            ]
            return FuellingPlan(
                loadingPhases: phases,
                morning: morning,
                during: during,
                rationale: "A 90-180 min race benefits from 1 day of focused carb-loading at ~8 g/kg — enough to top up glycogen without overloading."
            )
        }

        // 180-300 min (marathon range): 2 days at 9 g/kg.
        if raceMinutes < 300 {
            let phases = [
                Phase(
                    title: "2 days out",
                    carbsGrams: Int((weight * 8.0).rounded()),
                    carbsPerKg: 8.0,
                    detail: "Start carb-focused eating. Reduce fibre and fat. Regular small meals beat one big plate."
                ),
                Phase(
                    title: "Day before",
                    carbsGrams: Int((weight * 9.0).rounded()),
                    carbsPerKg: 9.0,
                    detail: "Peak load. Low fibre, familiar foods. +800 mg sodium. Light pasta/rice dinner — done eating by 20:00."
                )
            ]
            return FuellingPlan(
                loadingPhases: phases,
                morning: morning,
                during: during,
                rationale: "For a 3-5 hr race, 2 days of loading at 8-9 g/kg maximises glycogen stores — classic marathon protocol (Burke 2011)."
            )
        }

        // > 300 min (ultra): 3 days at 10 g/kg.
        let phases = [
            Phase(
                title: "3 days out",
                carbsGrams: Int((weight * 8.0).rounded()),
                carbsPerKg: 8.0,
                detail: "Begin the load. Shift plate composition toward carbs — rice, pasta, bread, potatoes, fruit. Reduce fibre."
            ),
            Phase(
                title: "2 days out",
                carbsGrams: Int((weight * 9.0).rounded()),
                carbsPerKg: 9.0,
                detail: "Keep loading, keep hydration up. Regular small meals. +500 mg sodium/day."
            ),
            Phase(
                title: "Day before",
                carbsGrams: Int((weight * 10.0).rounded()),
                carbsPerKg: 10.0,
                detail: "Peak. Familiar low-fibre foods only. +800 mg sodium. Early dinner, early bed."
            )
        ]
        return FuellingPlan(
            loadingPhases: phases,
            morning: morning,
            during: during,
            rationale: "For an ultra-endurance race, a full 3-day load at 8-10 g/kg/day is worth it — you'll burn through stored glycogen inside the first 2-3 hours."
        )
    }

    /// Builds the pre-race meal phase, tuning carbs-per-kg and copy
    /// to the athlete's chosen pre-race timing. Research basis:
    /// Jeukendrup ISSN 2017 — 1 g/kg at 1h, 2 g/kg at 2h, 3 g/kg at
    /// 3h, 4 g/kg at 4h. Defaults to 3h when timing is unknown.
    private static func morningPhase(
        timing: PreRaceMealTiming?,
        weightKg: Double
    ) -> Phase {
        let resolved = timing ?? .threeHours
        let carbsPerKg: Double
        let detail: String
        let title: String
        switch resolved {
        case .oneHour:
            carbsPerKg = 1.0
            title = "Race morning (1h before)"
            detail = "Tight window: keep it small and liquid-leaning. Half a banana + honey, or 300 ml sports drink + a slice of toast. Skip fibre, fat, and protein — no room for digestion."
        case .twoHours:
            carbsPerKg = 2.0
            title = "Race morning (2h before)"
            detail = "Moderate carb meal: oatmeal with honey + banana, or a bagel with jam. 400 ml water + electrolytes. Low fibre, familiar foods only."
        case .threeHours:
            carbsPerKg = 3.0
            title = "Race morning (3h before)"
            detail = "Full carb meal: bagel + honey + jam + banana, oatmeal with maple syrup, or white toast with jam. 500 ml water + electrolytes. No fibre or fat."
        case .fourHours:
            carbsPerKg = 4.0
            title = "Race morning (4h before)"
            detail = "Full meal with time to digest: bagels + peanut butter + honey, or rice with honey + scrambled egg white. 500 ml water + electrolytes. Back to bed afterwards is fine."
        }
        return Phase(
            title: title,
            carbsGrams: Int((weightKg * carbsPerKg).rounded()),
            carbsPerKg: carbsPerKg,
            detail: detail
        )
    }
}
