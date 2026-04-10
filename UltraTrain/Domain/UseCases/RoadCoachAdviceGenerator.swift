import Foundation

/// Generates road-specific coach advice and session descriptions.
///
/// Key difference from trail advice: references paces in min/km, uses
/// road-specific terminology (tempo, threshold, VO2max intervals),
/// no trail/hiking/elevation language.
enum RoadCoachAdviceGenerator {

    /// Generates coach advice for a road training session.
    static func advice(
        type: SessionType,
        intensity: Intensity,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        isRecoveryWeek: Bool,
        paceProfile: RoadPaceProfile?
    ) -> String? {
        if isRecoveryWeek {
            return recoveryWeekAdvice(type: type)
        }

        switch type {
        case .recovery:
            return easyRunAdvice(phase: phase, paceProfile: paceProfile)
        case .intervals:
            return intervalAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .tempo:
            return tempoAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .longRun:
            return longRunAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .rest:
            return "Rest is where adaptation happens. Trust the process."
        default:
            return nil
        }
    }

    /// Generates a road-specific session description.
    static func sessionDescription(
        type: SessionType,
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        isRecoveryWeek: Bool
    ) -> String {
        if isRecoveryWeek {
            return type == .longRun
                ? "Easy long run — shorter this week. Recovery is king."
                : "Easy run. Recovery week — protect your adaptation."
        }

        switch (type, phase) {
        case (.intervals, .base):
            return "Speed development. Short fast reps to build running economy."
        case (.intervals, .build):
            return "VO2max intervals. Build your aerobic ceiling for \(discipline.displayName) performance."
        case (.intervals, .peak):
            return "Race-specific intervals. Lock in your \(discipline.displayName) rhythm."
        case (.tempo, .base):
            return "Threshold introduction. Comfortably hard — you should be able to speak in short phrases."
        case (.tempo, .build):
            return "Lactate threshold development. The cornerstone of \(discipline.displayName) performance."
        case (.tempo, .peak):
            return "Race-pace threshold work. Sharpen your ability to sustain target pace."
        case (.longRun, .base):
            return "Aerobic long run. Easy pace throughout — build your endurance foundation."
        case (.longRun, .build):
            return "Structured long run. Building toward race-specific endurance."
        case (.longRun, .peak):
            return "Race-specific long run. Practice pacing, fueling, and mental focus."
        case (.longRun, .taper):
            return "Reduced long run. Maintain feel without fatigue."
        default:
            return "Easy run at conversational pace."
        }
    }

    // MARK: - Specific Advice

    private static func easyRunAdvice(phase: TrainingPhase, paceProfile: RoadPaceProfile?) -> String {
        var advice = "Keep it truly easy — conversational pace."
        if let profile = paceProfile {
            let slowPace = formatPace(profile.easyPacePerKm.upperBound)
            let fastPace = formatPace(profile.easyPacePerKm.lowerBound)
            advice += " Target: \(fastPace)-\(slowPace)/km."
        }
        advice += " This is where your aerobic engine grows. Resist the urge to push."
        return advice
    }

    private static func intervalAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        var advice: String
        switch phase {
        case .base:
            advice = "Speed strides and short reps today. Focus on form and leg turnover, not raw speed."
        case .build:
            advice = "VO2max session. Run the work intervals at a controlled hard effort — you should feel like you're working but not sprinting."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.intervalPacePerKm))/km."
            }
        case .peak:
            advice = "Race-specific work. This is your \(discipline.displayName) pace — memorize how it feels."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice = "Light speed work to stay sharp."
        }
        return advice
    }

    private static func tempoAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        var advice: String
        switch phase {
        case .base, .build:
            advice = "Threshold pace: comfortably hard. You can speak in short phrases but not hold a conversation."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.thresholdPacePerKm))/km."
            }
        case .peak:
            advice = "Race-pace threshold work. Sustain your target \(discipline.displayName) pace with control."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice = "Easy tempo to maintain feel."
        }
        return advice
    }

    private static func longRunAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        switch phase {
        case .base:
            var advice = "Easy long run. The goal is time on feet, not pace."
            if let profile = paceProfile {
                advice += " Stay in the \(formatPace(profile.easyPacePerKm.lowerBound))-\(formatPace(profile.easyPacePerKm.upperBound))/km range."
            }
            return advice
        case .build:
            return "Structured long run. Start easy and build into a moderate effort in the second half. Practice your race-day nutrition."
        case .peak:
            if discipline == .roadMarathon {
                return "Marathon-specific long run. Include blocks at marathon pace. This is your dress rehearsal — practice everything: pacing, fueling, gear."
            }
            return "Race-specific long run. Include a faster segment at race pace. Practice your race-day routine."
        default:
            return "Easy long run to maintain aerobic fitness."
        }
    }

    private static func recoveryWeekAdvice(type: SessionType) -> String {
        switch type {
        case .longRun:
            "Shorter long run this week. Your body is absorbing recent training — let it work."
        case .recovery:
            "Easy effort. Recovery weeks are when you get stronger. Trust the process."
        default:
            "Recovery week. Keep it easy."
        }
    }

    // MARK: - Formatting

    /// Formats pace in seconds/km to "M:SS" string.
    static func formatPace(_ secondsPerKm: Double) -> String {
        let mins = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
