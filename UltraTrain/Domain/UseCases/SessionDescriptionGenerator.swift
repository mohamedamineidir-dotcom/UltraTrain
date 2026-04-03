import Foundation

enum SessionDescriptionGenerator {

    // MARK: - Long Run

    static func longRun(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Recovery week long run. Easy effort, no pace targets. Just enjoy the trail."
        }
        switch phase {
        case .base:
            return "Long run at easy effort. Focus on building time on feet. Walk uphills freely."
        case .build:
            return "Long run with blocks at race effort. Practice your nutrition strategy."
        case .peak:
            return "Race simulation long run. Start easy, build to race effort. Full nutrition and gear rehearsal."
        case .taper:
            return "Reduced long run at easy effort. Trust your fitness."
        case .recovery, .race:
            return "Easy long run. Conversational pace. Focus on recovery and movement quality."
        }
    }

    // MARK: - B2B

    static func b2bDay1(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return "Back-to-back Day 1: Long run building fatigue for tomorrow. Easy pace. Practice fueling."
        case .peak:
            return "Back-to-back Day 1: Long effort building toward race intensity. Include terrain-specific sections."
        default:
            return "Back-to-back Day 1: Long run at easy pace. Fuel well for tomorrow."
        }
    }

    static func b2bDay2(phase: TrainingPhase) -> String {
        switch phase {
        case .build:
            return "Back-to-back Day 2: Run on tired legs. First hour very easy, then build to race effort."
        case .peak:
            return "Back-to-back Day 2: Start on yesterday's fatigue. Build from easy to race effort. Full race simulation."
        default:
            return "Back-to-back Day 2: Long run on tired legs. Stay patient, keep it easy."
        }
    }

    // MARK: - Uphill Intervals

    static func verticalGain(phase: TrainingPhase, isRecoveryWeek: Bool) -> String {
        if isRecoveryWeek {
            return "Light uphill intervals. Easy climbing effort. No pushing."
        }
        switch phase {
        case .base:
            return "Uphill intervals at moderate effort. Focus on form, cadence, and power hiking technique."
        case .build:
            return "Uphill intervals at threshold effort. Build race-specific climbing endurance."
        case .peak:
            return "Race-specific climbing. Short steep repeats mimicking your race profile."
        case .taper:
            return "Light uphill intervals. Short climbs to stay sharp."
        case .recovery, .race:
            return "Easy uphill intervals at comfortable effort."
        }
    }

    // MARK: - Intervals

    static func intervals(phase: TrainingPhase, isRecoveryWeek: Bool, weekInPhase: Int = 0) -> String {
        if isRecoveryWeek {
            return "Recovery week: no hard intervals. Easy effort only."
        }
        switch phase {
        case .base:
            return "Uphill threshold intervals. Short reps with equal recovery."
        case .build:
            if weekInPhase < 6 {
                return "Hill repeats at high intensity. Short hard climbs with full recovery."
            }
            return "Sustained threshold work at race effort on rolling terrain. Practice fueling."
        case .peak:
            return "Threshold intervals at race effort. Medium reps building endurance."
        case .taper:
            return "Short opener intervals to stay sharp without fatiguing."
        case .recovery, .race:
            return "Easy effort. No hard intervals this week."
        }
    }

    // MARK: - Tempo

    static func tempo(phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            return "Tempo run at threshold effort. Build sustained race pace ability."
        case .build:
            return "Tempo blocks at race effort. Practice pacing and fueling."
        case .peak:
            return "Race-pace tempo on varied terrain."
        case .taper:
            return "Short tempo to stay sharp. Controlled effort."
        default:
            return "Easy tempo at comfortable effort."
        }
    }

    // MARK: - Cross-Training

    static func crossTraining() -> String {
        "Cross-training: cycling, swimming, hiking, or yoga. Active recovery without impact."
    }

    // MARK: - Easy Run

    static func easyRun(isRecoveryWeek: Bool, isPreLongRun: Bool = false, isPreRace: Bool = false) -> String {
        if isRecoveryWeek {
            return "Recovery week easy jog. Conversational pace. Blood flow, not fitness."
        }
        if isPreRace {
            return "Pre-race shakeout. Short easy jog. Stay loose and relaxed."
        }
        if isPreLongRun {
            return "Easy run to loosen up before the long run. Keep it conversational."
        }
        return "Easy run at conversational pace. Active recovery between quality sessions."
    }

    // MARK: - Taper Sub-Phase

    static func taperLongRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Taper long run. Reduced volume, easy effort. Practice your nutrition one last time."
        case .trueTaper:
            return "Short taper long run. Easy effort. Your fitness is locked in."
        }
    }

    static func taperIntervals(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Taper intervals. Short reps at race effort to maintain sharpness."
        case .trueTaper:
            return "Opener strides. Short pickups to stay sharp."
        }
    }

    static func taperVerticalGain(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Light uphill intervals. Short climbs at moderate effort."
        case .trueTaper:
            return "No hard climbing this week. Easy terrain only."
        }
    }

    static func taperEasyRun(subPhase: TaperProfile.SubPhase) -> String {
        switch subPhase {
        case .volumeTransition:
            return "Easy taper run. Volume is dropping by design."
        case .trueTaper:
            return "Short easy run. Keep legs loose for race day."
        }
    }

    static func taperStrides() -> String {
        "Opener strides: short pickups at fast but controlled effort. Full recovery between reps."
    }

    // MARK: - Rest

    static func rest(isRecoveryWeek: Bool, isPreRace: Bool = false) -> String {
        if isPreRace {
            return "Rest day. Final gear check, carb-load, and visualize your race plan."
        }
        if isRecoveryWeek {
            return "Recovery week rest. Sleep well, eat well. Your body is adapting."
        }
        return "Rest day. Recovery is part of training. Prioritize sleep."
    }
}
