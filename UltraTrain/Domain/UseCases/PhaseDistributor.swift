import Foundation

enum PhaseDistributor {

    struct PhaseAllocation: Equatable, Sendable {
        let phase: TrainingPhase
        let weekCount: Int
        let phaseFocus: PhaseFocus
    }

    /// Distributes weeks across 4 training phases using Campus Coach 5-block cycle:
    /// Seuil 30 (base) → VO2max (build) → Seuil 60 (peak) → Affûtage (taper)
    static func distribute(
        totalWeeks: Int,
        experience: ExperienceLevel,
        taperProfile: TaperProfile? = nil
    ) -> [PhaseAllocation] {
        guard totalWeeks >= 4 else {
            return [
                PhaseAllocation(phase: .base, weekCount: max(totalWeeks - 1, 1), phaseFocus: .threshold30),
                PhaseAllocation(phase: .taper, weekCount: 1, phaseFocus: .sharpening)
            ]
        }

        let fracs = focusFractions(for: experience)

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

    private static func focusFractions(for experience: ExperienceLevel) -> FocusFractions {
        switch experience {
        case .beginner:
            FocusFractions(threshold30: 0.25, vo2max: 0.15, threshold60: 0.35, sharpening: 0.25)
        case .intermediate:
            FocusFractions(threshold30: 0.18, vo2max: 0.15, threshold60: 0.44, sharpening: 0.23)
        case .advanced:
            FocusFractions(threshold30: 0.15, vo2max: 0.15, threshold60: 0.46, sharpening: 0.24)
        case .elite:
            FocusFractions(threshold30: 0.12, vo2max: 0.18, threshold60: 0.46, sharpening: 0.24)
        }
    }
}
