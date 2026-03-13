import Foundation

enum CoachAdviceGenerator {

    static func advice(
        for type: SessionType,
        intensity: Intensity,
        phase: TrainingPhase,
        verticalGainEnvironment: VerticalGainEnvironment = .mountain
    ) -> String? {
        switch type {
        case .rest:
            return String(localized: "coach.rest", defaultValue: "Active rest: foam roll, walk, stretch. Quality sleep tonight is your biggest performance gain.")

        case .recovery:
            return String(localized: "coach.recovery", defaultValue: "If in doubt, go slower. This run is about blood flow, not fitness gains.")

        case .crossTraining:
            return String(localized: "coach.crossTraining", defaultValue: "Keep it light and enjoyable. Different movement patterns help recovery and adaptation.")

        case .backToBack:
            return String(localized: "coach.backToBack", defaultValue: "Today you run on yesterday's fatigue. This is ultra-specific. Start easy and stay patient.")

        case .longRun:
            return longRunAdvice(intensity: intensity)

        case .tempo:
            return String(localized: "coach.tempo", defaultValue: "Find a rhythm you can hold for the whole session. If you can't finish a sentence, slow down slightly.")

        case .intervals:
            return String(localized: "coach.intervals", defaultValue: "Full recovery between reps matters more than speed. If form breaks down, stop the set.")

        case .verticalGain:
            return verticalGainAdvice(intensity: intensity, environment: verticalGainEnvironment)
        }
    }

    private static func longRunAdvice(intensity: Intensity) -> String {
        switch intensity {
        case .easy:
            return String(localized: "coach.longRun.easy", defaultValue: "Focus on time on feet, not pace. Walk uphills if needed — save your legs for the flats.")
        case .moderate:
            return String(localized: "coach.longRun.moderate", defaultValue: "Steady state run. Lock into a rhythm and practice your race nutrition strategy.")
        case .hard, .maxEffort:
            return String(localized: "coach.longRun.hard", defaultValue: "Push the pace on this one but stay controlled. Practice fueling at race effort.")
        }
    }

    private static func verticalGainAdvice(
        intensity: Intensity,
        environment: VerticalGainEnvironment
    ) -> String {
        switch environment {
        case .mountain:
            return String(localized: "coach.vg.mountain", defaultValue: "Find a trail with sustained climbing. Power hike the steepest sections — hands on thighs, short steps.")
        case .hill:
            return String(localized: "coach.vg.hill", defaultValue: "Find a hill with 3-5 min of sustained climbing. Focus on maintaining cadence and posture.")
        case .treadmill:
            return treadmillAdvice(intensity: intensity)
        case .mixed:
            return String(localized: "coach.vg.mixed", defaultValue: "Alternate outdoor hills and treadmill. Focus on consistent effort regardless of terrain.")
        }
    }

    private static func treadmillAdvice(intensity: Intensity) -> String {
        switch intensity {
        case .easy, .moderate:
            return String(localized: "coach.vg.treadmill.easy", defaultValue: "Set incline to 8-10%. Walk at a brisk pace. Reduce to 0% for recovery between reps.")
        case .hard:
            return String(localized: "coach.vg.treadmill.hard", defaultValue: "Set incline to 10-15%. Walk at a brisk pace. Reduce to 0% for recovery between reps.")
        case .maxEffort:
            return String(localized: "coach.vg.treadmill.max", defaultValue: "Set incline to 15%+. Maximum effort climbs. Full flat recovery between reps.")
        }
    }
}
