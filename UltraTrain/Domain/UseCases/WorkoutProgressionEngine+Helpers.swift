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

    static func intervalFocusParams(
        _ focus: PhaseFocus,
        planProgress: Double
    ) -> FocusParams {
        switch focus {
        case .threshold30:
            FocusParams(
                setDurationSec: 60 + planProgress * 120,     // 1min → 3min
                intensity: .hard,
                workRestRatio: 1.0,                           // 1:1 rest
                maxReps: 15
            )
        case .vo2max:
            FocusParams(
                setDurationSec: 45 + planProgress * 75,      // 45s → 2min
                intensity: .hard,
                workRestRatio: 0.8,                           // 1:1.25 rest
                maxReps: 12
            )
        case .threshold60:
            FocusParams(
                setDurationSec: 240 + planProgress * 240,    // 4min → 8min
                intensity: .moderate,
                workRestRatio: 2.0,                           // 2:1 work:rest
                maxReps: 8
            )
        case .sharpening:
            FocusParams(
                setDurationSec: 120,
                intensity: .moderate,
                workRestRatio: 1.0,
                maxReps: 4
            )
        case .postRaceRecovery:
            FocusParams(
                setDurationSec: 180,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 5
            )
        }
    }

    static func vgFocusParams(
        _ focus: PhaseFocus,
        planProgress: Double
    ) -> FocusParams {
        switch focus {
        case .threshold30:
            FocusParams(
                setDurationSec: 120 + planProgress * 120,    // 2min → 4min climb (between VO2max & threshold60)
                intensity: .hard,
                workRestRatio: 1.0,                           // 1:1 rest (jog descent ≈ climb time)
                maxReps: 12
            )
        case .vo2max:
            FocusParams(
                setDurationSec: 90 + planProgress * 90,      // 1.5min → 3min steep
                intensity: .hard,
                workRestRatio: 0.75,                          // 1:1.33 rest (long descent)
                maxReps: 12
            )
        case .threshold60:
            FocusParams(
                setDurationSec: 300 + planProgress * 180,    // 5min → 8min sustained
                intensity: .moderate,
                workRestRatio: 1.5,
                maxReps: 8
            )
        case .sharpening:
            FocusParams(
                setDurationSec: 180,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 3
            )
        case .postRaceRecovery:
            FocusParams(
                setDurationSec: 240,
                intensity: .easy,
                workRestRatio: 1.0,
                maxReps: 2
            )
        }
    }

    // MARK: - Total Work Caps

    /// Maximum total set work (excluding warmup/cooldown/rest) per bloc type.
    /// 30'Threshold: runner can sustain this pace ~30min → sets ≤ 23min total
    /// 60'Threshold: runner can sustain this pace ~60min → sets ≤ 50min total
    static func maxTotalWorkSeconds(for focus: PhaseFocus) -> Double {
        switch focus {
        case .threshold30:      1380   // 23 minutes
        case .threshold60:      3000   // 50 minutes
        case .vo2max:           1200   // 20 minutes
        case .sharpening:       600    // 10 minutes
        case .postRaceRecovery: 900    // 15 minutes
        }
    }

    // MARK: - Scaling Factors

    static func intervalRaceScale(_ effectiveKm: Double) -> Double {
        let clamped = min(max(effectiveKm, 40), 250)
        return 0.65 + (clamped - 40) / (250 - 40) * 0.70
    }

    static func vgElevDensityFactor(elevationGainM: Double, effectiveKm: Double) -> Double {
        guard effectiveKm > 0 else { return 1.0 }
        let density = elevationGainM / effectiveKm
        let clamped = min(max(density, 20), 100)
        return 0.8 + (clamped - 20) / (100 - 20) * 0.5
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
        return "\(reps)×\(workText) \(zoneText) / \(restText) jog"
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
        return "\(reps)×\(workText) \(zoneText) / \(restText) jog down"
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
