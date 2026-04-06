import Foundation

// MARK: - ProgressionContext

extension WorkoutProgressionEngine {

    struct ProgressionContext: Sendable {
        let raceEffectiveKm: Double
        let raceElevationGainM: Double
        let totalWeeks: Int
        let weekIndexInPlan: Int
        let experience: ExperienceLevel
        let philosophy: TrainingPhilosophy
    }

    // MARK: - Focus Parameters

    struct FocusParams {
        let setDurationSec: Double
        let intensity: Intensity
        let workRestRatio: Double
        let maxReps: Int
    }

    // MARK: - Interval Focus Parameters

    static func intervalFocusParams(
        _ focus: PhaseFocus,
        planProgress: Double,
        experience: ExperienceLevel = .intermediate
    ) -> FocusParams {
        switch focus {
        case .threshold30:
            let baseDuration: Double = 180
            let maxDuration: Double = experience == .advanced || experience == .elite ? 480 : 360
            return FocusParams(
                setDurationSec: baseDuration + planProgress * (maxDuration - baseDuration),
                intensity: .hard,
                workRestRatio: 2.5,                           // 2.5:1 work:rest (short recovery for threshold)
                maxReps: 8
            )
        case .vo2max:
            let maxDuration: Double = experience == .elite ? 180 : 150
            return FocusParams(
                setDurationSec: 45 + planProgress * (maxDuration - 45),
                intensity: .hard,
                workRestRatio: 0.8,                           // 1:1.25 rest
                maxReps: 14
            )
        case .threshold60:
            let maxDuration: Double = experience == .advanced || experience == .elite ? 720 : 480
            return FocusParams(
                setDurationSec: 240 + planProgress * (maxDuration - 240),
                intensity: .moderate,
                workRestRatio: 3.0,                           // 3:1 work:rest (minimal recovery)
                maxReps: 6
            )
        case .sharpening:
            return FocusParams(
                setDurationSec: 120,
                intensity: .moderate,
                workRestRatio: 1.0,
                maxReps: 4
            )
        case .postRaceRecovery:
            return FocusParams(
                setDurationSec: 180,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 5
            )
        }
    }

    // MARK: - VG Focus Parameters

    static func vgFocusParams(
        _ focus: PhaseFocus,
        planProgress: Double,
        experience: ExperienceLevel = .intermediate
    ) -> FocusParams {
        switch focus {
        case .threshold30:
            let maxDuration: Double = experience == .advanced || experience == .elite ? 420 : 360
            return FocusParams(
                setDurationSec: 180 + planProgress * (maxDuration - 180),
                intensity: .hard,
                workRestRatio: 1.0,                           // 1:1 (descent = climb time)
                maxReps: 10
            )
        case .vo2max:
            let maxDuration: Double = experience == .elite ? 240 : 180
            return FocusParams(
                setDurationSec: 90 + planProgress * (maxDuration - 90),
                intensity: .hard,
                workRestRatio: 0.75,                          // 1:1.33 (long descent)
                maxReps: 12
            )
        case .threshold60:
            let maxDuration: Double = experience == .advanced || experience == .elite ? 720 : 480
            return FocusParams(
                setDurationSec: 300 + planProgress * (maxDuration - 300),
                intensity: .moderate,
                workRestRatio: 1.5,
                maxReps: 6
            )
        case .sharpening:
            return FocusParams(
                setDurationSec: 180,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 3
            )
        case .postRaceRecovery:
            return FocusParams(
                setDurationSec: 240,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 2
            )
        }
    }

    // MARK: - Total Work Caps

    /// Maximum total set work (excluding warmup/cooldown/rest) per bloc type.
    static func maxTotalWorkSeconds(for focus: PhaseFocus) -> Double {
        switch focus {
        case .threshold30:      1380   // 23 minutes
        case .threshold60:      2400   // 40 minutes (reduced from 50)
        case .vo2max:           1200   // 20 minutes
        case .sharpening:       600    // 10 minutes
        case .postRaceRecovery: 900    // 15 minutes
        }
    }

    // MARK: - Scaling Factors

