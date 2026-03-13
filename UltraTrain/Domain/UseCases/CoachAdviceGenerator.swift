import Foundation

enum CoachAdviceGenerator {

    static func advice(
        for type: SessionType,
        intensity: Intensity,
        phase: TrainingPhase,
        weekInPhase: Int = 0,
        isB2BDay2: Bool = false,
        isRecoveryWeek: Bool = false,
        verticalGainEnvironment: VerticalGainEnvironment = .mountain
    ) -> String? {
        // Recovery week prefix for all session types
        let recoveryPrefix = isRecoveryWeek
            ? "Recovery week — keep all efforts easy. Adaptation happens during rest. "
            : ""

        let baseAdvice: String?
        switch type {
        case .rest:
            baseAdvice = restAdvice(phase: phase, isRecoveryWeek: isRecoveryWeek)
        case .recovery:
            baseAdvice = recoveryRunAdvice(phase: phase)
        case .crossTraining:
            baseAdvice = "Keep it light and enjoyable. Different movement patterns help recovery and adaptation."
        case .backToBack:
            baseAdvice = b2bAdvice(phase: phase, isDay2: isB2BDay2)
        case .longRun:
            baseAdvice = longRunAdvice(phase: phase, intensity: intensity, weekInPhase: weekInPhase)
        case .tempo:
            baseAdvice = tempoAdvice(phase: phase)
        case .intervals:
            baseAdvice = intervalAdvice(phase: phase, weekInPhase: weekInPhase)
        case .verticalGain:
            baseAdvice = verticalGainAdvice(phase: phase, intensity: intensity, environment: verticalGainEnvironment)
        }

        guard let advice = baseAdvice else { return nil }
        return isRecoveryWeek && type != .rest ? recoveryPrefix + advice : advice
    }

    // MARK: - Rest

