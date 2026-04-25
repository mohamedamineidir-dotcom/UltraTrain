import Foundation

enum PhaseDistributor {

    struct PhaseAllocation: Equatable, Sendable {
        let phase: TrainingPhase
        let weekCount: Int
        let phaseFocus: PhaseFocus
    }

    /// Distributes weeks across 4 training phases using Campus Coach 5-block cycle:
    /// Seuil 30 (base) → VO2max (build) → Seuil 60 (peak) → Affûtage (taper)
    ///
    /// - Parameter raceEffectiveKm: race effective distance (km + D+/100).
    ///   100K+ races shift +5% from base into peak — the longer the race,
    ///   the more cumulative race-specific work the athlete needs (a
    ///   100-mile plan and a 50K plan should not have identical phase
    ///   weighting for the same experience tier). Floors at 18% base for
    ///   elites so even pros coming off recovery still rebuild aerobic
    ///   foundation before peak.
    static func distribute(
        totalWeeks: Int,
        experience: ExperienceLevel,
        taperProfile: TaperProfile? = nil,
        raceEffectiveKm: Double = 0
    ) -> [PhaseAllocation] {
        guard totalWeeks >= 4 else {
            return [
                PhaseAllocation(phase: .base, weekCount: max(totalWeeks - 1, 1), phaseFocus: .threshold30),
                PhaseAllocation(phase: .taper, weekCount: 1, phaseFocus: .sharpening)
            ]
        }

        let fracs = focusFractions(for: experience, raceEffectiveKm: raceEffectiveKm)

        if let profile = taperProfile {
            // Race-aware taper: use profile's week count
            // For short plans (<8 weeks), cap taper at 2 weeks
            let maxTaper = totalWeeks < 8 ? 2 : totalWeeks / 2
            let sharp = min(profile.totalTaperWeeks, maxTaper)
            let remaining = totalWeeks - sharp

            // Adaptive build phase fraction based on plan length
            let adaptiveBuildFrac = VolumeCapCalculator.buildPhaseFraction(totalWeeks: totalWeeks)
            let adjustedT30 = fracs.threshold30
            let adjustedVO2 = adaptiveBuildFrac
            let adjustedT60 = 1.0 - adjustedT30 - adjustedVO2
            let nonTaperSum = adjustedT30 + adjustedVO2 + adjustedT60

            let t30 = max(Int(round(Double(remaining) * adjustedT30 / nonTaperSum)), 1)
            let vo2 = max(Int(round(Double(remaining) * adjustedVO2 / nonTaperSum)), 1)
            let t60 = max(remaining - t30 - vo2, 1)

            return [
                PhaseAllocation(phase: .base, weekCount: t30, phaseFocus: .threshold30),
                PhaseAllocation(phase: .build, weekCount: vo2, phaseFocus: .vo2max),
                PhaseAllocation(phase: .peak, weekCount: t60, phaseFocus: .threshold60),
                PhaseAllocation(phase: .taper, weekCount: sharp, phaseFocus: .sharpening)
            ]
        }

        // Legacy behavior when no taper profile
        let t30 = max(Int(round(Double(totalWeeks) * fracs.threshold30)), 1)
        let vo2 = max(Int(round(Double(totalWeeks) * fracs.vo2max)), 1)
        var t60 = max(Int(round(Double(totalWeeks) * fracs.threshold60)), 1)
        let sharp = max(Int(round(Double(totalWeeks) * fracs.sharpening)), 1)

        // Absorb rounding difference into threshold60 (longest block)
        let sum = t30 + vo2 + t60 + sharp
        t60 += (totalWeeks - sum)
        t60 = max(t60, 1)

        return [
            PhaseAllocation(phase: .base, weekCount: t30, phaseFocus: .threshold30),
            PhaseAllocation(phase: .build, weekCount: vo2, phaseFocus: .vo2max),
            PhaseAllocation(phase: .peak, weekCount: t60, phaseFocus: .threshold60),
            PhaseAllocation(phase: .taper, weekCount: sharp, phaseFocus: .sharpening)
        ]
    }

    // MARK: - Focus Fractions

    private struct FocusFractions {
        let threshold30: Double
        let vo2max: Double
        let threshold60: Double
        let sharpening: Double
    }

    private static func focusFractions(
        for experience: ExperienceLevel,
        raceEffectiveKm: Double = 0
    ) -> FocusFractions {
        let base: FocusFractions
        switch experience {
        case .beginner:
            base = FocusFractions(threshold30: 0.25, vo2max: 0.15, threshold60: 0.35, sharpening: 0.25)
        case .intermediate:
            base = FocusFractions(threshold30: 0.18, vo2max: 0.15, threshold60: 0.44, sharpening: 0.23)
        case .advanced:
            base = FocusFractions(threshold30: 0.15, vo2max: 0.15, threshold60: 0.46, sharpening: 0.24)
        case .elite:
            // Elite base floor at 18%. The previous 12% assumed elites came
            // in with bulletproof aerobic foundation — fine in steady-state
            // training, dangerous after a recovery period or coming back
            // from injury. 18% is enough to rebuild without robbing peak.
            base = FocusFractions(threshold30: 0.18, vo2max: 0.18, threshold60: 0.40, sharpening: 0.24)
        }

        // 100K+ shift: move 5% from base → peak. Longer races demand more
        // accumulated race-specific work; a 100-mile plan should not have
        // the same peak weight as a 50K plan for the same athlete.
        // Triggered by race effective km (km + D+/100), so a 60K with
        // 4000m D+ also benefits.
        guard raceEffectiveKm >= 100 else { return base }
        let shift = 0.05
        let shiftedT30 = max(base.threshold30 - shift, 0.05)
        let actualShift = base.threshold30 - shiftedT30
        return FocusFractions(
            threshold30: shiftedT30,
            vo2max: base.vo2max,
            threshold60: base.threshold60 + actualShift,
            sharpening: base.sharpening
        )
    }
}
