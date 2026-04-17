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
        paceProfile: RoadPaceProfile?,
        raceName: String? = nil,
        experience: ExperienceLevel = .intermediate
    ) -> String? {
        if isRecoveryWeek {
            return recoveryWeekAdvice(type: type)
        }

        var advice: String?
        switch type {
        case .recovery:
            advice = easyRunAdvice(phase: phase, paceProfile: paceProfile)
        case .intervals:
            advice = intervalAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .tempo:
            advice = tempoAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .longRun:
            advice = longRunAdvice(phase: phase, discipline: discipline, paceProfile: paceProfile)
        case .rest:
            advice = "Rest is where adaptation happens. Trust the process."
        default:
            break
        }

        // Issue #9: Goal realism warning for ambitious athletes
        if let realism = paceProfile?.goalRealismLevel, realism != .realistic, phase == .base || phase == .build {
            let warning = realism == .veryAmbitious
                ? " Note: your goal is very ambitious vs current fitness. All paces are based on your current ability — we'll introduce goal pace only in late peak."
                : " Note: your goal is ambitious. Training paces are based on current fitness to build safely toward race day."
            advice = (advice ?? "") + warning
        }

        return advice
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
        var advice = "Warm-up: 10-15min easy jog + 4-6 strides."
        switch phase {
        case .base:
            advice += " Speed strides and short reps. Focus on form and leg turnover, not raw speed."
        case .build:
            advice += " VO2max session. Run the intervals at a controlled hard effort — working hard but not sprinting."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.intervalPacePerKm))/km."
            }
        case .peak:
            advice += " Race-specific work. This is your \(discipline.displayName) pace — memorize how it feels."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice += " Light speed work to stay sharp."
        }
        advice += " Cool-down: 5-10min easy jog."
        return advice
    }

    private static func tempoAdvice(
        phase: TrainingPhase,
        discipline: RoadRaceDiscipline,
        paceProfile: RoadPaceProfile?
    ) -> String {
        var advice = "Warm-up: 10min easy jog + 4 strides."
        switch phase {
        case .base, .build:
            advice += " Threshold pace: comfortably hard. Speak in short phrases but not a conversation."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.thresholdPacePerKm))/km."
            }
        case .peak:
            advice += " Race-pace threshold work. Sustain your target \(discipline.displayName) pace with control."
            if let profile = paceProfile {
                advice += " Target: \(formatPace(profile.racePacePerKm))/km."
            }
        default:
            advice += " Easy tempo to maintain feel."
        }
        advice += " Cool-down: 5-10min easy jog."
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