    private static func restAdvice(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Recovery week rest. Your body is absorbing training. Focus on sleep quality, nutrition, and gentle stretching."
        }
        switch phase {
        case .taper:
            return "Taper rest day. Trust your training. Light walking and foam rolling. No guilt about not running."
        default:
            return "Active rest: foam roll, walk, stretch. Quality sleep tonight is your biggest performance gain."
        }
    }

    // MARK: - Recovery Run

    private static func recoveryRunAdvice(phase: TrainingPhase) -> String {
        switch phase {
        case .taper:
            return "Short easy jog to keep legs fresh. If anything feels off, cut it short. You're tapering for a reason."
        default:
            return "If in doubt, go slower. This run is about blood flow, not fitness gains. Conversational pace only."
        }
    }

    // MARK: - Long Run (Phase-Aware)

    private static func longRunAdvice(phase: TrainingPhase, intensity: Intensity, weekInPhase: Int) -> String {
        switch phase {
        case .base:
            if weekInPhase < 3 {
                return "Build your aerobic base. Focus purely on time on feet — walk all uphills, no pace pressure. This is foundation work."
            }
            return "Long aerobic run. Maintain easy effort throughout. Practice walking technical terrain. Building your engine."
        case .build:
            if weekInPhase < 4 {
                return "Long run with building effort. Start easy, include 15-20min at race effort in the second half. Practice nutrition every 30-40min."
            }
            return "Long run with race-effort blocks. Include 20-30min at goal pace mid-run. Eat and drink on schedule — this is a dress rehearsal."
        case .peak:
            return "Race simulation run. Start easy for 30min, then run extended sections at race effort. Practice your entire fueling plan. Wear race gear."
        case .taper:
            return "Short easy long run. Trust your fitness — the hay is in the barn. Easy effort, enjoy the trail."
        default:
            return longRunByIntensity(intensity)
        }
    }

    private static func longRunByIntensity(_ intensity: Intensity) -> String {
        switch intensity {
        case .easy:
            return "Focus on time on feet, not pace. Walk uphills if needed — save your legs for the flats."
        case .moderate:
            return "Steady state run. Lock into a rhythm and practice your race nutrition strategy."
        case .hard, .maxEffort:
            return "Push the pace on this one but stay controlled. Practice fueling at race effort."
        }
    }

    // MARK: - B2B (Phase-Aware)

    private static func b2bAdvice(phase: TrainingPhase, isDay2: Bool) -> String {
        if isDay2 {
            switch phase {
            case .peak:
                return "B2B Day 2: Start on yesterday's fatigue. First 30-60min very easy to warm up, then build to race effort. This simulates the second half of your ultra — embrace the discomfort."
            default:
                return "B2B Day 2: Today you run on yesterday's fatigue. This is ultra-specific training. Start very easy for the first hour, then gradually build effort. If you bonk, slow down and eat — just like race day."
            }
        }
        // Day 1
        switch phase {
        case .peak:
            return "B2B Day 1: Long run at steady effort. Fuel well because tomorrow you run on today's tired legs. Include terrain that matches your race."
        default:
            return "B2B Day 1: Build fatigue for tomorrow's session. Keep effort easy to moderate. Fuel consistently — your body needs to start tomorrow with glycogen."
        }
    }

    // MARK: - Intervals (Phase-Aware)

    private static func intervalAdvice(phase: TrainingPhase, weekInPhase: Int = 0) -> String {
        switch phase {
        case .base:
            return "Hill threshold repeats — 3×10min at tempo effort on moderate gradient. Full recovery between reps. Focus on smooth form and consistent splits."
        case .build:
            if weekInPhase < 6 {
                return "VO2max hill repeats — short, intense efforts on steep gradients. Push hard but stay controlled. If form breaks down, stop the set. Better to do 4 perfect than 6 sloppy."
            }
            return "Sustained threshold — 2×30min or 1×45min at race effort on rolling terrain. This is the bread and butter of ultra preparation. Stay controlled and fuel on schedule."
        case .peak:
            return "Short, sharp race-sharpening intervals. Maximum quality over maximum quantity. These are fine-tuning sessions — you're already fit."
        case .taper:
            return "Opener intervals. Just enough to keep your legs sharp. Controlled effort, don't chase times. Save the fire for race day."
        default:
            return "Full recovery between reps matters more than speed. If form breaks down, stop the set."
        }
    }

    // MARK: - Tempo (Phase-Aware)

    private static func tempoAdvice(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return "Find a rhythm you can hold for the entire session. You should be able to speak in short phrases. This builds your lactate threshold."
        case .build:
            return "Sustained threshold effort. Push the tempo but stay in control. This is the bread and butter of race-pace development."
        case .peak:
            return "Race-pace tempo. Lock into your goal race effort. Practice maintaining form when fatigue builds."
        default:
            return "Find a rhythm you can hold for the whole session. If you can't finish a sentence, slow down slightly."
        }
    }

    // MARK: - Vertical Gain (Phase + Environment Aware)

    private static func verticalGainAdvice(
        phase: TrainingPhase,
        intensity: Intensity,
        environment: VerticalGainEnvironment
    ) -> String {
        let phaseAdvice: String
        switch phase {
        case .base:
            phaseAdvice = "Build climbing confidence. Focus on efficient power hiking technique: hands on thighs, short steps, rhythmic breathing."
        case .build:
            phaseAdvice = "Sustained climbing endurance. Push the effort on ascents. This is where ultra-trail races are won and lost."
        case .peak:
            phaseAdvice = "Race-specific climbing. Mimic your race elevation profile — steep sections, variable grade, technical terrain if possible."
        case .taper:
            phaseAdvice = "Light climbing to maintain feel. Short efforts, controlled intensity. Keep your mountain legs without the fatigue."
        default:
            phaseAdvice = "Climbing session. Focus on consistent effort on the uphills."
        }

        let envTip: String
        switch environment {
        case .mountain:
            envTip = " Find sustained trails with real elevation."
        case .hill:
            envTip = " Find a hill with 3-5min of sustained climbing."
        case .treadmill:
            envTip = treadmillTip(intensity: intensity)
        case .mixed:
            envTip = " Alternate outdoor and treadmill climbing."
        }

        return phaseAdvice + envTip
    }

    private static func treadmillTip(intensity: Intensity) -> String {
        switch intensity {
        case .easy, .moderate:
            return " Set incline to 8-10%. Walk at brisk pace. Flat recovery between reps."
        case .hard:
            return " Set incline to 10-15%. Brisk pace. Flat recovery between reps."
        case .maxEffort:
            return " Set incline to 15%+. Maximum effort climbs. Full flat recovery."
        }
    }
}