    /// Race distance scale: peaks around 80-120km effective, flattens for very long ultras.
    /// Longer ultras need more easy volume, not more intervals (Koop's 90/10 principle).
    static func intervalRaceScale(_ effectiveKm: Double) -> Double {
        let clamped = min(max(effectiveKm, 30), 300)
        if clamped <= 100 {
            // 30km→100km: scale from 0.70 to 1.05 (moderate increase)
            return 0.70 + (clamped - 30) / (100 - 30) * 0.35
        } else {
            // 100km→300km: scale from 1.05 down to 0.80 (less intensity for longer races)
            return 1.05 - (clamped - 100) / (300 - 100) * 0.25
        }
    }

    static func vgElevDensityFactor(elevationGainM: Double, effectiveKm: Double) -> Double {
        guard effectiveKm > 0 else { return 1.0 }
        let density = elevationGainM / effectiveKm
        let clamped = min(max(density, 15), 120)
        // Wider range: 0.7 for flat trails to 1.5 for vertical races
        return 0.7 + (clamped - 15) / (120 - 15) * 0.8
    }

    static func experienceFactor(_ experience: ExperienceLevel) -> Double {
        switch experience {
        case .beginner:     0.70
        case .intermediate: 0.85
        case .advanced:     1.00
        case .elite:        1.10
        }
    }

    static func philosophyFactor(_ philosophy: TrainingPhilosophy) -> Double {
        switch philosophy {
        case .enjoyment:    0.85
        case .balanced:     1.00
        case .performance:  1.12
        }
    }

    // MARK: - Progression Mode

    /// Returns the progression mode for a given week, phase-aware.
    /// Mode 2 (reduced rest) uses smaller reduction for VO2max to prevent quality degradation.
    static func progressionRestReduction(for focus: PhaseFocus) -> Double {
        switch focus {
        case .vo2max:       1.12  // Only 12% rest reduction (preserve VO2max quality)
        case .threshold30:  1.25  // 25% rest reduction
        case .threshold60:  1.30  // 30% rest reduction
        default:            1.20
        }
    }

    // MARK: - Description Formatters

    static func formatIntervalDescription(
        reps: Int,
        workSec: Double,
        restSec: Double,
        focus: PhaseFocus
    ) -> String {
        let workText = formatDuration(workSec)
        let restText = formatDuration(restSec)
        let zoneText = zoneLabel(for: focus)
        return "\(reps)\u{00D7}\(workText) \(zoneText) / \(restText) jog"
    }

    static func formatVGDescription(
        reps: Int,
        workSec: Double,
        restSec: Double,
        focus: PhaseFocus
    ) -> String {
        let workText = formatDuration(workSec)
        let restText = formatDuration(restSec)
        let zoneText = vgZoneLabel(for: focus)
        return "\(reps)\u{00D7}\(workText) \(zoneText) / \(restText) jog down"
    }

    // MARK: - Rounding

    static func roundToNearest15(_ seconds: Double) -> Double {
        guard seconds > 0 else { return 0 }
        return (seconds / 15.0).rounded() * 15.0
    }

    // MARK: - Private Helpers

    private static func formatDuration(_ seconds: Double) -> String {
        let totalSec = Int(seconds)
        let min = totalSec / 60
        let sec = totalSec % 60
        if sec == 0 {
            return "\(min)min"
        } else {
            return "\(min):\(String(format: "%02d", sec))"
        }
    }

    private static func zoneLabel(for focus: PhaseFocus) -> String {
        switch focus {
        case .threshold30:      "at threshold (Z3-4)"
        case .vo2max:           "at VO2max (Z4-5)"
        case .threshold60:      "at threshold (Z3)"
        case .sharpening:       "at threshold (Z3)"
        case .postRaceRecovery: "easy (Z2)"
        }
    }

    private static func vgZoneLabel(for focus: PhaseFocus) -> String {
        switch focus {
        case .threshold30:      "climb at threshold (Z3)"
        case .vo2max:           "steep climb at VO2max (Z4-5)"
        case .threshold60:      "climb at threshold (Z3-4)"
        case .sharpening:       "easy climb (Z2)"
        case .postRaceRecovery: "easy climb (Z2)"
        }
    }
}
