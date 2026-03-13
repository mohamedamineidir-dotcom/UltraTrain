import Foundation

enum PhaseDistributor {

    struct PhaseAllocation: Equatable, Sendable {
        let phase: TrainingPhase
        let weekCount: Int
    }

    static func distribute(totalWeeks: Int, experience: ExperienceLevel) -> [PhaseAllocation] {
        guard totalWeeks >= 4 else {
            return [PhaseAllocation(phase: .base, weekCount: max(totalWeeks - 1, 1)),
                    PhaseAllocation(phase: .taper, weekCount: 1)]
        }

        let fractions = fractions(for: experience)
        var baseWeeks = Int(round(Double(totalWeeks) * fractions.base))
        var buildWeeks = Int(round(Double(totalWeeks) * fractions.build))
        var peakWeeks = Int(round(Double(totalWeeks) * fractions.peak))
        var taperWeeks = Int(round(Double(totalWeeks) * fractions.taper))

        // Guarantee at least 1 week per phase
        baseWeeks = max(baseWeeks, 1)
        buildWeeks = max(buildWeeks, 1)
        peakWeeks = max(peakWeeks, 1)
        taperWeeks = max(taperWeeks, 1)

        // Adjust to match total — absorb difference into build (longest phase)
        let sum = baseWeeks + buildWeeks + peakWeeks + taperWeeks
        buildWeeks += (totalWeeks - sum)
        buildWeeks = max(buildWeeks, 1)

        return [
            PhaseAllocation(phase: .base, weekCount: baseWeeks),
            PhaseAllocation(phase: .build, weekCount: buildWeeks),
            PhaseAllocation(phase: .peak, weekCount: peakWeeks),
            PhaseAllocation(phase: .taper, weekCount: taperWeeks)
        ]
    }

    private struct Fractions {
        let base: Double
        let build: Double
        let peak: Double
        let taper: Double
    }

    private static func fractions(for experience: ExperienceLevel) -> Fractions {
        switch experience {
        case .beginner:
            Fractions(base: 0.30, build: 0.30, peak: 0.15, taper: 0.25)
        case .intermediate:
            Fractions(base: 0.25, build: 0.35, peak: 0.20, taper: 0.20)
        case .advanced:
            Fractions(base: 0.20, build: 0.40, peak: 0.20, taper: 0.20)
        case .elite:
            Fractions(base: 0.15, build: 0.45, peak: 0.20, taper: 0.20)
        }
    }
}
